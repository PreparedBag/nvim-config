-- Store options for reuse
local opts = { noremap = true, silent = true }

-- Store configuration (minimal vs full dev)
vim.keymap.set("n", "<leader>M", function()
    local marker = vim.fn.stdpath("data") .. "/nvim-dev"
    local now_dev = vim.fn.filereadable(marker) == 1
        and vim.trim(vim.fn.readfile(marker)[1] or "") == "true"
    local next_dev = not now_dev
    vim.fn.writefile({ tostring(next_dev) }, marker)
    vim.notify(
        ("Dev mode %s — restart nvim to apply")
            :format(next_dev and "ON" or "OFF"),
        vim.log.levels.INFO
    )
end, { desc = "Toggle Dev Mode (Restart to Apply)" })

-- Moving Lines
-- Move selected text down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", opts)
-- Move selected text up
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", opts)
-- Move cursor right in insert mode (useful after accepting completions with parens)
vim.keymap.set('i', '<C-l>', '<Right>', { noremap = true, silent = true, desc = 'Move cursor right in insert mode' })
vim.keymap.set('i', '<C-b>', '<Left>', { noremap = true, silent = true, desc = 'Move cursor left in insert mode' })

-- Joining and Scrolling
-- Join lines and keep cursor in place
vim.keymap.set("n", "J", "mzJ`z", opts)
-- Scroll half-page down and center
vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
-- Scroll half-page up and center
vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)

-- Search Navigation
-- Next search result and center
vim.keymap.set("n", "n", "nzzzv", opts)
-- Previous search result and center
vim.keymap.set("n", "N", "Nzzzv", opts)
-- Clear search highlight
vim.keymap.set('n', '<Esc>', ':nohlsearch<CR><Esc>', opts)

-- Next file in buffers
-- vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
-- Previous file in buffers
-- vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })

-- Quickfix navigation (telescope/grep results land here)
vim.keymap.set("n", "<leader>j", function()
    local ok = pcall(vim.cmd.cnext)
    if not ok then
        pcall(vim.cmd.cfirst) -- past the end -> wrap to first
        -- vim.notify("End of quickfix list", vim.log.levels.INFO)
    end
end, { noremap = true, silent = true, desc = "Next Quickfix Item" })
vim.keymap.set("n", "<leader>k", function()
    local ok = pcall(vim.cmd.cprev)
    if not ok then
        pcall(vim.cmd.clast) -- before the start -> wrap to last
        -- vim.notify("Start of quickfix list", vim.log.levels.INFO)
    end
end, { noremap = true, silent = true, desc = "Previous Quickfix Item" })

-- Keep `*` / `#` centered
vim.keymap.set("n", "*", "*zzzv", opts)
vim.keymap.set("n", "#", "#zzzv", opts)

-- Marks
-- Add mark
-- vim.keymap.set('n', '<leader>mah', 'mh', opts)
-- vim.keymap.set('n', '<leader>maj', 'mj', opts)
-- vim.keymap.set('n', '<leader>mak', 'mk', opts)
-- vim.keymap.set('n', '<leader>mal', 'ml', opts)
-- vim.keymap.set('n', '<leader>mh', '`h', opts)
-- vim.keymap.set('n', '<leader>mj', '`j', opts)
-- vim.keymap.set('n', '<leader>mk', '`k', opts)
-- vim.keymap.set('n', '<leader>ml', '`l', opts)

-- Window Management
vim.keymap.set('n', '<leader>sh', ':split<CR>', { noremap = true, silent = true, desc = "Horizontal Split" })
vim.keymap.set('n', '<leader>sv', ':vsplit<CR>', { noremap = true, silent = true, desc = "Vertical Split" })
vim.keymap.set('n', '<leader>ww', '<C-w><C-w>', { noremap = true, silent = true, desc = "Toggle Window Focus" })
vim.keymap.set('n', '<leader>wh', '<C-w>h', { noremap = true, silent = true, desc = "Focus Left" })
vim.keymap.set('n', '<leader>wl', '<C-w>l', { noremap = true, silent = true, desc = "Focus Right" })
vim.keymap.set('n', '<leader>wj', '<C-w>j', { noremap = true, silent = true, desc = "Focus Down" })
vim.keymap.set('n', '<leader>wk', '<C-w>k', { noremap = true, silent = true, desc = "Focus Up" })
-- Resize windows
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", opts)
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", opts)
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", opts)
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", opts)
-- Equalize all window sizes
vim.keymap.set("n", "<leader>we", "<C-w>=", { noremap = true, silent = true, desc = "Equalize All" })

-- Clipboard
-- Paste over selection without overwriting default register
vim.keymap.set("x", "<leader>p", [["_dP]], { noremap = true, silent = true, desc = "Paste Without Yank" })
-- Yank to system clipboard
vim.keymap.set("n", "<leader>y", [["+y]], { noremap = true, silent = true, desc = "Yank to Clipboard" })
vim.keymap.set("v", "<leader>y", [["+y]], { noremap = true, silent = true, desc = "Yank to Clipboard" })
-- Yank whole line to system clipboard
vim.keymap.set("n", "<leader>Y", [["+Y]], { noremap = true, silent = true, desc = "Yank Line to Clipboard" })

-- Miscellaneous
-- Quit
vim.keymap.set("n", "<leader>q", ":q<CR>", { noremap = true, silent = true, desc = "Quit Without Saving" })
-- Save file
vim.keymap.set("n", "<C-s>", "<cmd>w<cr>", opts)
-- Close buffer
vim.keymap.set("n", "<leader>bd", ":bd<CR>", { noremap = true, silent = true, desc = "Delete Current" })
-- Open buffer list with Telescope
vim.keymap.set("n", "<leader>bb", ":Telescope buffers<CR><ESC>", { noremap = true, silent = true, desc = "Show All" })

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

    local filename = vim.api.nvim_buf_get_name(current_bufnr)

    -- Check if file exists
    if filename == "" or vim.fn.filereadable(filename) == 0 then
        vim.notify("Cannot read file", vim.log.levels.ERROR)
        return
    end

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

    -- Run xxd directly on the file (fixed line)
    local xxd_output = vim.fn.systemlist("xxd " .. vim.fn.shellescape(filename))

    -- Insert the xxd output
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, xxd_output)
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)

    -- Store the window and buffer IDs for toggling
    vim.g.binary_preview_winid = preview_win
    vim.g.binary_preview_bufnr = preview_buf
end, { noremap = true, silent = true, desc = "Toggle Binary Preview" })

-- Make file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { noremap = true, silent = true, desc = "Make File Executable" })
-- Replace word under cursor globally
-- vim.keymap.set("n", "<leader>rw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], opts)

-- References fallback: plain ripgrep. Overridden per-buffer by LSP when attached.
-- vim.keymap.set("n", "<leader>lr", function()
--     local word = vim.fn.expand("<cword>")
--     require("telescope.builtin").grep_string({
--         search = word,
--         initial_mode = "normal",
--         prompt_title = "Ripgrep: " .. word,
--     })
-- end, { silent = true, desc = "Ripgrep Word Under Cursor" })

if _G.DEV_ENABLED then
    vim.keymap.set('n', '<leader>ld', function() vim.notify("LSP not Attached") end,
        { silent = true, desc = "Line Diagnostics" })
    vim.keymap.set('n', '<leader>lr', function() vim.notify("LSP not Attached") end,
        { silent = true, desc = "References" })
    vim.keymap.set('n', '<leader>la', function() vim.notify("LSP not Attached") end,
        { silent = true, desc = "Code Actions" })
    vim.keymap.set('n', '<leader>lw', function() vim.notify("LSP not Attached") end,
        { silent = true, desc = "Workspace Symbols" })
    vim.keymap.set('n', '<leader>lf', function() vim.notify("LSP not Attached") end,
        { silent = true, desc = "Format Document" })
    vim.keymap.set('n', '<leader>lo', function() vim.notify("LSP not Attached") end,
        { silent = true, desc = "Document Symbols" })
    vim.keymap.set('n', '<leader>ln', function() vim.notify("LSP not Attached") end,
        { silent = true, desc = "Refactor Symbol" })
    vim.keymap.set('n', '<leader>lj', function() vim.notify("LSP not Attached") end,
        { silent = true, desc = "Next Diagnostic" })
    vim.keymap.set('n', '<leader>lk', function() vim.notify("LSP not Attached") end,
        { silent = true, desc = "Prev Diagnostic" })
end

-- Terminal
-- Exit terminal mode
vim.keymap.set('t', '<ESC>', '<C-\\><C-n>', opts)

-- Indentation in Visual Mode
-- Indent right
vim.keymap.set('v', '<Tab>', '>gv', opts)
-- Indent left
vim.keymap.set('v', '<S-Tab>', '<gv', opts)

-- Escape in Insert Mode
-- Map 'jk' to escape in insert mode
vim.keymap.set('i', 'jk', '<Esc>', opts)

-- Commenting with Comment.nvim
-- Comment current line
vim.keymap.set('n', 'gcc', '<Plug>(comment_toggle_linewise_current)', opts)
-- Comment selection in visual mode
vim.keymap.set('x', 'gc', '<Plug>(comment_toggle_linewise_visual)', opts)

vim.keymap.set("n", "zt", function()
    vim.opt.foldenable = not vim.opt.foldenable:get()
    vim.notify("Folding " .. (vim.opt.foldenable:get() and "enabled" or "disabled"))
end, { noremap = true, silent = true, desc = "Toggle Enable" })

vim.keymap.set("n", "ze", function()
    vim.opt.foldenable = true
    vim.cmd("normal! zR")
end, { noremap = true, silent = true, desc = "Expand All" })

vim.keymap.set("n", "zc", function()
    vim.opt.foldenable = true
    vim.cmd("normal! zM")
end, { noremap = true, silent = true, desc = "Collapse All" })

vim.keymap.set("n", "zj", function()
    vim.opt.foldenable = true
    if vim.wo.foldlevel > 0 then
        vim.cmd("normal! zM")
    else
        vim.cmd("normal! zR")
    end
end, { noremap = true, silent = true, desc = "Toggle All" })
