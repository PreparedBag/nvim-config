return {
    'akinsho/toggleterm.nvim',
    keys = {
        { "<leader>,", ":ToggleTerm<CR>", desc = "Toggle Terminal" },
    },
    config = function()
        require('toggleterm').setup({
            direction = 'float',
            float_opts = {
                border = 'curved',
                width = function()
                    return math.floor(vim.o.columns * 0.8)
                end,
                height = function()
                    return math.floor(vim.o.lines * 0.8)
                end,
                row = function()
                    return math.floor((vim.o.lines - math.floor(vim.o.lines * 0.8)) / 2)
                end,
                col = function()
                    return math.floor((vim.o.columns - math.floor(vim.o.columns * 0.8)) / 2)
                end,
                winblend = 0,
            },
            start_in_insert = true,
            shade_terminals = true,
            persist_size = true,
        })
    end
}
