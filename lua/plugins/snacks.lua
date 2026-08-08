return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        animate = { enabled = false },
        bigfile = { enabled = true },
        bufdelete = { enabled = false },
        dashboard = { enabled = true },
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
