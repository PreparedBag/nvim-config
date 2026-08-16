-- vim.keymap.set("n", "<leader>gb", function() Snacks.picker.git_branches() end, { desc = "Git Branches" })
-- vim.keymap.set("n", "<leader>gl", function() Snacks.picker.git_log() end, { desc = "Git Log" })
-- vim.keymap.set("n", "<leader>gL", function() Snacks.picker.git_log_line() end, { desc = "Git Log Line" })
-- vim.keymap.set("n", "<leader>gs", function() Snacks.picker.git_status() end, { desc = "Git Status" })
-- vim.keymap.set("n", "<leader>gS", function() Snacks.picker.git_stash() end, { desc = "Git Stash" })
-- vim.keymap.set("n", "<leader>gd", function() Snacks.picker.git_diff() end, { desc = "Git Diff (Hunks)" })
-- vim.keymap.set("n", "<leader>gf", function() Snacks.picker.git_log_file() end, { desc = "Git Log File" })
--
-- vim.keymap.set("n", "<leader>gi", function() Snacks.picker.gh_issue() end, { desc = "GitHub Issues (open)" })
-- vim.keymap.set("n", "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, { desc = "GitHub Issues (all)" })
-- vim.keymap.set("n", "<leader>gp", function() Snacks.picker.gh_pr() end, { desc = "GitHub Pull Requests (open)" })
-- vim.keymap.set("n", "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, { desc = "GitHub Pull Requests (all)" })
-- vim.keymap.set("n", "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Git Browse" })

return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        animate = { enabled = false },
        bigfile = { enabled = true },
        bufdelete = { enabled = false },
        dashboard = {
            width = 60,
            bo = {
                buftype = "readonly",
            },
            preset = {
                keys = {
                    -- { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                    -- { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                    -- { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                    -- { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                    { icon = " ", key = "s", desc = "Session Picker", action = function() Session_Picker() end, },
                    { icon = " ", key = "r", desc = "Restore Last Session", section = "session" },
                    { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                    { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                },
                -- Used by the `header` section
                header = [[
    ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
    ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
    ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
    ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
    ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
    ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
    ]],
            },
            sections = {
                { section = "header" },
                { section = "keys",   gap = 1, padding = 1 },
                { section = "startup" },
            },
        },
        debug = { enabled = false },
        dim = { enabled = false },
        explorer = { enabled = false },
        gh = { enabled = false },
        git = { enabled = false },
        gitbrowse = { enabled = false },
        image = { enabled = false },
        indent = { enabled = false },
        input = {
            enabled = false,
            win = {
                keys = {
                    i_ctrl_k = { "<c-k>", { "hist_up" }, mode = { "i", "n" } },
                    i_ctrl_j = { "<c-j>", { "hist_down" }, mode = { "i", "n" } },
                },
            },
        },
        keymap = { enabled = false },
        layout = {
            enabled = false,
            layout = {
                width = 0.8,
                height = 0.8,
                zindex = 100,
            },
        },
        lazygit = { enabled = false },
        notifier = {
            enabled = true,
            top_down = false,
            sort = { "added" }
        },
        notify = {
            enabled = true,
        },
        picker = {
            enabled = false,
            ui_select = true,
            win = {
                keys = {
                    i_ctrl_u = { "<c-u>", { "preview_scroll_up" }, mode = { "i", "n" } },
                    i_ctrl_d = { "<c-d>", { "preview_scroll_down" }, mode = { "i", "n" } },
                },
            },
            sources = {
                select = {
                    focus = "list",
                },
            },
        },
        profiler = { enabled = false },
        quickfile = { enabled = false },
        rename = { enabled = false },
        scope = { enabled = false },
        scratch = { enabled = false },
        scroll = { enabled = false },
        statuscolumn = { enabled = false },
        terminal = { enabled = false },
        toggle = {
            enabled = true,
        },
        win = { enabled = true },
        words = { enabled = false },
        zen = { enabled = false },
    },
}
