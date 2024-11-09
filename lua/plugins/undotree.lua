return {
    "mbbill/undotree",
    version = '*',
    config = function()
        vim.g.undotree_DiffAutoOpen = 0
        local opts = { noremap = true, silent = true }
        vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", opts)
    end
}
