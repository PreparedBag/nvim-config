return {
    "neoclide/coc.nvim",
    enabled = require("config.flags").get("DEV_ENABLED"),
    branch = "release",
    build = "npm ci",
}
