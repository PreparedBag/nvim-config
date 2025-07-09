return {
    "mbbill/undotree",
    version = '*',
    config = function()
        vim.g.undotree_DiffAutoOpen = 0
        local opts = { noremap = true, silent = true }
        vim.keymap.set("n", "<leader>u", function()
            if vim.bo.filetype ~= "nerdtree" then
                vim.cmd("UndotreeToggle")
                vim.cmd("UndotreeFocus")
                vim.schedule(function()
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].filetype == "undotree" then
                            vim.api.nvim_win_set_width(win, 40)
                        end
                    end
                end)
            end
        end, opts)
    end
}
