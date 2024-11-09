return {
    'stevearc/oil.nvim',
    dependencies = { "echasnovski/mini.icons" },
    config = function()
        require("oil").setup()
        vim.keymap.set("n", "<leader>fe", ":Oil<CR>", { noremap = true, silent = true })
    end
}
