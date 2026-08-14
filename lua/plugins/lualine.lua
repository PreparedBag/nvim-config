return {
    'nvim-lualine/lualine.nvim',
    event = "VeryLazy",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local lualine = require('lualine')

        local session_component = {
            function()
                if not _G.session_directory then
                    return ""
                end
                return " " .. vim.fn.fnamemodify(_G.session_directory, ":t") .. " "
            end,
        }

        lualine.setup({
            options = {
                icons_enabled        = true,
                theme                = "auto",
                component_separators = { left = '|', right = '|' },
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
                        "dapui_scopes",
                        "dapui_breakpoints",
                        "dapui_stacks",
                        "dapui_watches",
                        "dapui_console",
                        "dapui_repl",
                        "dap-repl",
                    },
                },
                always_divide_middle = false,
                globalstatus         = false,
            },
            sections = {
                lualine_a = { 'mode' },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = { 'filename' },
                lualine_x = { 'filetype' },
                lualine_y = { 'progress' },
                lualine_z = { session_component }
            },
            inactive_sections = {
                lualine_a = { 'mode' },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = { 'filename' },
                lualine_x = { 'filetype' },
                lualine_y = { 'progress' },
                lualine_z = { session_component }
            },
        })
    end
}
