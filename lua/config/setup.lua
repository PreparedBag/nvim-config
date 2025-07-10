-- Leader keys
-- Set space as the leader key
vim.g.mapleader = " "
-- Set space as the local leader key
vim.g.maplocalleader = " "

-- Disable Netrw banner
vim.g.netrw_banner = 0

-- General Settings
-- Disable mode display in the command line
vim.opt.showmode = false
-- Disable GUI cursor
vim.opt.guicursor = ""
-- Show line numbers
vim.opt.number = true
-- Show relative line numbers
vim.opt.relativenumber = true
-- Set tab width to 4 spaces
vim.opt.tabstop = 4
-- Set soft tabstop to 4 spaces
vim.opt.softtabstop = 4
-- Set shift width (indentation) to 4 spaces
vim.opt.shiftwidth = 4
-- Convert tabs to spaces
vim.opt.expandtab = true
-- Enable smart indentation
vim.opt.smartindent = true
-- Enable break indent for wrapping long lines
vim.opt.breakindent = true
-- Disable line wrapping
vim.opt.wrap = false
-- Disable swap files
vim.opt.swapfile = false
-- Disable backup files
vim.opt.backup = false
vim.opt.writebackup = false
-- Set undo directory and enable undo file
vim.opt.undodir = os.getenv("HOME") .. "/.config/nvim/.undodir"
vim.opt.undofile = true
-- Highlight search results
vim.opt.hlsearch = true
-- Enable incremental search
vim.opt.incsearch = true
-- Ignore case in searches
vim.opt.ignorecase = true
-- Enable true color support
vim.opt.termguicolors = true
-- Keep 9 lines above and below the cursor
vim.opt.scrolloff = 9
-- Always show the sign column
vim.opt.signcolumn = "yes"
-- Append '@-@' to valid file names
vim.opt.isfname:append("@-@")
-- Set update time to 100ms for faster UI updates
vim.opt.updatetime = 100
-- Allow hidden buffers
vim.opt.hidden = true
-- Enable line wrapping
vim.opt.wrap = true
-- Use system clipboard for all yank, delete, change, and put operations
-- vim.opt.clipboard = "unnamedplus"
-- Highlight the current line
vim.opt.cursorline = true

-- Completion Settings
-- Configure completion menu behavior
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Splitting behavior
-- Open new horizontal splits below the current window
vim.opt.splitbelow = true
-- Open new vertical splits to the right of the current window
vim.opt.splitright = true

-- Enable mouse support in all modes
vim.opt.mouse = "a"

-- Folding Settings
-- Set maximum fold level
vim.opt.foldlevel = 99
-- Start with all folds open
vim.opt.foldlevelstart = 99
-- Enable folding
vim.opt.foldenable = true
-- Set the fold column width to 0 (hide fold column)
vim.opt.foldcolumn = "0"
-- Set maximum nested folds
vim.opt.foldnestmax = 5
-- Set empty fold text (fold summary)
vim.opt.foldtext = ""
