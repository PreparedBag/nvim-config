return {
    {
        'numToStr/Comment.nvim',
        enabled = require("config.flags").get("LSP_ENABLED"),
        keys = {
            { "gcc", mode = "n", desc = "Comment Line" },
            { "gbc", mode = "n", desc = "Block Comment Line" },
            { "gc",  mode = "v", desc = "Comment Selection" },
            { "gb",  mode = "v", desc = "Block Comment Selection" },
        },
        config = function()
            require('Comment').setup()

            local ft = require('Comment.ft')
            ft.c = { '//%s', '/* ---%s--- */' }
            ft.cpp = ft.c
        end
    },
    {
        "folke/todo-comments.nvim",
        enabled = require("config.flags").get("LSP_ENABLED"),
        dependencies = { "nvim-lua/plenary.nvim" },
        event = { "BufReadPost", "BufNewFile" },
        keys = {
            {
                "<leader>ft",
                function()
                    require("telescope").extensions["todo-comments"].todo({
                        keywords = "TODO,FIXME,TEST,REVIEW,BUG,HACK",
                        -- OPTION: start in normal or insert mode
                        initial_mode = "normal",
                    })
                end,
                desc = "Pending Tasks",
            },
            {
                "<leader>fi",
                function()
                    require("telescope").extensions["todo-comments"].todo({
                        -- OPTION: start in normal or insert mode
                        initial_mode = "normal",
                    })
                end,
                desc = "All Annotations",
            },
        },
        config = function()
            require("todo-comments").setup({
                keywords = {
                    OPTION = { icon = " ", color = "info", alt = { "REMINDER", "MARK" } },
                    REVIEW = { icon = "", color = "info" },
                },
            })
        end,
    },
}
