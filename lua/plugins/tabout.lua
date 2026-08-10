return {
    "abecodes/tabout.nvim",
    enabled = require("config.flags").get("LSP_ENABLED"),
    dependencies = { "nvim-treesitter/nvim-treesitter", "L3MON4D3/LuaSnip" },
    opts = {
        tabkey = "<Tab>",
        backwards_tabkey = "<S-Tab>",
        act_as_tab = true,
        act_as_shift_tab = true,
        enable_backwards = true,
        completion = false,
        tabouts = {
            { open = "'", close = "'" },
            { open = '"', close = '"' },
            { open = "`", close = "`" },
            { open = "(", close = ")" },
            { open = "[", close = "]" },
            { open = "{", close = "}" },
        },
        ignore_beginning = true,
        exclude = {},
    },
}
