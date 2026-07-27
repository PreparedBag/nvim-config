return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
        local wk = require("which-key")

        wk.setup({
            icons = {
                mappings = false,
            },
        })

        wk.add({
            -- LSP Navigation
            { "gd",          desc = "Go to Definition",              mode = "n" },
            { "gD",          desc = "Go to Declaration",             mode = "n" },
            { "gi",          desc = "Go to Implementation",          mode = "n" },
            { "gt",          desc = "Go to Type Definition",         mode = "n" },
            { "K",           desc = "Hover Documentation",           mode = "n" },
            { "<C-h>",       desc = "Signature Help",                mode = { "n", "i" } },

            -- Quickfix
            { "<leader>j",   desc = "Next Quickfix Item",            mode = "n" },
            { "<leader>k",   desc = "Previous Quickfix Item",        mode = "n" },

            -- Fold
            { "<leader>z",   group = "Fold",                         mode = "n" },
            { "<leader>zt",  desc = "Toggle Enable",                 mode = "n" },
            { "<leader>ze",  desc = "Expand All",                    mode = "n" },
            { "<leader>zc",  desc = "Collapse All",                  mode = "n" },

            -- LSP
            { "<leader>l",   group = "LSP",                          mode = "n" },
            { "<leader>la",  desc = "Code Actions",                  mode = "n" },
            { "<leader>ln",  desc = "Refactor Symbol",               mode = "n" },
            { "<leader>lf",  desc = "Format Document",               mode = "n" },
            { "<leader>ld",  desc = "Show Diagnostics",              mode = "n" },
            { "<leader>lk",  desc = "Prev Diagnostic",               mode = "n" },
            { "<leader>lj",  desc = "Next Diagnostic",               mode = "n" },
            { "<leader>lr",  desc = "Show References",               mode = "n" },
            { "<leader>lw",  desc = "Workspace Symbols",             mode = "n" },
            { "<leader>lo",  desc = "Document Outline/Symbols",      mode = "n" },
            { "<leader>ls",  desc = "Start LSP Server",              mode = "n" },
            { "<leader>lc",  desc = "Stop LSP Server",               mode = "n" },

            -- Find (Telescope)
            { "<leader>f",   group = "Find",                         mode = { "n", "v" } },
            { "<leader>ff",  desc = "Find Files (Fuzzy Finder)",     mode = "n" },
            { "<leader>fa",  desc = "Find All Files (Include All)",  mode = "n" },
            { "<leader>fp",  desc = "Find Phrase (Live Grep)",       mode = "n" },
            { "<leader>fs",  desc = "Find String (Include All)",     mode = "n" },
            { "<leader>fb",  desc = "Find Buffers",                  mode = "n" },
            { "<leader>fd",  desc = "Set Telescope CWD Here",        mode = "n" },
            { "<leader>fo",  desc = "Set Telescope CWD to Original", mode = "n" },
            { "<leader>fw",  desc = "Find Word (Ripgrep)",           mode = { "n", "v" } },
            { "<leader>fe",  desc = "File Explorer",                 mode = "n" },
            { "<leader>fq",  desc = "View Quickfix List",            mode = "n" },
            { "<leader>fh",  desc = "View Quickfix History",         mode = "n" },
            { "<leader>fH",  desc = "Find Help Tags",                mode = "n" },

            -- Debugger
            { "<leader>d",   group = "Debugger" },
            { "<leader>dt",  group = "Target Actions",               mode = "n" },
            { "<leader>dg",  group = "Go To Actions",                mode = "n" },

            -- Splits
            { "<leader>s",   group = "Split",                        mode = "n" },
            { "<leader>sh",  desc = "Horizontal Split",              mode = "n" },
            { "<leader>sv",  desc = "Vertical Split",                mode = "n" },

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
            { "<leader>it",  desc = "Insert Table Template",         mode = "n" },
            { "<leader>ii1", desc = "Insert 1 Image",                mode = "n" },
            { "<leader>ii2", desc = "Insert 2 Images",               mode = "n" },
            { "<leader>ig",  desc = "Insert Gantt Chart Template",   mode = "n" },
            { "<leader>if",  desc = "Insert Flowchart Template",     mode = "n" },

            -- Table Mode
            -- { "<leader>t",   group = "Table",                        mode = "n" },

            -- Git Integration
            { "<leader>g",   group = "Git",                          mode = { "n", "v" } },
            { "<leader>gh",  group = "Hunks",                        mode = { "n", "v" } },

            -- Harpoon
            { "<leader>h",   group = "Harpoon",                      mode = "n" },
            { "<leader>1",   hidden = true },
            { "<leader>2",   hidden = true },
            { "<leader>3",   hidden = true },
            { "<leader>4",   hidden = true },
            { "<leader>5",   hidden = true },
            { "<leader>6",   hidden = true },
            { "<leader>7",   hidden = true },
            { "<leader>8",   hidden = true },

            -- Markdown & HTML
            { "<leader>m",   group = "Markdown & HTML",              mode = "n" },
            { "<leader>mh",  desc = "Start HTML Server",             mode = "n" },
            { "<leader>mp",  desc = "Toggle Markdown Preview",       mode = "n" },

            -- Clipboard and Paste
            { "<leader>p",   desc = "Paste without Yank",            mode = "x" },
            { "<leader>y",   desc = "Yank to Clipboard",             mode = { "n", "v" } },
            { "<leader>Y",   desc = "Yank line to Clipboard",        mode = "n" },

            -- Terminal
            -- { "<leader>,",   desc = "Toggle Terminal",               mode = "n" },

            -- Undotree Toggle
            { "<leader>u",   desc = "Toggle Undotree",               mode = "n" },

            -- NERDTree Commands
            -- { "<leader>N",   desc = "Toggle NERDTree Focus",         mode = "n" },
            -- { "<leader>n",   desc = "Toggle NERDTree",               mode = "n" },

            -- Quit
            { "<leader>q",   desc = "Quit Without Saving",           mode = "n" },

            -- Buffers
            { "<leader>b",   group = "Buffers",                      mode = "n" },
            { "<leader>bb",  desc = "Show Buffers",                  mode = "n" },
            { "<leader>bd",  desc = "Delete Current Buffer",         mode = "n" },
            { "<leader>bt",  desc = "Toggle Binary View",            mode = "n" },

            -- Oil
            { "<leader>o",   group = "Oil",                          mode = "n" },
        })
    end
}
