-- toggle binary mode
vim.keymap.set("n", "<leader>nt", function()
    local current_bufnr = vim.api.nvim_get_current_buf()
    local preview_bufnr = vim.g.binary_preview_bufnr
    local preview_winid = vim.g.binary_preview_winid

    -- If we're IN the preview buffer, close it and return to session
    if preview_bufnr and current_bufnr == preview_bufnr then
        if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
            vim.api.nvim_win_close(preview_winid, true)
            vim.g.binary_preview_winid = nil
            vim.g.binary_preview_bufnr = nil
        end
        return
    end

    -- don't run in oil or special buffers (but we already handled preview above)
    if vim.bo.filetype == "oil" or vim.bo.buftype ~= "" then
        return
    end

    -- if preview exists and is valid, close it
    if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
        vim.api.nvim_win_close(preview_winid, true)
        vim.g.binary_preview_winid = nil
        vim.g.binary_preview_bufnr = nil
        return
    end

    local filename = vim.api.nvim_buf_get_name(current_bufnr)

    -- check if file exists
    if filename == "" or vim.fn.filereadable(filename) == 0 then
        vim.notify("Cannot read file", vim.log.levels.ERROR)
        return
    end

    -- create a new split and scratch buffer
    vim.cmd("split")
    local preview_win = vim.api.nvim_get_current_win()
    local preview_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(preview_win, preview_buf)

    -- set buffer options for scratch buffer
    vim.api.nvim_buf_set_option(preview_buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(preview_buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(preview_buf, "swapfile", false)
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)

    -- set a descriptive name
    vim.api.nvim_buf_set_name(preview_buf, "[Binary Preview] " .. vim.fn.fnamemodify(filename, ":t"))

    -- run xxd directly on the file (fixed line)
    local xxd_output = vim.fn.systemlist("xxd " .. vim.fn.shellescape(filename))

    -- insert the xxd output
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, xxd_output)
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)

    -- store the window and buffer ids for toggling
    vim.g.binary_preview_winid = preview_win
    vim.g.binary_preview_bufnr = preview_buf
end, { noremap = true, silent = true, desc = "Toggle Binary Preview" })

return {
    {
        "Wansmer/treesj",
        enabled = _G.DEV_ENABLED,
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        keys = {
            { "<leader>J", "<cmd>TSJToggle<cr>", desc = "Toggle Split/Join" },
        },
        opts = {
            use_default_keymaps = false, -- using our own <leader>J above
            -- TODO: update max length
            max_join_length = 500,
        },
    },
    -- TODO: comment/uncomment for autopairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        enabled = _G.DEV_ENABLED,
        opts = {
            check_ts = true, -- treesitter-aware: skip pairing inside strings/comments
            fast_wrap = {},  -- <M-e> fast-wraps the next node in a pair
        },
    },
}
