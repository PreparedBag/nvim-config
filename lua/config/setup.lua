vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

vim.o.sessionoptions = "buffers,curdir,folds,globals,help,tabpages,winsize,winpos,localoptions"

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.nrformats = { "alpha", "hex", "bin" }

-- Disable Netrw banner
vim.g.netrw_banner = 0

vim.opt.showmode = false
vim.opt.guicursor = ""
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.breakindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undodir = os.getenv("HOME") .. "/.config/nvim/.undodir"
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes:2"
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.hidden = true
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.splitbelow = false
vim.opt.splitright = true

-- vim.opt.timeout = true
-- vim.opt.timeoutlen = 300
-- vim.opt.mouse = "a"
