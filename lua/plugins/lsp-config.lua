return {
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        enabled = _G.DEV_ENABLED,
        build = ":MasonUpdate",
        config = function()
            require("mason").setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        enabled = _G.DEV_ENABLED,
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

            -- Track signature-help window state (used by the insert-mode <C-h> map)
            local signature_active = true

            -- ============================================================================
            -- LSP ON_ATTACH - BUFFER-LOCAL KEYMAPS
            -- ============================================================================

            local on_attach = function(client, bufnr)
                if not is_valid_lsp_buffer(bufnr) then
                    vim.lsp.buf_detach_client(bufnr, client.id)
                    return
                end

                local opts = { noremap = true, silent = true, buffer = bufnr }

                -- Small helper so per-map descriptions stay tidy
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs,
                        vim.tbl_extend('force', opts, { desc = desc }))
                end

                -- Navigation
                map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
                map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
                map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
                map("n", "gt", vim.lsp.buf.type_definition, "Go to Type Definition")

                map("n", "<leader>lq", function() vim.diagnostic.setqflist({ open = false }) end,
                    "Diagnostics to quickfix");
                map("n", "<leader>lD",
                    function() require("telescope.builtin").diagnostics({ initial_mode = "normal" }) end,
                    "Project diagnostics (Telescope)")

                -- Information
                map("n", "K", vim.lsp.buf.hover, "Hover")
                map("n", "<C-h>", vim.lsp.buf.signature_help, "Signature Help")
                map("i", "<C-h>", function()
                    if not signature_active then
                        vim.lsp.buf.signature_help()
                        signature_active = true
                    end
                end, "Signature Help")

                -- Code actions and refactoring
                map("n", "<leader>la", vim.lsp.buf.code_action, "Code Actions")
                map("n", "<leader>ln", vim.lsp.buf.rename, "Refactor Symbol")
                map("n", "<leader>lf", function()
                    vim.lsp.buf.format({ async = true })
                end, "Format")

                -- Diagnostics
                map("n", "<leader>ld", vim.diagnostic.open_float, "Line Diagnostics")
                map("n", "<leader>lk", function() vim.diagnostic.jump({ count = -1 }) end, "Prev Diagnostic")
                map("n", "<leader>lj", function() vim.diagnostic.jump({ count = 1 }) end, "Next Diagnostic")
                map("n", "<leader>le", function()
                    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
                end, "Next Error")

                -- References via LSP; falls back to ripgrep only if the LSP returns nothing.
                map("n", "<leader>lr", function()
                    local word = vim.fn.expand("<cword>")
                    -- local bufnr = vim.api.nvim_get_current_buf()

                    local function ripgrep()
                        require("telescope.builtin").grep_string({
                            search = word,
                            initial_mode = "normal",
                            prompt_title = "Ripgrep: " .. word,
                        })
                    end

                    -- Clients on this buffer that actually support references
                    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/references" })
                    if #clients == 0 then
                        vim.notify("No LSP references support, using ripgrep", vim.log.levels.INFO)
                        ripgrep()
                        return
                    end

                    -- Pass encoding explicitly -> no more position_encoding warning
                    local params = vim.lsp.util.make_position_params(0, clients[1].offset_encoding) --[[@as lsp.ReferenceParams]]
                    params.context = { includeDeclaration = true }

                    vim.lsp.buf_request_all(bufnr, "textDocument/references", params, function(results)
                        local items = {}
                        for _, res in pairs(results) do
                            if res and res.result then
                                vim.list_extend(items, res.result)
                            end
                        end

                        if #items == 0 then
                            vim.notify("No LSP references found, falling back to ripgrep", vim.log.levels.INFO)
                            vim.schedule(ripgrep)
                        else
                            vim.schedule(function()
                                local pickers = require("telescope.pickers")
                                local finders = require("telescope.finders")
                                local conf = require("telescope.config").values
                                local make_entry = require("telescope.make_entry")

                                local locations = vim.lsp.util.locations_to_items(
                                    items, clients[1].offset_encoding
                                )

                                pickers.new({}, {
                                    prompt_title = "References: " .. word,
                                    initial_mode = "normal",
                                    finder = finders.new_table({
                                        results = locations,
                                        entry_maker = make_entry.gen_from_quickfix({}),
                                    }),
                                    previewer = conf.qflist_previewer({}),
                                    sorter = conf.generic_sorter({}),
                                }):find()
                            end)
                        end
                    end)
                end, "Show References")

                -- Workspace symbols
                map("n", "<leader>lw", function()
                    require('telescope.builtin').lsp_dynamic_workspace_symbols()
                end, "Workspace Symbols")

                -- Document symbols
                map("n", "<leader>lo", function()
                    require('telescope.builtin').lsp_document_symbols()
                end, "Document Symbols")

                -- Enable formatting on save if supported
                -- if client.server_capabilities.documentFormattingProvider then
                --     local group = vim.api.nvim_create_augroup("LspFormat_" .. bufnr, { clear = true })
                --     vim.api.nvim_create_autocmd("BufWritePre", {
                --         group = group,
                --         buffer = bufnr,
                --         callback = function()
                --             vim.lsp.buf.format({ bufnr = bufnr })
                --         end,
                --     })
                -- end
            end

            -- Keep signature_active in sync with whether a signature float is open
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

            -- Toggle blink.cmp autocomplete for the current buffer
            vim.keymap.set('n', '<leader>lA', function()
                local ok, _ = pcall(require, 'blink.cmp')
                if not ok then
                    vim.notify("blink.cmp not installed", vim.log.levels.WARN)
                    return
                end

                local bufnr = vim.api.nvim_get_current_buf()
                local current_state = vim.b[bufnr].blink_cmp_enabled

                if current_state == false then
                    vim.b[bufnr].blink_cmp_enabled = nil
                    vim.notify("Autocomplete enabled")
                else
                    vim.b[bufnr].blink_cmp_enabled = false
                    vim.notify("Autocomplete disabled")
                    vim.api.nvim_input('<C-e>') -- force-close any open menu
                end

                vim.cmd('doautocmd TextChanged') -- re-evaluate enabled state
            end, { noremap = true, silent = true, desc = 'Toggle Blink Autocomplete' })

            -- Detach LSP from current buffer only
            vim.keymap.set('n', '<leader>lc', function()
                local bufnr = vim.api.nvim_get_current_buf()
                local clients = vim.lsp.get_clients({ bufnr = bufnr })

                if #clients == 0 then
                    vim.notify("No LSP clients attached", vim.log.levels.WARN)
                    return
                end

                for _, client in ipairs(clients) do
                    vim.lsp.buf_detach_client(bufnr, client.id)
                end

                vim.api.nvim_input('<Esc>')
                vim.notify("LSP detached from buffer")
            end, { noremap = true, silent = true, desc = 'Detach LSP from Buffer' })

            -- Attach a suitable LSP to the current buffer
            vim.keymap.set('n', '<leader>ls', function()
                local bufnr = vim.api.nvim_get_current_buf()
                local filetype = vim.bo[bufnr].filetype

                if filetype == "" then
                    vim.notify("No filetype set for buffer", vim.log.levels.WARN)
                    return
                end

                local all_clients = vim.lsp.get_clients()
                local attached = 0

                for _, client in ipairs(all_clients) do
                    local fts = client.config.filetypes --[[@as string[]?]]
                    if fts then
                        for _, ft in ipairs(fts) do
                            if ft == filetype then
                                vim.lsp.buf_attach_client(bufnr, client.id)
                                on_attach(client, bufnr)
                                attached = attached + 1
                                break
                            end
                        end
                    end
                end

                if attached > 0 then
                    vim.notify("LSP attached to buffer")
                else
                    vim.notify("No suitable LSP clients found for " .. filetype, vim.log.levels.WARN)
                end
            end, { noremap = true, silent = true, desc = 'Attach LSP to Buffer' })

            -- ============================================================================
            -- LSP SERVER SETUP
            -- ============================================================================

            local capabilities = vim.lsp.protocol.make_client_capabilities()

            -- Integrate blink.cmp capabilities if available
            pcall(function()
                capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)
            end)

            vim.lsp.config.jdtls = {
                cmd = { 'jdtls' },
                filetypes = { 'java' },
                root_markers = {
                    '.git', 'pom.xml', 'build.gradle',
                    'build.gradle.kts', 'settings.gradle',
                },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.clangd = {
                -- NOTE: dropped --clang-tidy to reduce CPU load. add back in if needed.
                cmd = { 'clangd', '--background-index', '-j=4', "--query-driver=/usr/bin/arm-none-eabi-*" },
                filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
                root_markers = { '.git', 'compile_commands.json' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.pyright = {
                cmd = { 'pyright-langserver', '--stdio' },
                filetypes = { 'python' },
                -- HACK: webui.py and setup.py used for project specific markers.
                root_markers = { '.git', 'pyproject.toml', 'setup.py', 'webui.py', 'main.py', 'index.py' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.lua_ls = {
                cmd = { vim.fn.stdpath('data') .. '/mason/bin/lua-language-server' },
                filetypes = { 'lua' },
                root_markers = { '.luarc.json', '.git' },
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    Lua = {
                        runtime = { version = 'LuaJIT' },
                        diagnostics = { globals = { 'vim' } },
                        workspace = {
                            library = {
                                vim.env.VIMRUNTIME .. '/lua',
                            },
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
                cmd = { "vscode-html-language-server", "--stdio" },
                filetypes = { "html" },
                root_markers = { ".git" },
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    css  = { validate = false },
                    less = { validate = false },
                    scss = { validate = false },
                    html = {
                        format = {
                            wrapLineLength = 0, -- disable wrapping/reflow
                            unformatted = "",
                            contentUnformatted = "",
                        },
                    },
                },
            }

            vim.lsp.config.cssls = {
                cmd = { 'vscode-css-language-server', '--stdio' },
                filetypes = { 'css', 'scss', 'less' },
                root_markers = { '.git' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.gopls = {
                cmd = { 'gopls' },
                filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
                root_markers = { 'go.mod', '.git', 'go.work' },
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    gopls = {
                        analyses = {
                            unusedparams = true,
                            shadow = true,
                        },
                        staticcheck = true,
                    },
                },
            }
            vim.lsp.config.rust_analyzer = {
                cmd = { 'rust-analyzer' },
                filetypes = { 'rust' },
                root_markers = { '.git', 'Cargo.toml', 'Cargo.lock' },
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    ['rust-analyzer'] = {
                        cargo = { allFeatures = true },
                        checkOnSave = { command = 'clippy' },
                    },
                },
            }

            require("mason-lspconfig").setup({
                -- NOTE: gopls, rust_analyzer installed manually via :MasonInstall when needed
                ensure_installed = { "jdtls", "clangd", "pyright", "lua_ls", "ts_ls", "html", "cssls" },
                handlers = {
                    function(server_name)
                        vim.lsp.enable(server_name)
                    end,
                }
            })
        end
    }
}
