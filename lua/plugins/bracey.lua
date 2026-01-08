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
            local current_file = vim.fn.expand('%:p')
            local current_filename = vim.fn.expand('%:t')
            local current_dir = vim.fn.expand('%:p:h')

            -- Check if file contains Flask syntax
            local lines = vim.fn.readfile(current_file)
            local uses_flask = false
            for _, line in ipairs(lines) do
                if string.match(line, "url_for") or
                    string.match(line, "{{%s*.*%s*}}") or
                    string.match(line, "{%%.*%%}") then
                    uses_flask = true
                    break
                end
            end

            if uses_flask then
                -- Use Flask server
                vim.notify("Flask imports detected...running local Flask dev server...", vim.log.levels.INFO)
                vim.fn.system("pkill -f 'flask-dev-server.py' 2>/dev/null")
                local flask_script = vim.fn.stdpath('config') .. '/flask-dev-server.py'
                vim.fn.jobstart(
                    { 'python3', flask_script, current_dir, current_filename },
                    { detach = true }
                )
                vim.defer_fn(function()
                    vim.fn.jobstart({ 'xdg-open', 'http://localhost:5000' }, { detach = true })
                end, 1000)
            else
                -- Use Bracey for regular HTML
                vim.notify("Starting HTML server...", vim.log.levels.INFO)
                vim.cmd('Bracey')
                vim.fn.jobstart({ 'xdg-open', 'http://localhost:3000' }, { detach = true })
            end
        end, { noremap = true, silent = true })
    end,
}
