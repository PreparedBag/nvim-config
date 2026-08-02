return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        branch = "main",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup()

            -- Parsers to install (replaces ensure_installed).
            require("nvim-treesitter").install({
                "c", "regex", "lua", "vim", "vimdoc", "html", "css",
                "javascript", "mermaid", "yaml", "markdown", "markdown_inline",
                "go", "gomod", "gowork", "gosum", "rust",
            })

            -- Enable highlighting (and indent expr) per-buffer.
            -- On `main` there is no highlight = { enable = true }; you start
            -- treesitter yourself when a buffer's filetype has a parser.
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(ev)
                    local ok = pcall(vim.treesitter.start, ev.buf)
                    if ok then
                        -- treesitter-based indentation (opt-in, per buffer)
                        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = { lookahead = true },
                move = { set_jumps = true },
            })

            -- Selection text objects: map them yourself on `main`.
            local sel = require("nvim-treesitter-textobjects.select").select_textobject
            local map = function(key, obj, desc)
                vim.keymap.set({ "x", "o" }, key, function()
                    sel(obj, "textobjects")
                end, { desc = desc })
            end
            map("af", "@function.outer", "a function")
            map("if", "@function.inner", "inner function")
            map("ac", "@class.outer", "a class")
            map("ic", "@class.inner", "inner class")
            map("aa", "@parameter.outer", "a parameter")
            map("ia", "@parameter.inner", "inner parameter")
            map("ab", "@block.outer", "a block")
            map("ib", "@block.inner", "inner block")

            -- Movement: map next/prev yourself on `main`.
            local move = require("nvim-treesitter-textobjects.move")
            vim.keymap.set({ "n", "x", "o" }, "]f", function()
                move.goto_next_start("@function.outer", "textobjects")
            end, { desc = "Next function" })
            vim.keymap.set({ "n", "x", "o" }, "[f", function()
                move.goto_previous_start("@function.outer", "textobjects")
            end, { desc = "Prev function" })
            vim.keymap.set({ "n", "x", "o" }, "]c", function()
                move.goto_next_start("@class.outer", "textobjects")
            end, { desc = "Next class" })
            vim.keymap.set({ "n", "x", "o" }, "[c", function()
                move.goto_previous_start("@class.outer", "textobjects")
            end, { desc = "Prev class" })
        end,
    },
}
