return {
    "uga-rosa/ccc.nvim",
    cmd = { "CccPick", "CccConvert", "CccHighlighterToggle" },
    keys = {
        { "<leader>cp", "<cmd>CccPick<cr>", desc = "Color Picker" },
    },
    opts = {
        highlighter = {
            auto_enable = false,
            lsp = false,
        },
    },
}
