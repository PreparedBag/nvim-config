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
            local servers = { "clangd" }
            require("mason-lspconfig").setup({
                ensure_installed = servers
            })
            local lspconfig = require("lspconfig")

            -- Global on_attach function for all LSPs
            local on_attach = function(_, bufnr)
                local opts = { noremap = true, silent = true, buffer = bufnr }
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
            end

            -- Apply on_attach to all LSPs and set vim as global
            for _, server in ipairs(servers) do
                lspconfig[server].setup({ on_attach = on_attach, })
            end
        end
    },
}
