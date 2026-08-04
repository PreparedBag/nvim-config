return {
    {
        "Wansmer/treesj",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        keys = {
            { "<leader>J", "<cmd>TSJToggle<cr>", desc = "Toggle Split/Join (Treesitter)" },
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
        opts = {
            check_ts = true, -- treesitter-aware: skip pairing inside strings/comments
            fast_wrap = {},  -- <M-e> fast-wraps the next node in a pair
        },
    },
}
