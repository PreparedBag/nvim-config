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

-- Marks
-- Add mark
-- vim.api.nvim_set_keymap('n', '<leader>mah', 'mh', opts)
-- vim.api.nvim_set_keymap('n', '<leader>maj', 'mj', opts)
-- vim.api.nvim_set_keymap('n', '<leader>mak', 'mk', opts)
-- vim.api.nvim_set_keymap('n', '<leader>mal', 'ml', opts)
-- vim.api.nvim_set_keymap('n', '<leader>mh', '`h', opts)
-- vim.api.nvim_set_keymap('n', '<leader>mj', '`j', opts)
-- vim.api.nvim_set_keymap('n', '<leader>mk', '`k', opts)
-- vim.api.nvim_set_keymap('n', '<leader>ml', '`l', opts)

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
    local current_bufnr = vim.api.nvim_get_current_buf()
    local preview_bufnr = vim.g.binary_preview_bufnr
    local preview_winid = vim.g.binary_preview_winid
    
    -- If we're IN the preview buffer, close it and return to original
    if preview_bufnr and current_bufnr == preview_bufnr then
        if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
            vim.api.nvim_win_close(preview_winid, true)
            vim.g.binary_preview_winid = nil
            vim.g.binary_preview_bufnr = nil
        end
        return
    end
    
    -- Don't run in oil or special buffers (but we already handled preview above)
    if vim.bo.filetype == "oil" or vim.bo.buftype ~= "" then 
        return 
    end
    
    -- If preview exists and is valid, close it
    if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
        vim.api.nvim_win_close(preview_winid, true)
        vim.g.binary_preview_winid = nil
        vim.g.binary_preview_bufnr = nil
        return
    end
    
    -- Get the current buffer content
    local lines = vim.api.nvim_buf_get_lines(current_bufnr, 0, -1, false)
    local filename = vim.api.nvim_buf_get_name(current_bufnr)
    
    -- Create a new split and scratch buffer
    vim.cmd("split")
    local preview_win = vim.api.nvim_get_current_win()
    local preview_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(preview_win, preview_buf)
    
    -- Set buffer options for scratch buffer
    vim.api.nvim_buf_set_option(preview_buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(preview_buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(preview_buf, "swapfile", false)
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)
    
    -- Set a descriptive name
    vim.api.nvim_buf_set_name(preview_buf, "[Binary Preview] " .. vim.fn.fnamemodify(filename, ":t"))
    
    -- Run xxd on the content
    local xxd_output = vim.fn.systemlist("xxd", lines)
    
    -- Insert the xxd output
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, xxd_output)
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)
    
    -- Store the window and buffer IDs for toggling
    vim.g.binary_preview_winid = preview_win
    vim.g.binary_preview_bufnr = preview_buf
    
end, { desc = "Toggle Binary Preview" })

-- Make file executable
vim.api.nvim_set_keymap("n", "<leader>x", "<cmd>!chmod +x %<CR>", opts)
-- Replace word under cursor globally
vim.api.nvim_set_keymap("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], opts)

vim.keymap.set('n', '<leader>lr', function()
    vim.notify("LSP not attached")
end, opts)
vim.keymap.set('n', '<leader>ld', function()
    vim.notify("LSP not attached")
end, opts)
vim.keymap.set('n', '<leader>la', function()
    vim.notify("LSP not attached")
end, opts)
vim.keymap.set('n', '<leader>lt', function()
    vim.notify("LSP not attached")
end, opts)

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
