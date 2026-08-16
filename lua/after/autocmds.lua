-- Regenerate local :help tags on startup, so doc/nvim-config.txt (and any
-- other custom help files added later) are always searchable via :h / <leader>fH.
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.cmd("silent! helptags ~/.config/nvim/doc")
    end,
})

-- Fixes window resizing when popups are active
vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("WinResize", { clear = true }),
    pattern = "*",
    command = "wincmd =",
    desc = "Auto-resize windows on terminal buffer resize.",
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileType" }, {
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local special = vim.bo[buf].buftype ~= "" or vim.bo[buf].readonly or not vim.bo[buf].modifiable

        if special then
            vim.opt_local.fillchars:append({ eob = " " })
        else
            vim.opt_local.fillchars:remove("eob")
        end
    end,
})

local function sudo_write()
    local path = vim.fn.expand('%:p')
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

    local tmp = vim.fn.tempname()
    vim.fn.writefile(lines, tmp)
    pcall(vim.fn.setfperm, tmp, 'rw-------') -- user-only, belt and suspenders

    local password = vim.fn.inputsecret('sudo password: ')
    if password == '' then
        vim.fn.delete(tmp)
        vim.notify('Cancelled', vim.log.levels.WARN)
        return
    end

    -- Nothing but the password ever goes on this stdin - cp reads its
    -- content from the tmp file path, never from stdin at all.
    local result = vim.system(
        { 'sudo', '-S', 'cp', tmp, path },
        { stdin = password .. '\n' }
    ):wait()

    vim.fn.delete(tmp)

    if result.code == 0 then
        vim.bo.modified = false
        pcall(vim.cmd, 'wundo! ' .. vim.fn.fnameescape(vim.fn.undofile(path)))
        vim.api.nvim_exec_autocmds('BufWritePost', { buffer = 0 })
        vim.notify('Saved (sudo): ' .. path, vim.log.levels.INFO)
    else
        vim.notify('sudo write failed:\n' .. (result.stderr ~= '' and result.stderr or result.stdout),
            vim.log.levels.ERROR)
    end
end

pcall(vim.api.nvim_del_user_command, 'W')
vim.api.nvim_create_user_command('W', sudo_write, {})
