return {
    'saghen/blink.cmp',
    enabled = require("config.flags").get("LSP_ENABLED"),
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    opts = {
        keymap = {
            preset = 'none',
            ['<C-space>'] = { 'show', 'hide' },
            ['<C-s>'] = { function(cmp) cmp.show({ providers = { 'snippets' } }) end },
            ['<C-j>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ['<CR>'] = { 'accept', 'fallback' },
            ['<C-e>'] = { 'hide', 'fallback' },
            ['<C-y>'] = { 'accept', 'fallback' },
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
            default = function(ctx)
                local bufnr = ctx and ctx.bufnr or vim.api.nvim_get_current_buf()
                if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
                    return { 'lsp', 'path', 'snippets', 'buffer' }
                end
                return { 'path', 'snippets', 'buffer' }
            end,
        },
        fuzzy = {
            implementation = "prefer_rust_with_warning"
        }
    },
    opts_extend = { "sources.default" }
}
