return {
    "folke/which-key.nvim",
    config = function()
        local wk = require("which-key")

        wk.setup({
            icons = {
                mappings = false,
            },
        })

        wk.add({
            -- LSP
            { "<leader>k",   desc = "Next Location",                 mode = "n" },
            { "<leader>j",   desc = "Previous Location",             mode = "n" },
            { "<leader>l",   group = "LSP"},
            { "<leader>lr",   desc = "Show References",              mode = "n" },
            { "<leader>lt",   desc = "Toggle Autocompletion",        mode = "n" },
            { "<leader>la",   desc = "Code Actions",                 mode = "n" },
            { "<leader>ld",   desc = "Code Diagnostics",             mode = "n" },
            { "<leader>ls",   desc = "Start LSP Server",             mode = "n" },
            { "<leader>lc",   desc = "Stop LSP Server",              mode = "n" },

            -- Find (Telescope)
            { "<leader>f",   group = "Find" },
            { "<leader>ff",  desc = "Find Files (Fuzzy Finder)",     mode = "n" },
            { "<leader>fa",  desc = "Find Files (Include Hidden)",   mode = "n" },
            { "<leader>fp",  desc = "Find Phrase (Live Grep)",       mode = "n" },
            { "<leader>fs",  desc = "File Scroll",                   mode = "n" },
            { "<leader>fh",  desc = "Find Help Tags",                mode = "n" },
            { "<leader>fb",  desc = "Find Buffers",                  mode = "n" },
            { "<leader>fd",  desc = "Set Telescope CWD Here",        mode = "n" },
            { "<leader>fo",  desc = "Set Telescope CWD to Original", mode = "n" },
            { "<leader>fe",  desc = "File Explorer",                 mode = "n" },

            -- Splits
            { "<leader>s",   group = "Split",                        mode = "n" },
            { "<leader>sh",  desc = "Horizontal Split",              mode = "n" },
            { "<leader>sv",  desc = "Vertical Split",                mode = "n" },

            -- Search and Replace
            { "<leader>r",   group = "Refactor",                     mode = "n" },
            { "<leader>rw",  desc = "Refactor Word",                 mode = "n" },

            -- File Permissions
            { "<leader>x",   desc = "Make File Executable",          mode = "n" },

            -- Window Navigation
            { "<leader>w",   group = "Window Navigation",            mode = "n" },
            { "<leader>ww",  desc = "Switch Window",                 mode = "n" },
            { "<leader>wh",  desc = "Move to Left Window",           mode = "n" },
            { "<leader>wl",  desc = "Move to Right Window",          mode = "n" },
            { "<leader>wj",  desc = "Move to Below Window",          mode = "n" },
            { "<leader>wk",  desc = "Move to Above Window",          mode = "n" },

            -- Insert
            { "<leader>i",   group = "Insert",                       mode = "n" },
            { "<leader>ii",  group = "Image",                        mode = "n" },
            { "<leader>it",  group = "Insert Table Template",        mode = "n" },
            { "<leader>ii1", desc = "Insert 1 Image",                mode = "n" },
            { "<leader>ii2", desc = "Insert 2 Images",               mode = "n" },

            { "<leader>ig",  desc = "Insert Gantt Chart Template",   mode = "n" },
            { "<leader>if",  desc = "Insert Flowchart Template",     mode = "n" },

            -- Table Mode
            { "<leader>t",   group = "Table",                        mode = "n" },

            -- Harpoon
            { "<leader>e",   desc = "Harpoon Quick Menu",            mode = "n" },
            { "<leader>a",   desc = "Add to Harpoon",                mode = "n" },
            { "<leader>1",   hidden = true },
            { "<leader>2",   hidden = true },
            { "<leader>3",   hidden = true },
            { "<leader>4",   hidden = true },
            { "<leader>5",   hidden = true },

            -- Markdown Tools
            { "<leader>m",   group = "Markdown",                     mode = "n" },
            { "<leader>mp",  desc = "Markdown Live Preview Toggle",  mode = "n" },

            -- Clipboard and Paste
            { "<leader>v",   '"+P',                                  desc = "Paste from Clipboard", mode = { "n", "v" } },
            { "<leader>p",   desc = "Paste without Yank",            mode = "x" },
            { "<leader>y",   desc = "Yank to Clipboard",             mode = { "n", "v" } },
            { "<leader>d",   desc = "Delete without Yank",           mode = { "n", "v" } },

            -- Terminal
            -- { "<leader>,",   desc = "Toggle Terminal",               mode = "n" },

            -- Undotree Toggle
            { "<leader>u",   desc = "Toggle Undotree",               mode = "n" },

            -- Quit
            { "<leader>q",   desc = "Quit Without Saving",           mode = "n" },

            -- Buffers
            { "<leader>b",   group = "Buffers",                      mode = "n" },
            { "<leader>bb",  desc = "Show Buffers",                  mode = "n" },
            { "<leader>bd",  desc = "Delete Current Buffer",         mode = "n" },
            { "<leader>bt",  desc = "Toggle Binary View",            mode = "n" },
        })
    end
}
