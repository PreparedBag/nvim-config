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
                if vim.bo[ev.buf].buftype ~= "" then
                    return
                end
                vim.keymap.set("n", "<leader>c", "<cmd>CccPick<cr>", { noremap = true, silent = true, desc = "Color Picker" })
            end,
        })
    end,
}
