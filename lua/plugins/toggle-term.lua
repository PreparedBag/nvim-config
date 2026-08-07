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
        { "<leader>t", desc = "Toggle Terminal (CWD / Oil Dir)" },
        { "<leader>T", desc = "Toggle Terminal (Session Dir)" },
    },
    config = function(_, opts)
        require("toggleterm").setup(opts)

        local Terminal = require("toggleterm.terminal").Terminal

        -- <C-q> force-closes whichever terminal this is attached to,
        -- regardless of mode or prompt text - unlike <C-d>, which only
        -- closes on an empty prompt (that's just normal shell EOF, not
        -- something toggleterm controls). Set on `t` and `n` mode buffer-
        -- locally since terminal buffers support both.
        local function attach_close_keymap(term)
            local map_opts = { buffer = term.bufnr, noremap = true, silent = true, desc = "Close Terminal" }
            vim.keymap.set("t", "<C-d>", function() term:close() end, map_opts)
            vim.keymap.set("n", "<C-d>", function() term:close() end, map_opts)
        end

        -- Persistent, cwd-anchored terminal. Directory is fixed once, at
        -- creation - never changed afterward, so this never touches a
        -- running shell's channel (no more change_dir/chansend errors).
        local cwd_term = Terminal:new({
            direction = "float",
            hidden = true,
            dir = vim.fn.getcwd(),
            on_open = attach_close_keymap,
        })

        -- Persistent, anchored to wherever this session originally started.
        local original_term = Terminal:new({
            direction = "float",
            hidden = true,
            dir = _G.session_directory or vim.fn.getcwd(),
            on_open = attach_close_keymap,
        })

        vim.keymap.set("n", "<leader>t", function()
            if vim.bo.filetype == "oil" then
                -- Deliberately NOT cwd_term: a fresh, disposable terminal
                -- for this one directory, gone once you exit it. Doing
                -- file stuff here never touches cwd_term's state at all.
                local oil_term = Terminal:new({
                    direction = "float",
                    dir = require("oil").get_current_dir(),
                    close_on_exit = true, -- wipe itself once the shell exits
                    on_open = attach_close_keymap,
                })
                oil_term:toggle()
                return
            end

            cwd_term:toggle()
        end, { noremap = true, silent = true, desc = "Toggle Terminal (CWD / Oil Dir)" })

        vim.keymap.set("n", "<leader>T", function()
            original_term:toggle()
        end, { noremap = true, silent = true, desc = "Toggle Terminal (Session Dir)" })
    end,
}
