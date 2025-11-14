return {
    'numToStr/Comment.nvim',
    keys = {
        { "gcc", mode = "n", desc = "Comment line" },
        { "gc",  mode = "v", desc = "Comment selection" },
    },
    config = function()
        require('Comment').setup()
    end,
}
