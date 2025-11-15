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
            { "gd",          desc = "Go to Definition",                       mode = "n" },
            { "gD",          desc = "Go to Declaration",                      mode = "n" },
            { "gi",          desc = "Go to Implementation",                   mode = "n" },
            { "gt",          desc = "Go to Type Definition",                  mode = "n" },
            { "K",           desc = "Hover Documentation",                    mode = "n" },
            { "<C-h>",       desc = "Signature Help",                         mode = { "n", "i" } },

            -- Diagnostics Navigation
            { "<leader>j",   desc = "Previous Diagnostic",                    mode = "n" },
            { "<leader>k",   desc = "Next Diagnostic",                        mode = "n" },

            -- LSP Group
            { "<leader>l",   group = "LSP" },

            -- LSP Actions
            { "<leader>la",  desc = "Code Actions",                           mode = { "n", "v" } },
            { "<leader>ln",  desc = "Rename Symbol",                          mode = "n" },
            { "<leader>lf",  desc = "Format Document",                        mode = "n" },
            { "<leader>ld",  desc = "Show Diagnostics",                       mode = "n" },

            -- LSP References and Search
            { "<leader>lr",  desc = "Show References",                        mode = "n" },
            { "<leader>lR",  desc = "Ripgrep Search (Bypass LSP)",            mode = "n" },

            -- LSP Symbols
            { "<leader>lw",  desc = "Workspace Symbols",                      mode = "n" },
            { "<leader>lo",  desc = "Document Outline/Symbols",               mode = "n" },

            -- LSP Server Control
            { "<leader>ls",  desc = "Start LSP Server",                       mode = "n" },
            { "<leader>lc",  desc = "Stop LSP Server",                        mode = "n" },

            -- LSP Generate Group
            { "<leader>lg",  group = "Generate compile_commands.json" },
            { "<leader>lgc", desc = "Generate CMake compile_commands.json",   mode = "n" },
            { "<leader>lga", desc = "Generate compile_commands.json (Auto)",  mode = "n" },
            { "<leader>lgz", desc = "Generate Zephyr compile_commands.json",  mode = "n" },
            { "<leader>lgw", desc = "Generate West compile_commands.json",    mode = "n" },
            { "<leader>lgg", desc = "Generate Generic compile_commands.json", mode = "n" },

            -- Find (Telescope)
            { "<leader>f",   group = "Find" },
            { "<leader>ff",  desc = "Find Files (Fuzzy Finder)",              mode = "n" },
            { "<leader>fa",  desc = "Find Files (Include Hidden)",            mode = "n" },
            { "<leader>fp",  desc = "Find Phrase (Live Grep)",                mode = "n" },
            { "<leader>fs",  desc = "File Scroll",                            mode = "n" },
            { "<leader>fh",  desc = "Find Help Tags",                         mode = "n" },
            { "<leader>fb",  desc = "Find Buffers",                           mode = "n" },
            { "<leader>fd",  desc = "Set Telescope CWD Here",                 mode = "n" },
            { "<leader>fo",  desc = "Set Telescope CWD to Original",          mode = "n" },
            { "<leader>fe",  desc = "File Explorer",                          mode = "n" },

            -- Splits
            { "<leader>s",   group = "Split",                                 mode = "n" },
            { "<leader>sh",  desc = "Horizontal Split",                       mode = "n" },
            { "<leader>sv",  desc = "Vertical Split",                         mode = "n" },

            -- Search and Replace
            { "<leader>r",   group = "Refactor",                              mode = "n" },
            { "<leader>rw",  desc = "Refactor Word",                          mode = "n" },

            -- File Permissions
            { "<leader>x",   desc = "Make File Executable",                   mode = "n" },

            -- Window Navigation
            { "<leader>w",   group = "Window Navigation",                     mode = "n" },
            { "<leader>ww",  desc = "Switch Window",                          mode = "n" },
            { "<leader>wh",  desc = "Move to Left Window",                    mode = "n" },
            { "<leader>wl",  desc = "Move to Right Window",                   mode = "n" },
            { "<leader>wj",  desc = "Move to Below Window",                   mode = "n" },
            { "<leader>wk",  desc = "Move to Above Window",                   mode = "n" },

            -- Insert
            { "<leader>i",   group = "Insert",                                mode = "n" },
            { "<leader>ii",  group = "Image",                                 mode = "n" },
            { "<leader>it",  desc = "Insert Table Template",                  mode = "n" },
            { "<leader>ii1", desc = "Insert 1 Image",                         mode = "n" },
            { "<leader>ii2", desc = "Insert 2 Images",                        mode = "n" },
            { "<leader>ig",  desc = "Insert Gantt Chart Template",            mode = "n" },
            { "<leader>if",  desc = "Insert Flowchart Template",              mode = "n" },

            -- Table Mode
            { "<leader>t",   group = "Table",                                 mode = "n" },

            -- Harpoon
            { "<leader>e",   desc = "Harpoon Quick Menu",                     mode = "n" },
            { "<leader>a",   desc = "Add to Harpoon",                         mode = "n" },
            { "<leader>1",   hidden = true },
            { "<leader>2",   hidden = true },
            { "<leader>3",   hidden = true },
            { "<leader>4",   hidden = true },
            { "<leader>5",   hidden = true },
            { "<leader>6",   hidden = true },
            { "<leader>7",   hidden = true },
            { "<leader>8",   hidden = true },

            -- Markdown & HTML
            { "<leader>m",   group = "Markdown & HTML",                       mode = "n" },
            { "<leader>mh",  desc = "Start HTML Server",                      mode = "n" },
            { "<leader>mp",  desc = "Toggle Markdown Preview",                mode = "n" },

            -- Clipboard and Paste
            { "<leader>p",   desc = "Paste from Clipboard",                   mode = { "n", "v" } },
            { "<leader>v",   desc = "Paste without Yank",                     mode = "x" },
            { "<leader>y",   desc = "Yank to Clipboard",                      mode = { "n", "v" } },
            { "<leader>d",   desc = "Delete without Yank",                    mode = { "n", "v" } },

            -- Terminal
            { "<leader>,",   desc = "Toggle Terminal",                        mode = "n" },

            -- Undotree Toggle
            { "<leader>u",   desc = "Toggle Undotree",                        mode = "n" },

            -- NERDTree Commands
            { "<leader>N",   desc = "Toggle NERDTree Focus",                  mode = "n" },
            { "<leader>n",   desc = "Toggle NERDTree",                        mode = "n" },

            -- Quit
            { "<leader>q",   desc = "Quit Without Saving",                    mode = "n" },

            -- Buffers
            { "<leader>b",   group = "Buffers",                               mode = "n" },
            { "<leader>bb",  desc = "Show Buffers",                           mode = "n" },
            { "<leader>bd",  desc = "Delete Current Buffer",                  mode = "n" },
            { "<leader>bt",  desc = "Toggle Binary View",                     mode = "n" },

            -- Oil
            { "<leader>h",   desc = "Toggle Hidden Files (in Oil)",           mode = "n" },
        })
    end
}
