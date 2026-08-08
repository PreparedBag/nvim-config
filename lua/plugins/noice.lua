return {
    "folke/noice.nvim",
    config = function()
        require("noice").setup({
            routes = {
                {
                    filter = {
                        event = "lsp",
                        kind = "progress",
                        find = "lua_ls",
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = "notify",
                        find = "position_encoding param is required",
                    },
                    opts = { skip = true },
                },
                {
                    filter = { event = "notify" },
                    view = "notify",
                },
            },
            presets = {
                bottom_search = false,
                command_palette = true,
                long_message_to_split = false,
                inc_rename = false,
                lsp_doc_border = true,
            },
            messages = {
                view_history = "popup",
            },
            commands = {
                history = {
                    view = "popup",
                },
                all = {
                    view = "popup",
                },
            },
        })
        local theme = require("after.theme-utils")

        theme.on_colorscheme(function()
            vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", {
                fg = theme.theme_fg("Title"),
                bold = true,
                italic = true,
            })
            vim.api.nvim_set_hl(0, "NoiceCmdlineIcon", { link = "Normal" })
        end)
    end,
}
