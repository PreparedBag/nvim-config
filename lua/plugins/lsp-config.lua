return {
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        config = function()
            require("mason").setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "neovim/nvim-lspconfig" },
        config = function()
            -- ============================================================================
            -- HELPER FUNCTIONS
            -- ============================================================================

            local function enable_autocomplete()
                local cmp = require('cmp')
                cmp.setup({ completion = { autocomplete = { "TextChanged" } } })
            end

            local function disable_autocomplete()
                local cmp = require('cmp')
                cmp.setup({ completion = { autocomplete = {} } })
            end

            local function is_valid_lsp_buffer(bufnr)
                local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
                local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

                if buftype ~= '' then return false end

                local excluded_filetypes = {
                    'oil', 'help', 'qf', 'netrw', 'man', 'lazy', 'mason',
                }

                for _, ft in ipairs(excluded_filetypes) do
                    if filetype == ft then return false end
                end

                return true
            end

            -- ============================================================================
            -- COMPILE_COMMANDS.JSON GENERATION FUNCTIONS
            -- ============================================================================

            local function find_project_root()
                local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
                if vim.v.shell_error == 0 and git_root ~= "" then
                    return git_root
                end
                return vim.fn.getcwd()
            end

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

            local function write_compile_commands(root, commands)
                local output_file = root .. "/compile_commands.json"
                local file = io.open(output_file, "w")
                if not file then return nil end

                file:write("[\n")
                for i, entry in ipairs(commands) do
                    file:write("  {\n")
                    file:write(string.format('    "directory": "%s",\n', entry.directory:gsub('\\', '\\\\')))
                    file:write(string.format('    "command": "%s",\n', entry.command:gsub('\\', '\\\\')))
                    file:write(string.format('    "file": "%s"\n', entry.file:gsub('\\', '\\\\')))
                    file:write(i < #commands and "  },\n" or "  }\n")
                end
                file:write("]\n")
                file:close()
                return output_file
            end

            -- ============================================================================
            -- LSP ON_ATTACH - BUFFER-LOCAL KEYMAPS
            -- ============================================================================

            local signature_active = true

            local on_attach = function(client, bufnr)
                if not is_valid_lsp_buffer(bufnr) then
                    vim.lsp.buf_detach_client(bufnr, client.id)
                    return
                end

                local opts = { noremap = true, silent = true, buffer = bufnr }

                -- Navigation
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
                vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
                vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, opts)

                -- Information
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', '<C-h>', vim.lsp.buf.signature_help, opts)
                vim.keymap.set('i', '<C-h>', function()
                    if not signature_active then
                        vim.lsp.buf.signature_help()
                        signature_active = true
                    end
                end, opts)

                -- Code actions and refactoring
                vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, opts)
                vim.keymap.set('v', '<leader>la', vim.lsp.buf.code_action, opts)
                vim.keymap.set('n', '<leader>ln', vim.lsp.buf.rename, opts)
                vim.keymap.set('n', '<leader>lf', function()
                    vim.lsp.buf.format({ async = true })
                end, opts)

                -- Diagnostics
                vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, opts)
                vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
                vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
                vim.keymap.set('n', '<leader>lq', vim.diagnostic.setloclist, opts)

                -- References with Telescope fallback to ripgrep
                vim.keymap.set('n', '<leader>lr', function()
                    local clients = vim.lsp.get_clients({ bufnr = bufnr })
                    if #clients == 0 then
                        vim.notify("No LSP client attached", vim.log.levels.WARN)
                        return
                    end

                    local client = clients[1]
                    local word = vim.fn.expand("<cword>")
                    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

                    vim.lsp.buf_request(0, "textDocument/references", params, function(err, result)
                        if err then
                            vim.notify("LSP error: " .. vim.inspect(err), vim.log.levels.ERROR)
                            return
                        end

                        if not result or vim.tbl_isempty(result) then
                            vim.notify("No LSP references found, falling back to ripgrep", vim.log.levels.INFO)
                            vim.schedule(function()
                                require('telescope.builtin').grep_string({
                                    search = word,
                                    initial_mode = "normal",
                                    prompt_title = "Ripgrep: " .. word,
                                })
                            end)
                            return
                        end

                        vim.schedule(function()
                            require('telescope.builtin').lsp_references({
                                fname_width = 0,
                                trim_text = true,
                                show_line = true,
                                initial_mode = "normal",
                            })
                        end)
                    end)
                end, opts)

                -- Workspace symbols
                vim.keymap.set('n', '<leader>lw', function()
                    require('telescope.builtin').lsp_dynamic_workspace_symbols()
                end, opts)

                -- Document symbols
                vim.keymap.set('n', '<leader>lo', function()
                    require('telescope.builtin').lsp_document_symbols()
                end, opts)

                -- Alternative ripgrep search (bypass LSP)
                vim.keymap.set('n', '<leader>lR', function()
                    local word = vim.fn.expand("<cword>")
                    require('telescope.builtin').grep_string({
                        search = word,
                        initial_mode = "normal",
                        prompt_title = "Ripgrep: " .. word,
                    })
                end, opts)

                -- Search for macro definitions
                vim.keymap.set('n', '<leader>lm', function()
                    local word = vim.fn.expand("<cword>")
                    require('telescope.builtin').grep_string({
                        search = string.format([[#define\s+%s|config\s+%s]], word, word),
                        use_regex = true,
                        initial_mode = "normal",
                        prompt_title = "Macro Definition: " .. word,
                    })
                end, opts)

                -- Enable formatting on save if supported
                if client.server_capabilities.documentFormattingProvider then
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        callback = function()
                            vim.lsp.buf.format({ bufnr = bufnr })
                        end,
                    })
                end
            end

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

            -- Re-enable autocomplete when switching buffers
            vim.api.nvim_create_autocmd("BufEnter", {
                callback = function()
                    local bufnr = vim.api.nvim_get_current_buf()
                    local clients = vim.lsp.get_clients({ bufnr = bufnr })
                    if #clients > 0 then
                        enable_autocomplete()
                    end
                end,
            })

            -- ============================================================================
            -- GLOBAL LSP KEYMAPS
            -- ============================================================================

            local opts = { noremap = true, silent = true }

            -- Stop LSP and disable autocomplete
            vim.keymap.set('n', '<leader>lc', function()
                local bufnr = vim.api.nvim_get_current_buf()
                local clients = vim.lsp.get_clients({ bufnr = bufnr })
                for _, client in ipairs(clients) do
                    vim.lsp.stop_client(client.id)
                end
                disable_autocomplete()
                vim.api.nvim_input('<Esc>')
                vim.notify("LSP stopped and autocomplete disabled")
            end, opts)

            -- Start LSP and enable autocomplete
            vim.keymap.set('n', '<leader>ls', function()
                local ok = pcall(vim.cmd, "edit")
                if not ok then
                    vim.notify("Please save pending changes or discard", vim.log.levels.WARN)
                    return
                end
                local bufnr = vim.api.nvim_get_current_buf()
                local clients = vim.lsp.get_clients({ bufnr = bufnr })
                for _, client in ipairs(clients) do
                    on_attach(client, bufnr)
                end
                enable_autocomplete()
                vim.notify("LSP started and autocomplete enabled")
            end, opts)

            -- Generate compile_commands.json variants
            vim.keymap.set('n', '<leader>lgc', function()
                vim.fn.system("cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build")
                vim.fn.system("ln -sf build/compile_commands.json .")
                vim.cmd("LspRestart")
                vim.notify("CMake compile_commands.json generated")
            end, opts)

            vim.keymap.set('n', '<leader>lgw', function()
                vim.fn.system("west build -t compile_commands")
                vim.cmd("LspRestart")
                vim.notify("West compile_commands.json generated")
            end, opts)

            vim.keymap.set('n', '<leader>lgg', function()
                vim.notify("Generating generic compile_commands.json...")
                local root = find_project_root()
                local c_files = find_c_files(root)

                if #c_files == 0 then
                    vim.notify("No .c files found in " .. root, vim.log.levels.WARN)
                    return
                end

                local compile_commands = {}
                local flags = {
                    "-std=c11", "-Wall", "-Wextra", "-I.", "-I" .. root,
                    "-I/usr/include", "-I/usr/local/include",
                }

                for _, file in ipairs(c_files) do
                    table.insert(compile_commands, {
                        directory = root,
                        command = "gcc " .. table.concat(flags, " ") .. " -c " .. file,
                        file = file
                    })
                end

                local output = write_compile_commands(root, compile_commands)
                if output then
                    vim.notify(string.format("Generated %s with %d entries", output, #c_files))
                    vim.cmd("LspRestart")
                else
                    vim.notify("Failed to write compile_commands.json", vim.log.levels.ERROR)
                end
            end, opts)

            vim.keymap.set('n', '<leader>lgz', function()
                vim.notify("Generating Zephyr compile_commands.json...")
                local root = find_project_root()
                local c_files = find_c_files(root)

                if #c_files == 0 then
                    vim.notify("No .c files found in " .. root, vim.log.levels.WARN)
                    return
                end

                local zephyr_base = os.getenv("ZEPHYR_BASE") or (root .. "/zephyr")
                local build_dir = root .. "/build"
                local autoconf_h = build_dir .. "/zephyr/include/generated/autoconf.h"

                local compile_commands = {}
                local flags = {
                    "-std=c11", "-Wall", "-Wextra", "-I.", "-I" .. root,
                    "-I" .. root .. "/include",
                    "-I" .. zephyr_base .. "/include",
                    "-I" .. zephyr_base .. "/include/zephyr",
                    "-I" .. zephyr_base .. "/drivers",
                    "-I" .. zephyr_base .. "/soc",
                    "-I" .. build_dir .. "/zephyr/include/generated",
                    "-I/usr/include", "-I/usr/local/include",
                }

                if vim.fn.filereadable(autoconf_h) == 1 then
                    table.insert(flags, "-include")
                    table.insert(flags, autoconf_h)
                else
                    vim.notify("Warning: autoconf.h not found", vim.log.levels.WARN)
                end

                for _, file in ipairs(c_files) do
                    table.insert(compile_commands, {
                        directory = root,
                        command = "gcc " .. table.concat(flags, " ") .. " -c " .. file,
                        file = file
                    })
                end

                local output = write_compile_commands(root, compile_commands)
                if output then
                    vim.notify(string.format("Generated Zephyr %s with %d entries", output, #c_files))
                    vim.cmd("LspRestart")
                else
                    vim.notify("Failed to write compile_commands.json", vim.log.levels.ERROR)
                end
            end, opts)

            -- ============================================================================
            -- LSP SERVER SETUP
            -- ============================================================================

            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- Configure LSP servers
            vim.lsp.config.clangd = {
                cmd = { 'clangd', '--background-index', '--clang-tidy' },
                filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
                root_markers = { '.git', 'compile_commands.json' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.pyright = {
                cmd = { 'pyright-langserver', '--stdio' },
                filetypes = { 'python' },
                root_markers = { '.git', 'pyproject.toml', 'setup.py' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.lua_ls = {
                cmd = { 'lua-language-server' },
                filetypes = { 'lua' },
                root_markers = { '.git', '.luarc.json' },
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { 'vim' }
                        },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
            }

            vim.lsp.config.ts_ls = {
                cmd = { 'typescript-language-server', '--stdio' },
                filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
                root_markers = { '.git', 'package.json' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.html = {
                cmd = { 'vscode-html-language-server', '--stdio' },
                filetypes = { 'html' },
                root_markers = { '.git' },
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    css = { validate = false },
                    less = { validate = false },
                    scss = { validate = false },
                },
            }

            vim.lsp.config.cssls = {
                cmd = { 'vscode-css-language-server', '--stdio' },
                filetypes = { 'css', 'scss', 'less' },
                root_markers = { '.git' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            -- Setup mason-lspconfig
            require("mason-lspconfig").setup({
                ensure_installed = { "clangd", "pyright", "lua_ls", "ts_ls", "html", "cssls" },
                handlers = {
                    function(server_name)
                        vim.lsp.enable(server_name)
                    end,
                }
            })
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
                },
                performance = {
                    max_view_entries = 50,
                },
            })
        end
    }
}
