vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.health = { style = 'float' }

vim.g.netrw_banner = 0

vim.o.sessionoptions = 'buffers,curdir,folds,help,tabpages,winsize,localoptions,terminal'
vim.o.showmode = false
vim.o.guicursor = ""
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.breakindent = true
vim.o.wrap = false
vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false
vim.o.undodir = vim.fn.stdpath('state') .. '/undo//' -- ~/.local/state/nvim/undo
vim.o.undofile = true
vim.o.hlsearch = false
vim.o.incsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.termguicolors = true
vim.o.scrolloff = 8
vim.o.signcolumn = "yes:2"
vim.o.updatetime = 50
vim.o.hidden = true
vim.o.wrap = false
vim.o.cursorline = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.modeline = false
-- vim.o.timeout = true
-- vim.o.timeoutlen = 250
-- vim.o.winbar = ""

vim.opt.isfname:append("@-@")
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.winborder = "rounded"

-- Treesitter-based folding (starts off, toggle with zi)
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldenable = false
vim.o.foldlevel = 99 
vim.o.foldtext = ""
vim.o.foldcolumn = "1"
vim.opt.fillchars:append({
    fold = " ",
    foldclose = "+",
    foldopen = " ",
    foldsep = " ",
})

-- vim.o.mouse = "a"
