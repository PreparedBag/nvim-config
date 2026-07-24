return {
    'numToStr/Comment.nvim',
    keys = {
        { "gcc", mode = "n", desc = "Comment line" },
        { "gbc", mode = "n", desc = "Block comment line" },
        { "gc",  mode = "v", desc = "Comment selection" },
        { "gb",  mode = "v", desc = "Block comment selection" },
    },
    config = function()
        require('Comment').setup()
        local ft = require('Comment.ft')
        -- { line, block } ; padding adds the inner spaces
        ft.c = { '//%s', '/* ---%s--- */' }
        ft.cpp = ft.c     -- covers .h if it's detected as cpp
    end
}
