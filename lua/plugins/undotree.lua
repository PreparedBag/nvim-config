return {
    "mbbill/undotree",
    version = '*',
    config = function()
        vim.g.undotree_DiffAutoOpen = 0
        local opts = { noremap = true, silent = true }
        vim.keymap.set("n", "<leader>u", function()
            vim.cmd("UndotreeToggle")
            vim.cmd("UndotreeFocus")
        end, opts)
    end
}
