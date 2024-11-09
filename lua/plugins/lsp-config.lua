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
        config = function()
            local servers = { "lua_ls", "pyright" }
            require("mason-lspconfig").setup({
                ensure_installed = servers
            })
            local lspconfig = require("lspconfig")

            -- Global on_attach function for all LSPs
            local on_attach = function(_, bufnr)
                local opts = { noremap = true, silent = true, buffer = bufnr }
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', 'ca', vim.lsp.buf.code_action, opts)
            end

            -- Apply on_attach to all LSPs and set vim as global for lua_ls
            for _, server in ipairs(servers) do
                lspconfig[server].setup({
                    on_attach = on_attach,
                    settings = server == "lua_ls" and {
                        Lua = {
                            diagnostics = {
                                globals = { "vim" },
                            },
                        },
                    } or nil,
                })
            end
        end
    },
    { "neovim/nvim-lspconfig" },
    {
        "nvimtools/none-ls.nvim",
        event = "BufReadPre",
        config = function()
            local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
            local none_ls = require("null-ls")

            -- Setup sources for various languages
            none_ls.setup({
                sources = {
                    none_ls.builtins.formatting.stylua,
                    none_ls.builtins.formatting.black,
                    none_ls.builtins.formatting.prettier.with({
                        filetypes = { "markdown" }
                    }),
                    none_ls.builtins.formatting.clang_format,
                },

                on_attach = function(client, bufnr)
                    if client.supports_method("textDocument/formatting") then
                        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = augroup,
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.buf.format({ async = false })
                            end,
                        })
                    end
                end,
            })
        end
    }
}
