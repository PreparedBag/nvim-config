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

vim.opt.winborder = "rounded"

-- Treesitter-based folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = false
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldnestmax = 5

-- Transparent fold line -> keeps syntax highlighting
vim.opt.foldtext = ""

-- Fold column: blank normally, "+" next to a closed fold
vim.opt.foldcolumn = "1"
vim.opt.fillchars:append({
    fold = " ",
    foldclose = "+",
    foldopen = " ",
    foldsep = " ",
})
