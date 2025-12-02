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
                ---@diagnostic disable-next-line: deprecated
                vim.keymap.set('n', '<leader>k', vim.diagnostic.goto_prev, opts)
                ---@diagnostic disable-next-line: deprecated
                vim.keymap.set('n', '<leader>j', vim.diagnostic.goto_next, opts)

                -- LSP references with Telescope
                vim.keymap.set('n', '<leader>lr', function()
                    -- First try LSP references
                    vim.lsp.buf.references(nil, {
                        on_list = function(options)
                            if #options.items == 0 then
                                -- No LSP results, fallback to ripgrep
                                local word = vim.fn.expand("<cword>")
                                vim.notify("No LSP references found, falling back to ripgrep", vim.log.levels.INFO)
                                vim.schedule(function()
                                    require('telescope.builtin').grep_string({
                                        search = word,
                                        initial_mode = "normal",
                                        prompt_title = "Ripgrep: " .. word,
                                    })
                                end)
                            else
                                -- Show LSP results in Telescope
                                vim.schedule(function()
                                    require('telescope.builtin').lsp_references({
                                        fname_width = 0,
                                        trim_text = true,
                                        show_line = true,
                                        initial_mode = "normal",
                                    })
                                end)
                            end
                        end,
                    })
                end, { buffer = bufnr, desc = "Show References" })

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

            -- ============================================================================
            -- GLOBAL LSP KEYMAPS
            -- ============================================================================

            local opts = { noremap = true, silent = true }

            -- Stop LSP
            vim.keymap.set('n', '<leader>lc', function()
                local bufnr = vim.api.nvim_get_current_buf()
                local clients = vim.lsp.get_clients({ bufnr = bufnr })
                for _, client in ipairs(clients) do
                    vim.lsp.stop_client(client.id)
                end
                vim.api.nvim_input('<Esc>')
                vim.notify("LSP stopped")
            end, opts)

            -- Start LSP
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
                vim.notify("LSP started")
            end, opts)

            -- ============================================================================
            -- LSP SERVER SETUP
            -- ============================================================================

            local capabilities = vim.lsp.protocol.make_client_capabilities()

            -- Integrate blink.cmp capabilities if available
            pcall(function()
                capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)
            end)

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
    }
}
