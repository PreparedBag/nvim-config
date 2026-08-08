return {
    "brianhuster/live-preview.nvim",
    enabled = not _G.DEV_ENABLED,
    dependencies = { "folke/snacks.nvim" },
    ft = { "markdown" },
    cmd = { "LivePreview" },
    config = function()
        require("livepreview.config").set({
            port = 6969,
            sync_scroll = true,
        })
    end,
}
