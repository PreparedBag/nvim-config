return {
    {
        'nvim-treesitter/nvim-treesitter',
        event = { "BufReadPost", "BufNewFile" }, -- Load when opening files
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
