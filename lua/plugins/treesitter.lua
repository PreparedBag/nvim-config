return {
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "c", "lua", "vim", "vimdoc", "html", "css", "javascript", "mermaid", "yaml", "markdown" },
                auto_install = true,
                sync_install = false,
                highlight = { enable = true },
                indent = { enable = true },
            })
        end
    }
}
