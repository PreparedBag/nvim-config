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
        -- { import = "plugins.claude" },
        { import = "plugins.colorschemes" },
        { import = "plugins.comment" },
        -- { import = "plugins.debugger" },
        { import = "plugins.harpoon" },
        { import = "plugins.lualine" },
        { import = "plugins.lsp-config" },
        { import = "plugins.markdown" },
        { import = "plugins.minidiff" },
        { import = "plugins.nerdtree" },
        { import = "plugins.nibbler" },
        { import = "plugins.noice" },

        { import = "plugins.ollama" },

        { import = "plugins.oil" },
        { import = "plugins.telescope" },
        { import = "plugins.toggle-term" },
        { import = "plugins.treesitter" },
        { import = "plugins.undotree" },
        { import = "plugins.which-key" },
    },

    -- Lazy.nvim options
    checker = {
        enabled = true,
        notify = false,
    },
})

-- vim.cmd.colorscheme "aurora"
vim.cmd.colorscheme "catppuccin-frappe"

require("after.color-fix")
require("after.autocmds")
