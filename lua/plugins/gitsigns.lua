return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("gitsigns").setup({
            signs = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = "" },
                topdelete = { text = "" },
                changedelete = { text = "▎" },
                untracked = { text = "▎" },
            },
            signs_staged = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = "" },
                topdelete = { text = "" },
                changedelete = { text = "▎" },
            },
            signs_staged_enable = true,
            on_attach = function(bufnr)
                local gs = require("gitsigns")

                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, {
                        buffer = bufnr,
                        noremap = true,
                        silent = true,
                        desc = desc,
                    })
                end

                -- Hunk navigation
                map("n", "<leader>gj", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "]c", bang = true })
                    else
                        gs.nav_hunk("next")
                    end
                end, "Next Hunk")

                map("n", "<leader>gk", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gs.nav_hunk("prev")
                    end
                end, "Prev Hunk")

                -- Stage hunk (normal + visual range)
                map("n", "<leader>ghs", gs.stage_hunk, "Stage Hunk")
                map("v", "<leader>ghs", function()
                    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Stage Selected Hunk")

                -- Discard/reset hunk (normal + visual range)
                map("n", "<leader>ghr", gs.reset_hunk, "Discard Hunk")
                map("v", "<leader>ghr", function()
                    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Discard Selected Hunk")

                -- Undo the last stage
                map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")

                -- Preview hunk under cursor
                map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")

                -- Whole-buffer stage / reset
                map("n", "<leader>gS", gs.stage_buffer, "Stage Buffer")

                -- Blame current line
                map("n", "<leader>ge", function()
                    gs.blame_line({ full = true })
                end, "Blame Line")

                -- All project hunks into the quickfix list
                map("n", "<leader>gq", function()
                    gs.setqflist("all", { open = false }, function()
                        vim.fn.setqflist({}, "a", { title = "Git Hunks (All)" })
                    end)
                end, "All Hunks to Quickfix")
            end,
        })
    end,
}
