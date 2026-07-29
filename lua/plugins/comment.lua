return {
    {
        'numToStr/Comment.nvim',
        keys = {
            { "gcc", mode = "n", desc = "Comment Line" },
            { "gbc", mode = "n", desc = "Block Comment Line" },
            { "gc",  mode = "v", desc = "Comment Selection" },
            { "gb",  mode = "v", desc = "Block Comment Selection" },
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
                        keywords = "TODO,FIXME,HACK",
                        initial_mode = "normal",
                    })
                end,
                desc = "Pending Tasks",
            },
            {
                "<leader>fT",
                function()
                    require("telescope").extensions["todo-comments"].todo({
                        initial_mode = "normal",
                    })
                end,
                desc = "All Annotations",
            },
        },
        config = function()
            require("todo-comments").setup({})
        end,
    }
}
