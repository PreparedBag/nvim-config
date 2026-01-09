return {
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        event = { "VeryLazy" },
        -- event = { "BufReadPost", "BufNewFile" },
        build = ":TSUpdate",
        config = function()
            local ok, ts = pcall(require, "nvim-treesitter.configs")
            if not ok then
                ok, ts = pcall(require, "nvim-treesitter.config")
            end

            if ok then
                ts.setup({
                    ensure_installed = { "c", "lua", "vim", "vimdoc", "html", "css", "javascript", "mermaid", "yaml", "markdown" },
                    auto_install = true,
                    sync_install = false,
                    highlight = { enable = true },
                    indent = { enable = true },
                })
            end
        end
    }
}
