return {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        -- Add enabled function to check buffer variable
        enabled = function()
            local bufnr = vim.api.nvim_get_current_buf()
            -- Check if explicitly disabled for this buffer
            if vim.b[bufnr].blink_cmp_enabled == false then
                return false
            end
            -- Default: enabled
            return true
        end,

        keymap = {
            preset = 'none',
            ['<C-space>'] = { 'show', 'hide' },
            ['<C-j>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ['<CR>'] = { 'accept', 'fallback' },
            ['<C-e>'] = { 'hide', 'fallback' },
            ['<C-y>'] = { 'accept', 'fallback' },
            ['<C-h>'] = { 'show_documentation', 'hide_documentation' },
        },

        appearance = {
            nerd_font_variant = 'mono'
        },

        completion = {
            documentation = { auto_show = false }
        },

        sources = {
            default = { 'lsp', 'path', 'snippets', 'buffer' },
        },

        fuzzy = {
            implementation = "prefer_rust_with_warning"
        }
    },

    opts_extend = { "sources.default" }
}
