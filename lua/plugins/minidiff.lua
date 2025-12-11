return {
    'echasnovski/mini.diff',
    version = false,
    config = function()
        require('mini.diff').setup({
            -- Options for how buffers are updated
            view = {
                style = 'sign', -- 'sign' or 'number'
                signs = { add = '▎', change = '▎', delete = '▎' },
                priority = 199,
            },

            -- Module mappings
            mappings = {
                -- Apply hunks
                apply = 'gh',
                -- Reset hunks
                reset = 'gH',
                -- Textobject for hunk
                textobject = 'gh',
                -- Go to hunk
                goto_first = '[H',
                goto_prev = '[h',
                goto_next = ']h',
                goto_last = ']H',
            },

            -- Various options
            options = {
                -- Algorithm to use for computing diffs
                algorithm = 'histogram',
                -- How to calculate indent
                indent_heuristic = true,
                -- Linematch parameter (nil to disable)
                linematch = 60,
            },
        })
    end,
}
