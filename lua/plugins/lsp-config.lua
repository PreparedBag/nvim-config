return {
    {
        "williamboman/mason.nvim",
        event = "BufReadPre",
        config = function()
            require("mason").setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "neovim/nvim-lspconfig" },
        config = function()
            local servers = { "clangd", "pyright", "lua_ls", "ts_ls", "html", "cssls" }
            require("mason-lspconfig").setup({
                ensure_installed = servers
            })

            local lspconfig = require("lspconfig")

            -- HTML LSP specific settings
            lspconfig.html.setup({
                settings = {
                    css = { validate = false },
                    less = { validate = false },
                    scss = { validate = false },
                }
            })

            -- Helper function to enable autocomplete
            local function enable_autocomplete()
                local cmp = require('cmp')
                cmp.setup({ completion = { autocomplete = { "TextChanged" } } })
            end

            -- Helper function to disable autocomplete
            local function disable_autocomplete()
                local cmp = require('cmp')
                cmp.setup({ completion = { autocomplete = {} } })
            end

            -- <leader>lg - Generate compile_commands.json
            vim.keymap.set('n', '<leader>lg', function()
                -- Find project root (git root or current directory)
                local function find_project_root()
                    local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
                    if vim.v.shell_error == 0 and git_root ~= "" then
                        return git_root
                    end
                    return vim.fn.getcwd()
                end

                -- Find all .c files recursively
                local function find_c_files(root)
                    local c_files = {}
                    local find_cmd = string.format("find '%s' -type f -name '*.c' 2>/dev/null", root)
                    local handle = io.popen(find_cmd)
                    if handle then
                        for file in handle:lines() do
                            table.insert(c_files, file)
                        end
                        handle:close()
                    end
                    return c_files
                end

                -- Generate compile_commands.json
                local function generate_compile_commands(root, c_files)
                    local compile_commands = {}

                    -- Standard compiler flags with system includes
                    local flags = {
                        "-std=c11",
                        "-Wall",
                        "-Wextra",
                        "-I.",
                        "-I" .. root,
                        "-I/usr/include",
                        "-I/usr/local/include",
                    }

                    for _, file in ipairs(c_files) do
                        local entry = {
                            directory = root,
                            command = "gcc " .. table.concat(flags, " ") .. " -c " .. file,
                            file = file
                        }
                        table.insert(compile_commands, entry)
                    end

                    return compile_commands
                end

                -- Write compile_commands.json
                local function write_compile_commands(root, commands)
                    local json = vim.fn.json_encode(commands)
                    local output_file = root .. "/compile_commands.json"
                    local file = io.open(output_file, "w")
                    if file then
                        file:write(json)
                        file:close()
                        return output_file
                    end
                    return nil
                end

                vim.notify("Generating compile_commands.json...", vim.log.levels.INFO)

                local root = find_project_root()
                local c_files = find_c_files(root)

                if #c_files == 0 then
                    vim.notify("No .c files found in " .. root, vim.log.levels.WARN)
                    return
                end

                local commands = generate_compile_commands(root, c_files)
                local output = write_compile_commands(root, commands)

                if output then
                    vim.notify(string.format("Generated %s with %d entries", output, #c_files), vim.log.levels.INFO)

                    -- Restart LSP to pick up the new compile_commands.json
                    vim.cmd("LspRestart")
                else
                    vim.notify("Failed to write compile_commands.json", vim.log.levels.ERROR)
                end
            end, opts)

            -- Track signature help window state
            local signature_active = true

            -- LSP on_attach callback - sets up buffer-local keymaps
            local on_attach = function(_, bufnr)
                local opts = { noremap = true, silent = true, buffer = bufnr }

                -- Go to definition
                vim.keymap.set("n", "gd", function()
                    local params = vim.lsp.util.make_position_params()
                    vim.lsp.buf_request(0, "textDocument/definition", params, function(_, result)
                        if result == nil or vim.tbl_isempty(result) then return end
                        if vim.tbl_islist(result) then
                            vim.lsp.util.jump_to_location(result[1], "utf-8")
                        else
                            vim.lsp.buf.definition(result, "utf-8")
                        end
                    end)
                end, opts)

                -- Code action
                vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, opts)

                -- Diagnostic float
                vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, opts)

                -- Signature help (normal mode)
                vim.keymap.set('n', '<C-h>', vim.lsp.buf.signature_help, opts)

                -- Signature help (insert mode - only if not already active)
                vim.keymap.set('i', '<C-h>', function()
                    if not signature_active then
                        vim.lsp.buf.signature_help()
                        signature_active = true
                    end
                end, opts)

                -- LSP references via Telescope
                vim.keymap.set('n', '<leader>lr', function()
                    require('telescope.builtin').lsp_references {
                        fname_width = 0,
                        trim_text = true,
                        show_line = true,
                        initial_mode = "normal",
                    }
                end, opts)
            end

            -- Global keymaps (not buffer-specific)
            local opts = { noremap = true, silent = true }

            -- <leader>lc - Cancel/disable autocomplete entirely
            vim.keymap.set('n', '<leader>lc', function()
                disable_autocomplete()
                vim.api.nvim_input('<Esc>')
                vim.notify("Autocomplete disabled")
            end, opts)

            -- <leader>ls - Start LSP and enable autocomplete
            vim.keymap.set('n', '<leader>ls', function()
                local ok = pcall(vim.cmd, "edit")
                if not ok then
                    vim.notify("Please save pending changes or discard...", vim.log.levels.WARN)
                    return
                end

                local bufnr = vim.api.nvim_get_current_buf()
                local clients = vim.lsp.get_clients({ bufnr = bufnr })

                for _, client in ipairs(clients) do
                    on_attach(client, bufnr)
                end

                enable_autocomplete()
                vim.notify("LSP started with autocomplete enabled")
            end, opts)

            -- Track signature help window state
            vim.api.nvim_create_autocmd({ "InsertCharPre", "CursorMoved" }, {
                callback = function()
                    local active = false
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local config = vim.api.nvim_win_get_config(win)
                        if config.relative == "cursor" and config.anchor == "NW" then
                            active = true
                            break
                        end
                    end
                    signature_active = active
                end,
            })

            -- Re-enable autocomplete when switching buffers (for split navigation)
            vim.api.nvim_create_autocmd("BufEnter", {
                callback = function()
                    local bufnr = vim.api.nvim_get_current_buf()
                    local clients = vim.lsp.get_clients({ bufnr = bufnr })

                    -- Only re-enable if LSP is attached to this buffer
                    if #clients > 0 then
                        enable_autocomplete()
                    end
                end,
            })

            -- Setup all LSP servers
            for _, server in ipairs(servers) do
                local capabilities = require("cmp_nvim_lsp").default_capabilities()
                lspconfig[server].setup({
                    on_attach = on_attach,
                    capabilities = capabilities,
                })
            end
        end
    },
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            vim.o.completeopt = "menu,menuone,noselect"

            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-j>"] = cmp.mapping.select_next_item(),
                    ["<C-k>"] = cmp.mapping.select_prev_item(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = function()
                        if cmp.visible() then
                            cmp.abort()
                        else
                            cmp.complete()
                        end
                    end,
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp", keyword_length = 1 },
                }),
                completion = {
                    autocomplete = { "TextChanged" }
                }
            })
        end
    }
}
