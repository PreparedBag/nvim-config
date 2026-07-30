return {
    "folke/noice.nvim",
    dependencies = {
        "rcarriga/nvim-notify",
    },
    config = function()
        require("notify").setup({
            top_down = true,
            -- NOTE: update to preferred dialog style
            render = "default", -- fuller dialog style (vs "minimal" / "compact")
            stages = "static", -- animation; "fade"/"slide"/"static"
            timeout = 3000,
        })
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
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = true,
            },
        })
    end
}
