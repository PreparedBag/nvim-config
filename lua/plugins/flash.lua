return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
    config = function()
        require('flash').setup({
            -- OPTION: configuration options for flash
            search = {
                multi_window = true,
            },
            jump = {
                autojump = false,
            },
            highlight = {
                backdrop = true,
            },
        })
    end
}
