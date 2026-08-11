return {
    'stevearc/oil.nvim',
    lazy = false,   -- Load immediately since you use "nvim ."
    priority = 900, -- Load after colorscheme but before most plugins
    dependencies = { "echasnovski/mini.icons" },
    config = function()
        local oil = require("oil")

        -- Function to set the working directory to the session one
        local set_telescope_cwd_to_session = function()
            if _G.session_directory then
                vim.cmd('cd ' .. vim.fn.fnameescape(_G.session_directory))
                print('Changed working directory to session: ' .. _G.session_directory)
            else
                print('Error: Session directory is not set.')
            end
        end

        -- Function to set the working directory to the updated Netrw directory
        local set_telescope_cwd_to_updated = function()
            local oil = require("oil")     -- Assuming Oil is loaded and required

            -- Check if Oil is active and set the directory accordingly
            local oil_dir = oil.get_current_dir()     -- This is an Oil-specific function
            if oil_dir and vim.fn.isdirectory(oil_dir) == 1 then
                vim.cmd('cd ' .. vim.fn.fnameescape(oil_dir))
                print('Changed working directory to Oil path: ' .. oil_dir)
            else
                -- Fallback to regular Netrw behavior
                local netrw_dir = vim.fn.fnamemodify(vim.fn.expand('%:p:h'), ':p')
                if vim.fn.isdirectory(netrw_dir) == 1 then
                    vim.cmd('lcd ' .. vim.fn.fnameescape(netrw_dir))
                    print('Changed working directory to Netrw path: ' .. netrw_dir)
                else
                    print('Error: Invalid directory')
                end
            end
        end

        oil.setup({
            default_file_explorer = true,
            columns = {
                "icon",
                "permissions",
                "size",
                "mtime",
            },
            view_options = {
                show_hidden = true, -- Start with hidden files not shown
                is_hidden_file = function(name)
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
                -- ["<C-l>"] = "actions.refresh",
                ["-"] = "actions.parent",
                ["_"] = "actions.open_cwd",
                ["`"] = "actions.cd",
                ["~"] = "actions.tcd",
                ["gs"] = "actions.change_sort",
                ["gx"] = "actions.open_external",
                ["g."] = "actions.toggle_hidden", -- Toggle hidden files
            },
        })

        vim.keymap.set("n", "<leader>od", function() set_telescope_cwd_to_updated() end,
            { noremap = true, silent = true, desc = "Set Telescope CWD Here" })

        vim.keymap.set("n", "<leader>oo", function() set_telescope_cwd_to_session() end,
            { noremap = true, silent = true, desc = "Set Telescope CWD to Session Dir" })

        vim.keymap.set("n", "<leader>fe", ":Oil<CR>", { noremap = true, silent = true, desc = "File Explorer (Oil)" })

        vim.keymap.set("n", "<leader>os", function()
            require("oil").open(_G.session_directory or vim.fn.getcwd())
        end, { noremap = true, silent = true, desc = "Open Oil (Session Directory)" })

        vim.keymap.set("n", "<leader>oe", function()
            require("oil").open(vim.fn.getcwd())
        end, { noremap = true, silent = true, desc = "Open Oil (CWD)" })

        -- In Oil buffers, make <leader>r refresh and add toggle hidden shortcut
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "oil",
            callback = function(event)
                local actions = require("oil.actions")

                -- Refresh
                vim.keymap.set(
                    "n",
                    "<leader>or",
                    actions.refresh.callback,
                    { buffer = event.buf, silent = true, desc = "Refresh Oil" }
                )

                -- Toggle hidden files (additional shortcut besides g.)
                vim.keymap.set(
                    "n",
                    "<leader>oh",
                    actions.toggle_hidden.callback,
                    { buffer = event.buf, silent = true, desc = "Toggle Hidden Files" }
                )
            end,
        })
    end,
}
