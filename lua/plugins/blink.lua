return {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    opts = {
        -- Only enable for actual code files with LSP attached
        enabled = function()
            local bufnr = vim.api.nvim_get_current_buf()
            if vim.b[bufnr].blink_cmp_enabled == false then
                return false
            end
            local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
            if buftype ~= '' and buftype ~= 'acwrite' then
                return false
            end
            -- only enable when an LSP is attached
            return #vim.lsp.get_clients({ bufnr = bufnr }) > 0
        end,

        keymap = {
            preset = 'none',
            ['<C-space>'] = { 'show', 'hide' },
            ['<C-s>'] = { function(cmp) cmp.show({ providers = { 'snippets' } }) end },
            ['<C-j>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ['<CR>'] = { 'accept', 'fallback' },
            ['<C-e>'] = { 'hide', 'fallback' },
            ['<C-y>'] = { 'accept', 'fallback' },
            ['<C-h>'] = { 'show_documentation', 'hide_documentation' },
            ['<Tab>'] = { 'snippet_forward', 'fallback' },
            ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
        },

        snippets = { preset = 'luasnip' },

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
