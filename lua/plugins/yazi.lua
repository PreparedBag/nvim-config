return {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
        { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
        {
            "<leader>fe",
            mode = { "n", "v" },
            "<cmd>Yazi<cr>",
            desc = "Open yazi at the current file",
        },
        {
            "<leader>fE",
            "<cmd>Yazi cwd<cr>",
            desc = "Open yazi in nvim's working directory",
        },
    },
    opts = {
        -- replaces netrw, same role oil currently has
        open_for_directories = true,
        open_multiple_tabs = false,

        -- Off by default, matching how you've wanted dap/session teardown
        -- to work elsewhere in this config: explicit over automatic. Use
        -- <C-\> *inside* yazi to sync cwd deliberately, rather than having
        -- every close silently change it. Flip to true if you'd rather it
        -- just follow you automatically instead.
        change_neovim_cwd_on_close = false,

        yazi_floating_window_border = "rounded",
        keymaps = {
            show_help = "<f1>",
        },
    },
    init = function()
        -- mark netrw as loaded so it's never loaded at all
        vim.g.loaded_netrwPlugin = 1
    end,
}
