if not require("config.flags").get("HTML_VIEWER") then
    return
end

local function stop_servers()
    vim.fn.system("pkill -f 'flask-dev-server.py' 2>/dev/null")
    vim.fn.system("pkill -f 'static-dev-server.py' 2>/dev/null")
    vim.fn.system("fuser -k 3000/tcp 2>/dev/null")
    vim.fn.system("fuser -k 5000/tcp 2>/dev/null")
end

local function uses_flask(file)
    local lines = vim.fn.readfile(file)
    for _, line in ipairs(lines) do
        if string.match(line, "url_for") or
            string.match(line, "{{%s*.*%s*}}") or
            string.match(line, "{%%.*%%}") then
            return true
        end
    end
    return false
end

local function open_browser(url, delay)
    vim.defer_fn(function()
        vim.fn.jobstart({ 'xdg-open', url }, { detach = true })
    end, delay)
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "html" },
    callback = function(ev)
        vim.keymap.set('n', '<leader>mh', function()
            local file = vim.fn.expand('%:p')
            local name = vim.fn.expand('%:t')
            local dir = vim.fn.expand('%:p:h')
            local misc = vim.fn.stdpath('config') .. '/misc'

            stop_servers()

            if uses_flask(file) then
                vim.notify("Flask detected...starting Flask dev server...", vim.log.levels.INFO)
                vim.fn.jobstart(
                    { 'python3', misc .. '/flask-dev-server.py', dir, name },
                    { detach = true }
                )
                open_browser('http://localhost:5000', 1000)
            else
                vim.notify("Starting static dev server...", vim.log.levels.INFO)
                vim.fn.jobstart(
                    { 'python3', misc .. '/static-dev-server.py', dir, name, '3000' },
                    { detach = true }
                )
                open_browser('http://localhost:3000', 400)
            end
        end, { buffer = ev.buf, noremap = true, silent = true, desc = "Start/Restart HTML Server" })

        vim.keymap.set('n', '<leader>mH', function()
            stop_servers()
            vim.notify("HTML/Flask server stopped", vim.log.levels.INFO)
        end, { buffer = ev.buf, noremap = true, silent = true, desc = "Stop HTML Server" })
    end,
})
