return {
    {
        'numToStr/Comment.nvim',
        keys = {
            { "gcc",        mode = "n", desc = "Comment Line" },
            { "gbc",        mode = "n", desc = "Block Comment Line" },
            { "gc",         mode = "v", desc = "Comment Selection" },
            { "gb",         mode = "v", desc = "Block Comment Selection" },
            { "<leader>cc", mode = "n", desc = "Comment Line" },
            { "<leader>cb", mode = "n", desc = "Block Comment Line" },
            { "<leader>cc", mode = "v", desc = "Comment Selection" },
            { "<leader>cb", mode = "v", desc = "Block Comment Selection" },
        },
        config = function()
            require('Comment').setup()

            local ft = require('Comment.ft')
            ft.c = { '//%s', '/* ---%s--- */' }
            ft.cpp = ft.c

            local api = require('Comment.api')

            -- Leader equivalents of the g-prefixed defaults
            vim.keymap.set("n", "<leader>cc", api.toggle.linewise.current,
                { desc = "Comment Line" })
            vim.keymap.set("n", "<leader>cb", api.toggle.blockwise.current,
                { desc = "Block Comment Line" })

            -- Visual: toggle over the selection, then leave visual mode cleanly
            local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
            vim.keymap.set("x", "<leader>cc", function()
                vim.api.nvim_feedkeys(esc, "nx", false)
                api.toggle.linewise(vim.fn.visualmode())
            end, { desc = "Comment Selection" })
            vim.keymap.set("x", "<leader>cb", function()
                vim.api.nvim_feedkeys(esc, "nx", false)
                api.toggle.blockwise(vim.fn.visualmode())
            end, { desc = "Block Comment Selection" })
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
                        keywords = "TODO,FIXME,TEST,REVIEW",
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
            require("todo-comments").setup({
                keywords = {
                    MARK = { icon = "", color = "info", alt = { "REMINDER", "OPTION" } },
                },
            })
        end,
    },
    {
        "danymat/neogen",
        dependencies = "nvim-treesitter/nvim-treesitter",
        keys = {
            {
                "<leader>cd",
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
