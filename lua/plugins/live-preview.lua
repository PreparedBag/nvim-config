return {
    "brianhuster/live-preview.nvim",
    enabled = not require("config.flags").get("FULL_MARKDOWN"),
    dependencies = { "folke/snacks.nvim" },
    ft = { "markdown" },
    cmd = { "LivePreview" },
    keys = {
        {
            "<leader>mp",
            function()
                vim.g.livepreview_on = not vim.g.livepreview_on
                vim.cmd("LivePreview " .. (vim.g.livepreview_on and "start" or "close"))
            end,
            ft = "markdown",
            desc = "Toggle Markdown Preview",
        },
    },
    config = function()
        require("livepreview.config").set({
            port = 6969,
            sync_scroll = true,
        })
    end,
}
