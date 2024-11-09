return {
    "folke/noice.nvim",
    config = function()
        require("noice").setup({
            presets = {
                bottom_search = false,
                command_palette = true,
                long_message_to_split = true,
                inc_rename = false,
            },
        })
    end
}
