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

            -- Track signature help window state
            local signature_active = true

            -- Helper function to check if buffer should have LSP attached
            local function is_valid_lsp_buffer(bufnr)
                local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
                local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

                -- Skip special buffer types
                if buftype ~= '' then
                    return false
                end

                -- Skip certain filetypes that shouldn't have LSP
                local excluded_filetypes = {
                    'oil',
                    'help',
                    'qf',
                    'netrw',
                    'man',
                    'lazy',
                    'mason',
                }

                for _, ft in ipairs(excluded_filetypes) do
                    if filetype == ft then
                        return false
                    end
                end

                return true
            end

            -- LSP on_attach callback - sets up buffer-local keymaps
            local on_attach = function(client, bufnr)
                -- Only attach to valid file buffers
                if not is_valid_lsp_buffer(bufnr) then
                    vim.lsp.buf_detach_client(bufnr, client.id)
                    return
                end

                local opts = { noremap = true, silent = true, buffer = bufnr }

                -- Go to definition
                vim.keymap.set("n", "gd", function()
                    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
                    vim.lsp.buf_request(0, "textDocument/definition", params, function(_, result)
                        if result == nil or vim.tbl_isempty(result) then return end
                        if vim.tbl_islist(result) then
                            vim.lsp.util.jump_to_location(result[1], client.offset_encoding)
                        else
                            vim.lsp.buf.definition(result, client.offset_encoding)
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

            -- Setup all LSP servers using the new vim.lsp.config API (Neovim 0.11+)
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local servers = { "clangd", "pyright", "lua_ls", "ts_ls", "html", "cssls" }

            -- HTML LSP with specific settings
            vim.lsp.config.html = {
                cmd = { 'vscode-html-language-server', '--stdio' },
                filetypes = { 'html' },
                root_markers = { '.git' },
                settings = {
                    css = { validate = false },
                    less = { validate = false },
                    scss = { validate = false },
                },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            -- Setup remaining LSP servers
            vim.lsp.config.clangd = {
                cmd = { 'clangd' },
                filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
                root_markers = { '.git' },
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
            }

            vim.lsp.config.ts_ls = {
                cmd = { 'typescript-language-server', '--stdio' },
                filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
                root_markers = { '.git', 'package.json' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.cssls = {
                cmd = { 'vscode-css-language-server', '--stdio' },
                filetypes = { 'css', 'scss', 'less' },
                root_markers = { '.git' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            -- Use mason-lspconfig handlers to enable LSP without triggering deprecated API
            require("mason-lspconfig").setup({
                ensure_installed = servers,
                handlers = {
                    -- Default handler that enables LSP servers
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
                }
            })
        end
    }
}
