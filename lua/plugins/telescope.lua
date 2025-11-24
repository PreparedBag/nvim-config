return {
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        dependencies = {
            'nvim-lua/plenary.nvim',
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make', -- or 'cmake -S. -Bbuild && cmake --build build --config Release'
            },
        },
        config = function()
            local telescope = require('telescope')

            -- Function to set the working directory to the original one
            local set_telescope_cwd_to_original = function()
                if _G.original_working_directory then
                    vim.cmd('cd ' .. vim.fn.fnameescape(_G.original_working_directory))
                    print('Changed working directory to original: ' .. _G.original_working_directory)
                else
                    print('Error: Original working directory is not set.')
                end
            end

            -- Function to set the working directory to the updated Netrw directory
            local set_telescope_cwd_to_updated = function()
                local oil = require("oil") -- Assuming Oil is loaded and required

                -- Check if Oil is active and set the directory accordingly
                local oil_dir = oil.get_current_dir() -- This is an Oil-specific function
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

            -- Telescope setup
            telescope.setup({
                defaults = {
                    layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = { preview_width = 0.5 },
                        vertical = { preview_height = 0.5 },
                    },
                    fzf = {
                        fuzzy = true, -- keep fuzzy
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                    -- file_ignore_patterns = {
                    --     "%.jpg", "%.jpeg", "%.png", "%.gif", "%.bmp", "%.tiff",
                    --     "%.o", "%.out", "%.exe", "%.a", "%.so", "%.dll",
                    --     "%.zip", "%.tar", "%.gz", "%.rar", "%.7z", "%.bz2",
                    --     "%.pdf", "%.docx", "%.xlsx", "%.pptx", "%.doc", "%.xls",
                    --     "%.mp4", "%.mkv", "%.mp3", "%.avi", "%.flv", "%.mov",
                    --     "%.class", "%.jar", "%.war",
                    --     "%.bin", "%.iso",
                    --     "%.dmg", "%.pkg",
                    --     "%.lock", "%.log",
                    --     "%.xcf",
                    -- },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown {
                        }
                    }
                }
            })

            telescope.load_extension("ui-select")
            telescope.load_extension('fzf')

            -- Load media files extension
            local builtin = require('telescope.builtin')

            local opts = { noremap = true, silent = true }
            vim.keymap.set("n", "<leader>ff", builtin.find_files, opts)
            vim.keymap.set("n", "<leader>fa", function() builtin.find_files({ hidden = true }) end, opts)
            vim.keymap.set("n", "<leader>fp", function()
                require("telescope.builtin").live_grep({
                    additional_args = function()
                        return { "--fixed-strings" }
                    end,
                })
            end, { desc = "Grep (exact string)" })
            -- vim.keymap.set("n", "<leader>fp", builtin.live_grep, opts)
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, opts)
            vim.keymap.set("n", "<leader>fs", ":Telescope find_files<CR><ESC>", opts)
            vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR><ESC>", opts)

            vim.keymap.set("n", "<leader>fd", function() set_telescope_cwd_to_updated() end, opts)
            vim.keymap.set("n", "<leader>fo", function() set_telescope_cwd_to_original() end, opts)
            vim.keymap.set("n", "<leader>fe", ":Oil<CR>", opts)
        end
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
    }
}
