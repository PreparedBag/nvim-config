return {
    'turbio/bracey.vim',
    build = 'npm install --prefix server',
    ft = { 'html', 'css', 'javascript' },
    config = function()
        vim.g.bracey_server_port = 3000
        vim.g.bracey_auto_start_browser = 1
        vim.g.bracey_browser_command = "xdg-open http://localhost:3000"
        vim.g.bracey_refresh_on_save = 1

        vim.keymap.set('n', '<leader>mh', function()
            vim.cmd('Bracey')
            vim.fn.jobstart({ 'xdg-open', 'http://localhost:3000' }, { detach = true })
        end, { noremap = true, silent = true })
    end,
}
