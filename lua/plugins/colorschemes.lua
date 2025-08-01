return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "frappe", -- latte, frappe, macchiato, mocha
                background = {    -- :h background
                    light = "latte",
                    dark = "frappe",
                },
                transparent_background = false,    -- disables setting the background color.
                show_end_of_buffer = false,        -- shows the '~' characters after the end of buffers
                term_colors = true,                -- sets terminal colors (e.g. `g:terminal_color_0`)
                dim_inactive = {
                    enabled = false,               -- dims the background color of inactive window
                    shade = "dark",
                    percentage = 0.30,             -- percentage of the shade to apply to the inactive window
                },
                no_italic = false,                 -- Force no italic
                no_bold = true,                    -- Force no bold
                no_underline = true,               -- Force no underline
                styles = {                         -- Handles the styles of general hi groups (see `:h highlight-args`):
                    comments = { "italic" },       -- Change the style of comments
                    conditionals = { "italic" },
                    loops = {},
                    functions = {},
                    keywords = {},
                    strings = {},
                    variables = {},
                    numbers = {},
                    booleans = {},
                    properties = {},
                    types = {},
                    operators = {},
                    -- miscs = {}, -- Uncomment to turn off hard-coded styles
                },
                color_overrides = {},
                custom_highlights = {},
                default_integrations = true,
                integrations = {
                    cmp = true,
                    gitsigns = true,
                    harpoon = true,
                    nvimtree = true,
                    treesitter = true,
                    noice = true,
                    notify = true,
                    mini = {
                        enabled = true,
                        indentscope_color = "",
                    },
                    mason = true,
                },
            })
        end
    },
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
    },
    { 'lunarvim/colorschemes' },
}
