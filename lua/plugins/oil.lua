return {
    'stevearc/oil.nvim',
    lazy = false,   -- Load immediately since you use "nvim ."
    priority = 900, -- Load after colorscheme but before most plugins
    dependencies = { "echasnovski/mini.icons" },
    config = function()
        local oil = require("oil")

        oil.setup({
            default_file_explorer = true,
            columns = {
                "icon",
            },
            view_options = {
                show_hidden = true, -- Start with hidden files not shown
                is_hidden_file = function(name, bufnr)
                    return vim.startswith(name, ".")
                end,
            },
            keymaps = {
                ["g?"] = "actions.show_help",
                ["<CR>"] = "actions.select",
                ["<C-s>"] = "actions.select_vsplit",
                ["<C-h>"] = false, -- Disable default C-h since we use it for signature help
                ["<C-t>"] = "actions.select_tab",
                ["<C-p>"] = "actions.preview",
                ["<C-c>"] = "actions.close",
                ["<C-l>"] = "actions.refresh",
                ["-"] = "actions.parent",
                ["_"] = "actions.open_cwd",
                ["`"] = "actions.cd",
                ["~"] = "actions.tcd",
                ["gs"] = "actions.change_sort",
                ["gx"] = "actions.open_external",
                ["g."] = "actions.toggle_hidden", -- Toggle hidden files
            },
        })

        -- Open Oil with <leader>fe
        vim.keymap.set("n", "<leader>fe", ":Oil<CR>", { noremap = true, silent = true, desc = "File Explorer" })

        -- In Oil buffers, make <leader>r refresh and add toggle hidden shortcut
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "oil",
            callback = function(event)
                local actions = require("oil.actions")

                -- Refresh
                vim.keymap.set(
                    "n",
                    "<leader>r",
                    actions.refresh.callback,
                    { buffer = event.buf, silent = true, desc = "Refresh Oil" }
                )

                -- Toggle hidden files (additional shortcut besides g.)
                vim.keymap.set(
                    "n",
                    "<leader>h",
                    actions.toggle_hidden.callback,
                    { buffer = event.buf, silent = true, desc = "Toggle Hidden Files" }
                )
            end,
        })
    end,
}
