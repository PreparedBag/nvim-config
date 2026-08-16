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
        { import = "plugins.colorschemes" },
        { import = "plugins.ccc" },
        { import = "plugins.comment" },
        { import = "plugins.dap" },
        { import = "plugins.gitsigns" },
        { import = "plugins.flash" },
        { import = "plugins.git" },
        { import = "plugins.harpoon" },
        { import = "plugins.lualine" },
        { import = "plugins.live-preview" },
        { import = "plugins.lsp-config" },
        { import = "plugins.markdown-preview" },
        { import = "plugins.nerdtree" },
        { import = "plugins.noice" },
        { import = "plugins.nvim-colorizer" },
        { import = "plugins.oil" },
        { import = "plugins.persistence" },
        { import = "plugins.snacks" },
        { import = "plugins.surround" },
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
require("after.markdown-utils")
require("after.numbase").setup()
require("config.project").setup()
require("after.web-preview")
require("after.binary-view")
