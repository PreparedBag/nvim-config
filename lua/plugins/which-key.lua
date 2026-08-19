return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    version = "*",
    config = function()
        local wk = require("which-key")
        wk.setup({
            delay = 300,
            icons = { mappings = false, },
            win = {
                border = "rounded",
                no_overlap = false,
                wo = { winblend = 0 },
            },
            triggers = {
                { "<leader>", mode = { "n", "v" } },
                { "g",        mode = "n" },
                { "z",        mode = "n" },
                { "m",        mode = "n" },
                -- { "y",        mode = "n" },
                -- { "d",        mode = "n" },
                -- { "c",        mode = "n" },
            },
        })

        local mappings = {
            -- Buffers
            { "<leader>b",   group = "Buffers",           mode = "n" },

            -- Commands
            { "<leader>c",   group = "Custom Commands",   mode = "n" },

            -- Find (Telescope)
            { "<leader>f",   group = "Find",              mode = { "n", "v" } },

            -- Fold
            { "<leader>z",   group = "Fold",              mode = "n" },

            -- Git Integration
            { "<leader>g",   group = "Git",               mode = "n" },
            { "<leader>gh",  group = "Hunks",             mode = "n" },
            -- { "<leader>gb",  group = "Branch",            mode = "n" },
            -- { "<leader>gF",  group = "Fetch File",        mode = "n" },
            -- { "<leader>gz",  group = "Stash",             mode = "n" },

            -- Harpoon
            { "<leader>h",   group = "Harpoon",           mode = "n" },
            { "<leader>1",   hidden = true },
            { "<leader>2",   hidden = true },
            { "<leader>3",   hidden = true },
            { "<leader>4",   hidden = true },
            { "<leader>5",   hidden = true },
            { "<leader>6",   hidden = true },
            { "<leader>7",   hidden = true },
            { "<leader>8",   hidden = true },

            -- Information
            { "<leader>i",   group = "Information",       mode = "n" },

            -- Insert
            { "<leader>mi",  group = "Insert",            mode = "n" },
            { "<leader>mii", group = "Image",             mode = "n" },

            -- Miscellaneous
            { "<leader>m",   group = "Miscellaneous",     mode = "n" },

            -- Numbase
            { "<leader>n",   group = "Numbase",           mode = "n" },

            -- Oil
            { "<leader>o",   group = "Oil",               mode = "n" },

            -- Persistence
            { "<leader>p",   group = "Project",           mode = "n" },

            -- Splits
            { "<leader>s",   group = "Split",             mode = "n" },

            -- Terminal/Nerdtree
            { "<leader>t",   group = "Terminal/Nerdtree", mode = "n" },

            -- Window Navigation
            { "<leader>w",   group = "Window Navigation", mode = "n" },
        }

        -- Dev-only groups (LSP, debugger, markdown/html) — only shown when the
        -- heavy plugins are actually loaded, so no dead keymaps appear.
        if require("config.flags").get("DAP_ENABLED") then
            vim.list_extend(mappings, {
                { "<leader>d",  group = "DAP",            mode = { "n", "v" } },
                { "<leader>dt", group = "Target Actions", mode = "n" },
            })
        end
        if require("config.flags").get("LSP_ENABLED") then
            vim.list_extend(mappings, {
                { "<leader>l", group = "LSP", mode = "n" },
            })
        end
        -- if require("config.flags").get("HTML_VIEWER") then
        --     vim.list_extend(mappings, {
        --         { "<leader>m", group = "Markdown & HTML", mode = "n" },
        --     })
        -- end

        wk.add(mappings)
    end
}
