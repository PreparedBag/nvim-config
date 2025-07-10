-- Store options for reuse
local opts = { noremap = true, silent = true }

-- Moving Lines
-- Move selected text down
vim.api.nvim_set_keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
-- Move selected text up
vim.api.nvim_set_keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Joining and Scrolling
-- Join lines and keep cursor in place
vim.api.nvim_set_keymap("n", "J", "mzJ`z", opts)
-- Scroll half-page down and center
vim.api.nvim_set_keymap("n", "<C-d>", "<C-d>zz", opts)
-- Scroll half-page up and center
vim.api.nvim_set_keymap("n", "<C-u>", "<C-u>zz", opts)

-- Search Navigation
-- Next search result and center
vim.api.nvim_set_keymap("n", "n", "nzzzv", opts)
-- Previous search result and center
vim.api.nvim_set_keymap("n", "N", "Nzzzv", opts)
-- Clear search highlight
vim.api.nvim_set_keymap('n', '<Esc>', ':nohlsearch<CR><Esc>', opts)
-- Show netrw
vim.api.nvim_set_keymap('n', '<leader>fe', ':Ex<CR>', opts)

-- Quickfix and Location Lists
-- Go to next quickfix item and center
vim.api.nvim_set_keymap("n", "<C-k>", "<cmd>cnext<CR>zz", opts)
-- Go to previous quickfix item and center
vim.api.nvim_set_keymap("n", "<C-j>", "<cmd>cprev<CR>zz", opts)
-- Go to next location list item and center
vim.api.nvim_set_keymap("n", "<leader>k", "<cmd>lnext<CR>zz", opts)
-- Go to previous location list item and center
vim.api.nvim_set_keymap("n", "<leader>j", "<cmd>lprev<CR>zz", opts)

-- LSP Management
-- Start LSP
vim.api.nvim_set_keymap('n', '<leader>ls', '<cmd>LspStart<CR>', opts)
-- Stop LSP
vim.api.nvim_set_keymap('n', '<leader>lc', '<cmd>LspStop<CR>', opts)

-- Marks
-- Add mark
vim.api.nvim_set_keymap('n', '<leader>mah', 'mh', opts)
vim.api.nvim_set_keymap('n', '<leader>maj', 'mj', opts)
vim.api.nvim_set_keymap('n', '<leader>mak', 'mk', opts)
vim.api.nvim_set_keymap('n', '<leader>mal', 'ml', opts)
vim.api.nvim_set_keymap('n', '<leader>mh', '`h', opts)
vim.api.nvim_set_keymap('n', '<leader>mj', '`j', opts)
vim.api.nvim_set_keymap('n', '<leader>mk', '`k', opts)
vim.api.nvim_set_keymap('n', '<leader>ml', '`l', opts)

-- Window Management
-- Split window horizontally
vim.api.nvim_set_keymap('n', '<leader>sh', ':split<CR>', opts)
-- Split window vertically
vim.api.nvim_set_keymap('n', '<leader>sv', ':vsplit<CR>', opts)
-- Switch to the next window
vim.api.nvim_set_keymap('n', '<leader>ww', '<C-w><C-w>', opts)
-- Focus left window
vim.api.nvim_set_keymap('n', '<leader>wh', '<C-w>h', opts)
-- Focus right window
vim.api.nvim_set_keymap('n', '<leader>wl', '<C-w>l', opts)
-- Focus below window
vim.api.nvim_set_keymap('n', '<leader>wj', '<C-w>j', opts)
-- Focus above window
vim.api.nvim_set_keymap('n', '<leader>wk', '<C-w>k', opts)

-- Clipboard
-- Paste from system clipboard
vim.api.nvim_set_keymap('n', '<leader>p', '"+P', opts)
vim.api.nvim_set_keymap('v', '<leader>p', '"+P', opts)
-- Paste over selection without overwriting default register
vim.api.nvim_set_keymap("x", "<leader>v", [["_dP]], opts)
-- Yank to system clipboard
vim.api.nvim_set_keymap("n", "<leader>y", [["+y]], opts)
vim.api.nvim_set_keymap("v", "<leader>y", [["+y]], opts)
-- Delete without affecting clipboard
vim.api.nvim_set_keymap("n", "<leader>d", [["_d]], opts)
vim.api.nvim_set_keymap("v", "<leader>d", [["_d]], opts)

-- Miscellaneous
-- Quit
vim.api.nvim_set_keymap("n", "<leader>q", ":q<CR>", opts)
-- Close buffer
vim.api.nvim_set_keymap("n", "<leader>bd", ":bd<CR>", opts)
-- Open buffer list with Telescope
vim.api.nvim_set_keymap("n", "<leader>bb", ":Telescope buffers<CR><ESC>", opts)
-- Toggle binary mode
vim.keymap.set("n", "<leader>bt", function()
    if vim.bo.filetype == "oil" or vim.bo.buftype ~= "" then return end
    local is_binary = vim.fn.getline(1):match("^%x%x%x%x%x%x%x%x:")
    if is_binary then
        vim.cmd("syntax on")
        vim.cmd("LspStart")
        vim.cmd("%!xxd -r")
        vim.cmd("write")
    else
        vim.cmd("syntax off")
        vim.cmd("LspStop")
        vim.cmd("%!xxd")
    end
end, { desc = "Toggle Binary Mode" })
-- Make file executable
vim.api.nvim_set_keymap("n", "<leader>x", "<cmd>!chmod +x %<CR>", opts)
-- Replace word under cursor globally
vim.api.nvim_set_keymap("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], opts)

-- Terminal
-- Exit terminal mode
vim.api.nvim_set_keymap('t', '<ESC>', '<C-\\><C-n>', opts)

-- Indentation in Visual Mode
-- Indent right
vim.api.nvim_set_keymap('v', '<Tab>', '>gv', opts)
-- Indent left
vim.api.nvim_set_keymap('v', '<S-Tab>', '<gv', opts)

-- Escape in Insert Mode
-- Map 'jk' to escape in insert mode
vim.api.nvim_set_keymap('i', 'jk', '<Esc>', opts)

-- Commenting with Comment.nvim
-- Comment current line
vim.api.nvim_set_keymap('n', 'gcc', '<Plug>(comment_toggle_linewise_current)', opts)
-- Comment selection in visual mode
vim.api.nvim_set_keymap('x', 'gc', '<Plug>(comment_toggle_linewise_visual)', opts)
