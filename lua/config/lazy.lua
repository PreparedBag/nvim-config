-- Store the session directory when Neovim starts
_G.session_directory = vim.fn.getcwd()

-- Dev mode marker: default minimal (no marker), marker file with "true" enables dev
local marker = vim.fn.stdpath("data") .. "/nvim-dev"

_G.DEV_ENABLED = false
if vim.fn.filereadable(marker) == 1 then
    local lines = vim.fn.readfile(marker)
    local content = vim.trim(lines[1] or "")
    _G.DEV_ENABLED = (content == "true")
end

-- DEBUG: Uncomment to debug what the marker resolves to:
-- vim.notify("DEV_ENABLED = " .. tostring(_G.DEV_ENABLED) .. " (marker: " .. marker .. ")")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Include plugins from the lua/plugins/ folder
    spec = {
        { import = "plugins.blink" },
        { import = "plugins.bracey" },
        { import = "plugins.colorschemes" },
        { import = "plugins.comment" },
        { import = "plugins.debugger" },
        { import = "plugins.gitsigns" },
        { import = "plugins.flash" },
        { import = "plugins.fmt-utils" },
        { import = "plugins.git" },
        { import = "plugins.harpoon" },
        { import = "plugins.lualine" },
        { import = "plugins.lsp-config" },
        { import = "plugins.markdown" },
        { import = "plugins.nerdtree" },
        { import = "plugins.noice" },
        { import = "plugins.nvim-colorizer" },
        { import = "plugins.oil" },
        { import = "plugins.persistence" },
        { import = "plugins.snacks" },
        { import = "plugins.snippets" },
        { import = "plugins.surround" },
        { import = "plugins.tabout" },
        { import = "plugins.telescope" },
        { import = "plugins.toggle-term" },
        { import = "plugins.treesitter" },
        { import = "plugins.undotree" },
        { import = "plugins.which-key" },
        -- OPTION: uncomment for yazi integration
        -- { import = "plugins.yazi" },
    },

    -- Lazy.nvim options
    checker = {
        enabled = true,
        notify = false,
    },
})

-- vim.cmd.colorscheme "aurora"
vim.cmd.colorscheme "catppuccin-frappe"

require("after.theme-utils")
require("after.autocmds")
