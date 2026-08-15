return {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
        direction = "float",
        float_opts = {
            border = "rounded",
        },
    },
    keys = {
        { "<leader>tt", desc = "Show Terminal (CWD / Oil Dir)" },
        { "<leader>ts", desc = "Show Terminal (Session Dir)" },
        { "<leader>tg", desc = "Show Terminal (Git Dir)" },
    },
    config = function(_, opts)
        require("toggleterm").setup(opts)

        local terminal = require("toggleterm.terminal").Terminal

        local function attach_close_keymap(term)
            local map_opts = { buffer = term.bufnr, noremap = true, silent = true, desc = "Close Terminal" }
            vim.keymap.set("t", "<C-d>", function() term:close() end, map_opts)
            vim.keymap.set("n", "<C-d>", function() term:close() end, map_opts)
        end

        local function open_term(dir)
            terminal:new({
                direction = "float",
                hidden = true,
                dir = dir,
                on_open = attach_close_keymap,
            }):toggle()
        end

        vim.keymap.set("n", "<leader>tt", function()
            local dir = vim.fn.getcwd()
            if vim.bo.filetype == "oil" then
                dir = require("oil").get_current_dir()
            end
            open_term(dir)
        end, { noremap = true, silent = true, desc = "Show Terminal (CWD / Oil Dir)" })

        vim.keymap.set("n", "<leader>ts", function()
            open_term(_G.session_directory or vim.fn.getcwd())
        end, { noremap = true, silent = true, desc = "Show Terminal (Session Dir)" })

        vim.keymap.set("n", "<leader>tg", function()
            local root = vim.fs.root(0, ".git")
            if not root then
                vim.notify("Not a git repository", vim.log.levels.INFO)
                open_term(vim.fn.getcwd())
                return
            end
            open_term(root)
        end, { noremap = true, silent = true, desc = "Show Terminal (Git Dir)" })
    end,
}
