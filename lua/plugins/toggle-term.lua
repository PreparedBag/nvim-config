return {
    'akinsho/toggleterm.nvim',
    version = '*',
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
        local opts = { noremap = true, silent = true }
        vim.api.nvim_set_keymap("n", "<leader>,", ":ToggleTerm<CR>", opts)
    end
}
