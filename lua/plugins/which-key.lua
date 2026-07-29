return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    version = "*",
    config = function()
        local wk = require("which-key")

        wk.setup({
            delay = 200,
            icons = {
                mappings = false,
            },
        })

        wk.add({
            -- Buffers
            { "<leader>b",  group = "Buffers",           mode = "n" },

            -- Comment
            { "<leader>c",  group = "Comment",           mode = { "n", "v" } },

            -- Debugger
            { "<leader>d",  group = "Debugger" },
            { "<leader>dt", group = "Target Actions",    mode = "n" },

            -- Find (Telescope)
            { "<leader>f",  group = "Find",              mode = { "n", "v" } },

            -- Fold
            { "<leader>z",  group = "Fold",              mode = "n" },

            -- Git Integration
            { "<leader>g",  group = "Git",               mode = { "n", "v" } },
            { "<leader>gh", group = "Hunks",             mode = { "n", "v" } },
            { "<leader>gb", group = "Branch",            mode = "n" },
            { "<leader>gz", group = "Stash",             mode = "n" },

            -- Harpoon
            { "<leader>h",  group = "Harpoon",           mode = "n" },
            { "<leader>1",  hidden = true },
            { "<leader>2",  hidden = true },
            { "<leader>3",  hidden = true },
            { "<leader>4",  hidden = true },
            { "<leader>5",  hidden = true },
            { "<leader>6",  hidden = true },
            { "<leader>7",  hidden = true },
            { "<leader>8",  hidden = true },

            -- Insert
            { "<leader>i",  group = "Insert",            mode = "n" },
            { "<leader>ii", group = "Image",             mode = "n" },

            -- LSP
            { "<leader>l",  group = "LSP",               mode = "n" },

            -- Markdown & HTML
            { "<leader>m",  group = "Markdown & HTML",   mode = "n" },

            -- Oil
            { "<leader>o",  group = "Oil",               mode = "n" },

            -- Splits
            { "<leader>s",  group = "Split",             mode = "n" },

            -- Window Navigation
            { "<leader>w",  group = "Window Navigation", mode = "n" },

            -- NOTE: uncomment if needed
            -- Table Mode
            -- { "<leader>t",   group = "Table",                        mode = "n" },
            -- NERDTree Commands
            -- { "<leader>N",   desc = "Toggle NERDTree Focus",         mode = "n" },
            -- { "<leader>n",   desc = "Toggle NERDTree",               mode = "n" },

        })
    end
}
