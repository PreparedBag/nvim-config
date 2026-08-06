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

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches", "dapui_repl", "dapui_console" },
    callback = function()
        vim.opt_local.cursorline = false
        vim.opt_local.cursorcolumn = false
    end,
})

