return {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
        {
            "<leader>ps",
            function() require("persistence").load() end,
            desc = "Restore session (cwd)",
        },
        {
            "<leader>pl",
            function() require("persistence").load({ last = true }) end,
            desc = "Restore last session",
        },
        {
            "<leader>pd",
            function() require("persistence").stop() end,
            desc = "Don't save session",
        },
    },
}
