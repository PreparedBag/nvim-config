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
                end, "Next hunk")

                map("n", "<leader>gk", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ "[c", bang = true })
                    else
                        gs.nav_hunk("prev")
                    end
                end, "Prev hunk")

                -- Stage hunk (normal + visual range)
                map("n", "<leader>ghs", gs.stage_hunk, "Stage hunk")
                map("v", "<leader>ghs", function()
                    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Stage selected hunk")

                -- Discard/reset hunk (normal + visual range)
                map("n", "<leader>ghr", gs.reset_hunk, "Discard hunk")
                map("v", "<leader>ghr", function()
                    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Discard selected hunk")

                -- Undo the last stage
                map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo stage hunk")

                -- Preview hunk under cursor
                map("n", "<leader>ghp", gs.preview_hunk, "Preview hunk")

                -- Whole-buffer stage / reset
                map("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
                map("n", "<leader>ghR", gs.reset_buffer, "Reset buffer")

                -- Blame current line
                map("n", "<leader>ghb", function()
                    gs.blame_line({ full = true })
                end, "Blame line")

                -- All project hunks into the quickfix list
                map("n", "<leader>gq", function()
                    gs.setqflist("all", { open = false })
                end, "All hunks to quickfix")
            end,
        })
    end,
}
