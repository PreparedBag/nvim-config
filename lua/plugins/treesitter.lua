return {
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        -- event = { "BufReadPost", "BufNewFile" },
        build = ":TSUpdate",
        config = function()
            local ok, ts = pcall(require, "nvim-treesitter.configs")
            if not ok then
                ok, ts = pcall(require, "nvim-treesitter.config")
            end

            if ok then
                ts.setup({
                    ensure_installed = { "c", "lua", "vim", "vimdoc", "html", "css", "javascript", "mermaid", "yaml", "markdown", "go", "gomod", "gowork", "gosum", "rust" },
                    auto_install = true,
                    sync_install = false,
                    highlight = { enable = true },
                    indent = { enable = true },
                })
            end
        end
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("nvim-treesitter.configs").setup({
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                            ["ac"] = "@class.outer",
                            ["ic"] = "@class.inner",
                            ["aa"] = "@parameter.outer",
                            ["ia"] = "@parameter.inner",
                            ["ab"] = "@block.outer",
                            ["ib"] = "@block.inner",
                        },
                    },
                    move = {
                        enable = true,
                        set_jumps = true,
                        goto_next_start = {
                            ["]f"] = "@function.outer",
                            ["]c"] = "@class.outer",
                        },
                        goto_previous_start = {
                            ["[f"] = "@function.outer",
                            ["[c"] = "@class.outer",
                        },
                    },
                },
            })
        end,
    }
}
