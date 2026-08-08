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
            preset = {
                keys = {
                    { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                    { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                    { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
                    { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
                    { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
                    { icon = " ", key = "s", desc = "Restore Session", section = "session" },
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
    ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
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
        git = { enabled = true },
        gitbrowse = { enabled = false },
        image = { enabled = false },
        indent = { enabled = false },
        input = {
            enabled = true,
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
