return {
    {
        'numToStr/Comment.nvim',
        keys = {
            { "gcc", mode = "n", desc = "Comment line" },
            { "gbc", mode = "n", desc = "Block comment line" },
            { "gc",  mode = "v", desc = "Comment selection" },
            { "gb",  mode = "v", desc = "Block comment selection" },
        },
        config = function()
            require('Comment').setup()
            local ft = require('Comment.ft')
            -- { line, block } ; padding adds the inner spaces
            ft.c = { '//%s', '/* ---%s--- */' }
            ft.cpp = ft.c -- covers .h if it's detected as cpp
        end
    },
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event = { "BufReadPost", "BufNewFile" },
        keys = {
            {
                "<leader>ft",
                function()
                    require("telescope").extensions["todo-comments"].todo({
                        keywords = "TODO,FIXME",
                        initial_mode = "normal",
                    })
                end,
                desc = "Find TODO",
            },
            {
                "<leader>fT",
                function()
                    require("telescope").extensions["todo-comments"].todo({
                        initial_mode = "normal",
                    })
                end,
                desc = "Find all TODO/FIXME/etc",
            },
        },
        config = function()
            require("todo-comments").setup({})
        end,
    }
}
