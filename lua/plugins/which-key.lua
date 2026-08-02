return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    version = "*",
    config = function()
        local wk = require("which-key")
        wk.setup({
            delay = 200,
            icons = { mappings = false, },
            win = {
                -- border = "rounded",
                no_overlap = false,
                wo = { winblend = 0 },
            },
        })

        local mappings = {
            -- Buffers
            { "<leader>b",  group = "Buffers",           mode = "n" },

            -- Comment
            { "<leader>c",  group = "Comment",           mode = { "n", "v" } },

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

            -- Number
            { "<leader>n",  group = "Number",            mode = "n" },

            -- Oil
            { "<leader>o",  group = "Oil",               mode = "n" },

            -- Persistence
            { "<leader>p",  group = "Project",           mode = "n" },

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
        }

        -- Dev-only groups (LSP, debugger, markdown/html) — only shown when the
        -- heavy plugins are actually loaded, so no dead keymaps appear.
        if _G.DEV_ENABLED then
            vim.list_extend(mappings, {
                -- Debugger
                { "<leader>d",  group = "Debugger",        mode = { "n", "v" } },
                { "<leader>dt", group = "Target Actions",  mode = "n" },

                -- LSP
                { "<leader>l",  group = "LSP",             mode = "n" },

                -- Markdown & HTML
                { "<leader>m",  group = "Markdown & HTML", mode = "n" },
            })
        end

        wk.add(mappings)
    end
}
