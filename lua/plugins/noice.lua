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
            },
            views = {
                cmdline = {
                    enabled = false,
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
