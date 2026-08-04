return {
    {
        "abecodes/tabout.nvim",
        event = "InsertCharPre", -- loads as soon as you start typing, ahead of blink's own setup
        priority = 1000,         -- load before blink.cmp so its fallback chains into this
        dependencies = { "nvim-treesitter/nvim-treesitter", "L3MON4D3/LuaSnip" },
        opts = {
            tabkey = "",
            backwards_tabkey = "",
            act_as_tab = true,
            act_as_shift_tab = false,
            enable_backwards = true,
            completion = false, -- you don't use Tab for the completion menu, so let this stay out of that decision
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
    },
}
