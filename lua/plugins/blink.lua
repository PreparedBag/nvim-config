return {
    'saghen/blink.cmp',
    dependencies = { 'rafamadriz/friendly-snippets' },
    version = '1.*',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        -- Only enable for actual code files with LSP attached
        enabled = function()
            local bufnr = vim.api.nvim_get_current_buf()

            -- Check if explicitly disabled for this buffer
            if vim.b[bufnr].blink_cmp_enabled == false then
                return false
            end

            -- Get buffer type and filetype
            local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
            local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

            -- Disable for special buffer types
            if buftype ~= '' and buftype ~= 'acwrite' then
                return false
            end

            -- Disable for AI chat and special filetypes
            local excluded_filetypes = {
                'codecompanion',
                'TelescopePrompt',
                'help',
                'terminal',
                'prompt',
                'nofile',
                'qf',
                'lazy',
                'mason',
                'oil',
                'neo-tree',
                'NvimTree',
                'starter',
                'dashboard',
                'alpha',
            }

            for _, excluded_ft in ipairs(excluded_filetypes) do
                if filetype == excluded_ft or filetype:match(excluded_ft) then
                    return false
                end
            end

            -- Only enable if LSP is attached to this buffer
            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            if #clients == 0 then
                return false
            end

            -- Default: enabled (only reached if LSP is attached and it's a normal file)
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
