return {
    {
        'numToStr/Comment.nvim',
        enabled = require("config.flags").get("LSP_ENABLED"),
        keys = {
            { "gcc",        mode = "n", desc = "Comment Line" },
            { "gbc",        mode = "n", desc = "Block Comment Line" },
            { "gc",         mode = "v", desc = "Comment Selection" },
            { "gb",         mode = "v", desc = "Block Comment Selection" },
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
                        keywords = "TODO,FIXME,TEST,REVIEW",
                        -- OPTION: start in normal or insert mode
                        -- initial_mode = "normal",
                    })
                end,
                desc = "Pending Tasks",
            },
            {
                "<leader>fT",
                function()
                    require("telescope").extensions["todo-comments"].todo({
                        -- OPTION: start in normal or insert mode
                        -- initial_mode = "normal",
                    })
                end,
                desc = "All Annotations",
            },
        },
        config = function()
            require("todo-comments").setup({
                keywords = {
                    MARK = { icon = "", color = "info", alt = { "REMINDER", "OPTION" } },
                },
            })
        end,
    },
    {
        "danymat/neogen",
        enabled = require("config.flags").get("LSP_ENABLED"),
        dependencies = "nvim-treesitter/nvim-treesitter",
        keys = {
            {
                "<leader>lg",
                function() require("neogen").generate() end,
                desc = "Generate Doc Comment",
            },
        },
        opts = {
            snippet_engine = "nvim",
            languages = {
                c          = { template = { annotation_convention = "doxygen" } },
                cpp        = { template = { annotation_convention = "doxygen" } },
                java       = { template = { annotation_convention = "javadoc" } },
                python     = { template = { annotation_convention = "google_docstrings" } },
                javascript = { template = { annotation_convention = "jsdoc" } },
                typescript = { template = { annotation_convention = "tsdoc" } },
                lua        = { template = { annotation_convention = "emmylua" } },
                rust       = { template = { annotation_convention = "rustdoc" } },
                go         = { template = { annotation_convention = "godoc" } },
            },
        },
    },
}
