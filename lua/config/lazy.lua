-- Bootstrap lazy.nvim
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
        { import = "plugins.harpoon" },
        { import = "plugins.lualine" },
        { import = "plugins.markdown" },
        { import = "plugins.lsp-config" },
        { import = "plugins.noice" },
        { import = "plugins.telescope" },
        -- { import = "plugins.toggle-term" },
        { import = "plugins.treesitter" },
        { import = "plugins.undotree" },
        { import = "plugins.which-key" },
        { import = "plugins.comment" },
        { import = "plugins.oil" },
    },

    -- Lazy.nvim options
    checker = {
        enabled = false,
        notify = true,
    },
})

vim.cmd.colorscheme "aurora"

require("after.color-fix")
