return {
    "uga-rosa/ccc.nvim",
    opts = {
        highlighter = {
            auto_enable = false,
            lsp = false,
        },
    },
    config = function(_, opts)
        require("ccc").setup(opts)
        vim.api.nvim_create_autocmd("FileType", {
            -- pattern = "css",
            callback = function(ev)
                vim.keymap.set("n", "<leader>c", "<cmd>CccPick<cr>",
                    { buffer = ev.buf, desc = "Color Picker" })
            end,
        })
    end,
}
