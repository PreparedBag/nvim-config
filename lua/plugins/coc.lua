return {
    "neoclide/coc.nvim",
    enabled = require("config.flags").get("LSP_ENABLED"),
    branch = "release",
    build = "npm ci",
}
