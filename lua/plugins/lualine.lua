return {
    'nvim-lualine/lualine.nvim',
    event = "VeryLazy",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local lualine = require('lualine')
        lualine.setup({
            options = {
                icons_enabled        = true,
                theme                = "auto",

                -- Powerline-style separators
                component_separators = { left = '', right = '' },
                section_separators   = { left = '', right = '' },

                disabled_filetypes   = {
                    statusline = {
                        "nerdtree",
                        "dapui_scopes",
                        "dapui_breakpoints",
                        "dapui_stacks",
                        "dapui_watches",
                        "dapui_console",
                        "dapui_repl",
                        "dap-repl",
                    },
                    winbar = {
                        "nerdtree",
                    },
                },
                always_divide_middle = true,
                globalstatus         = false,
                refresh              = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000,
                }
            },
            sections = {
                lualine_a = { 'mode' },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = {
                    {
                        'filename',
                        path = 2,
                        fmt = function(str)
                            return str:gsub("^oil://", "")
                        end,
                    },
                },
                lualine_x = { 'filetype' },
                lualine_y = { 'progress' },
                lualine_z = { 'location' }
            }
        })
    end
}
