-- store configuration (minimal vs full dev)
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
end, { desc = "Toggle Dev Mode" })

vim.keymap.set("n", "Q", "<nop>", { noremap = true, silent = true, desc = "Useless" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Move selection up" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Move selection down" })
vim.keymap.set('i', '<C-l>', '<Right>', { noremap = true, silent = true, desc = 'Move cursor right in insert mode' })
vim.keymap.set('i', '<C-h>', '<Left>', { noremap = true, silent = true, desc = 'Move cursor left in insert mode' })
vim.keymap.set("n", "J", "mzJ`z", { noremap = true, silent = true, desc = "Join lines" })
vim.keymap.set("n", "<C-d>", function() vim.cmd("normal! \4zz") end, { noremap = true, silent = true, desc = "Jump half-page down" })
vim.keymap.set("n", "<C-u>", function() vim.cmd("normal! \21zz") end, { noremap = true, silent = true, desc = "Jump half-page up" })
-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true, desc = "Jump half-page down" })
-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true, desc = "Jump half-page up" })
vim.keymap.set("n", "n", "nzzzv", { noremap = true, silent = true, desc = "Next result" })
vim.keymap.set("n", "N", "Nzzzv", { noremap = true, silent = true, desc = "Prev result" })

vim.keymap.set('n', '<Esc>', ':nohlsearch<CR><Esc>', { noremap = true, silent = true, desc = "ESC and clear highlights" })

-- vim.keymap.set("n", "<leader>j", "<cmd>cnext<CR>zz", { noremap = true, silent = true, desc = "Next Quickfix Item" })
vim.keymap.set("n", "<leader>j", function()
    local ok = pcall(vim.cmd.cnext)
    if not ok then
        -- TEST: uncomment for wrapping
        -- pcall(vim.cmd.cfirst) -- past the end -> wrap to first
        vim.notify("End of quickfix list", vim.log.levels.INFO)
    end
end, { noremap = true, silent = true, desc = "Next Quickfix Item" })

-- vim.keymap.set("n", "<leader>k", "<cmd>cprev<CR>zz", { noremap = true, silent = true, desc = "Prev Quickfix Item" })
vim.keymap.set("n", "<leader>k", function()
    local ok = pcall(vim.cmd.cprev)
    if not ok then
        -- TEST: uncomment for wrapping
        -- pcall(vim.cmd.clast) -- before the start -> wrap to last
        vim.notify("Start of quickfix list", vim.log.levels.INFO)
    end
end, { noremap = true, silent = true, desc = "Previous Quickfix Item" })

-- keep `*` / `#` centered
vim.keymap.set("n", "*", "*zzzv", { noremap = true, silent = true, desc = "Next match" })
vim.keymap.set("n", "#", "#zzzv", { noremap = true, silent = true, desc = "Prev match" })

-- window management
vim.keymap.set('n', '<leader>sh', ':split<CR>', { noremap = true, silent = true, desc = "Horizontal Split" })
vim.keymap.set('n', '<leader>sv', ':vsplit<CR>', { noremap = true, silent = true, desc = "Vertical Split" })
vim.keymap.set('n', '<leader>ww', '<C-w><C-w>', { noremap = true, silent = true, desc = "Toggle Window Focus" })
vim.keymap.set('n', '<leader>wh', '<C-w>h', { noremap = true, silent = true, desc = "Focus Left" })
vim.keymap.set('n', '<leader>wl', '<C-w>l', { noremap = true, silent = true, desc = "Focus Right" })
vim.keymap.set('n', '<leader>wj', '<C-w>j', { noremap = true, silent = true, desc = "Focus Down" })
vim.keymap.set('n', '<leader>wk', '<C-w>k', { noremap = true, silent = true, desc = "Focus Up" })
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { noremap = true, silent = true, desc = "Increase vertical (+2)" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { noremap = true, silent = true, desc = "Decrease vertical (-2)" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>",
    { noremap = true, silent = true, desc = "Decrease Horizontal (-2)" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>",
    { noremap = true, silent = true, desc = "Increase Horizontal (+2)" })
vim.keymap.set("n", "<leader>we", "<C-w>=", { noremap = true, silent = true, desc = "Equalize All" })

-- copy/paste
vim.keymap.set("x", "<leader>p", [["_dP]], { noremap = true, silent = true, desc = "Paste Without Yank" })
vim.keymap.set("x", "<leader>y", [["+y]], { noremap = true, silent = true, desc = "Yank selection to clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { noremap = true, silent = true, desc = "Yank Line to Clipboard" })

-- quit current buffer without saving
vim.keymap.set("n", "<leader>q", function()
    if not vim.bo.modified then
        vim.cmd("quit")
        return
    end

    vim.ui.select(
        { "Save and quit", "Quit without saving", "Cancel" },
        { prompt = "Unsaved changes in this buffer:" },
        function(choice)
            if choice == "Save and quit" then
                vim.cmd("write")
                vim.cmd("quit")
            elseif choice == "Quit without saving" then
                vim.cmd("quit!")
            end
            -- Cancel or dismiss (Esc): do nothing
        end
    )
end, { silent = true, desc = "Quit with Confirm" })

-- buffers
vim.keymap.set("n", "<C-s>", "<cmd>w<cr>", { noremap = true, silent = true, desc = "Save current buffer" })
vim.keymap.set("n", "<leader><Tab>", "<cmd>bnext<cr>", { noremap = true, silent = true, desc = "Next buffer" })
-- TODO: uncomment for previous buffer navigation
-- vim.keymap.set("n", "<leader><S-Tab>", "<cmd>bprevious<cr>", { noremap = true, silent = true, desc = "Prev buffer" })
local function delete_buffers()
    local builtin = require('telescope.builtin')
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    builtin.buffers({
        initial_mode = 'normal',
        prompt_title = 'Delete Buffers',
        attach_mappings = function(prompt_bufnr, map)
            local function delete_selected()
                local picker = action_state.get_current_picker(prompt_bufnr)
                local selections = picker:get_multi_selection()
                if #selections == 0 then
                    local entry = action_state.get_selected_entry()
                    if entry then selections = { entry } end
                end

                actions.close(prompt_bufnr)

                local failed = {}
                for _, entry in ipairs(selections) do
                    if vim.api.nvim_buf_is_valid(entry.bufnr) then
                        local name = vim.api.nvim_buf_get_name(entry.bufnr)
                        local ok = pcall(vim.api.nvim_buf_delete, entry.bufnr, { force = false })
                        if not ok then
                            table.insert(failed, name ~= '' and name or ('buffer ' .. entry.bufnr))
                        end
                    end
                    -- already invalid (e.g. wiped as a side effect of an earlier
                    -- delete in this same batch) -> nothing to do, it's already gone
                end

                if #failed > 0 then
                    vim.notify('Unsaved changes, not deleted:\n' .. table.concat(failed, '\n'),
                        vim.log.levels.WARN)
                end
            end

            map('i', '<CR>', delete_selected)
            map('n', '<CR>', delete_selected)
            return true -- keep Telescope's other defaults (Tab multi-select, etc.)
        end,
    })
end

vim.keymap.set('n', '<leader>bd', delete_buffers, { noremap = true, silent = true, desc = 'Delete Buffers' })
vim.keymap.set("n", "<leader>bb", ":Telescope buffers<CR><ESC>", { noremap = true, silent = true, desc = "Show All" })
vim.keymap.set('n', '<leader>br', function()
    if vim.bo.modified then
        vim.notify('Buffer has unsaved changes - save or discard first', vim.log.levels.WARN)
        return
    end
    vim.cmd('edit!')
    pcall(vim.cmd, 'TSBufDisable highlight')
    pcall(vim.cmd, 'TSBufEnable highlight')
end, { noremap = true, silent = true, desc = 'Reload Buffer from File' })

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { noremap = true, silent = true, desc = "Make File Executable" })
vim.keymap.set('v', '<Tab>', '>gv', { noremap = true, silent = true, desc = "Indent right" })
vim.keymap.set('v', '<S-Tab>', '<gv', { noremap = true, silent = true, desc = "Indent left" })
vim.keymap.set('i', 'jk', '<Esc>', { noremap = true, silent = true, desc = "ESC" })

-- folding
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
