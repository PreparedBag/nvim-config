return {
    {
        'nvim-telescope/telescope.nvim',
        version = "*",
        -- tag = '0.1.8',
        dependencies = {
            'nvim-lua/plenary.nvim',
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make', -- or 'cmake -S. -Bbuild && cmake --build build --config Release'
            },
        },
        config = function()
            local telescope = require('telescope')
            local actions = require('telescope.actions')
            local state = require("telescope.state")
            local action_set = require("telescope.actions.set")

            -- move the *selection* through the results by a fraction of the window
            local function page_results(dir, frac) -- dir: 1 down / -1 up
                return function(prompt_bufnr)
                    local win = state.get_status(prompt_bufnr).results_win
                    local height = vim.api.nvim_win_get_height(win)
                    action_set.shift_selection(prompt_bufnr, math.floor(height * frac) * dir)
                end
            end

            -- Reads optional .nvim-project-settings.lua from the project root for extra
            -- search directories (e.g. a sibling ../shared library outside cwd).
            -- Returns nil (telescope's own default: just cwd) if the file isn't there.
            local function project_search_dirs()
                local extra = require('config.utils').section('telescope')
                if not extra or type(extra.extra_dirs) ~= 'table' then
                    return nil
                end

                local root = vim.fn.getcwd()
                local dirs = { root }
                for _, rel in ipairs(extra.extra_dirs) do
                    table.insert(dirs, vim.fn.fnamemodify(root .. '/' .. rel, ':p'))
                end
                return dirs
            end

            -- Extra `--glob '!pattern'` args from .nvim-project-settings.lua's
            -- telescope.exclude, on top of whatever a picker's own find_command/
            -- vimgrep_arguments already excludes.
            local function project_exclude_args()
                local ok, project = pcall(require, 'config.project')
                if not ok then
                    return {}
                end

                local extra = project.section('telescope')
                local args = {}
                if extra and type(extra.exclude) == 'table' then
                    for _, pattern in ipairs(extra.exclude) do
                        table.insert(args, '--glob')
                        table.insert(args, '!' .. pattern)
                    end
                end
                return args
            end

            local function relative_path_display(opts, path)
                return require("config.utils").relative_path(opts.cwd or vim.uv.cwd(), path)
            end

            local shared = {
                ["<C-y>"] = { actions.smart_send_to_qflist, type = "action", opts = { desc = "Send to quickfix" } },
                ["<C-l>"] = false, -- Disable default C-l since we use it for move right
            }

            local insert_mappings = vim.tbl_extend("force", {}, shared, {
                ["<C-j>"] = { actions.move_selection_next, type = "action", opts = { desc = "Next result" } },
                ["<C-k>"] = { actions.move_selection_previous, type = "action", opts = { desc = "Previous result" } },
            })

            local normal_mappings = vim.tbl_extend("force", {}, shared, {
                ["<C-j>"] = { page_results(1, 0.5), type = "action", opts = { desc = "Results: half-page down" } },
                ["<C-k>"] = { page_results(-1, 0.5), type = "action", opts = { desc = "Results: half-page up" } },
            })

            -- Telescope setup
            telescope.setup({
                defaults = {
                    path_display = relative_path_display,
                    scroll_strategy = "limit",
                    layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = { preview_width = 0.5 },
                        vertical = { preview_height = 0.5 },
                    },
                    preview = { treesitter = false },
                    -- Send Tab-marked items (or all if none marked) to the quickfix list.
                    -- Does NOT auto-open anything; view it later with <leader>fq.
                    mappings = { i = insert_mappings, n = normal_mappings },
                },
                extensions = {
                    -- fzf-native is an extension, so its config belongs HERE, not
                    -- under defaults (where it was silently ignored before).
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                    -- ["ui-select"] = {
                    --     require("telescope.themes").get_dropdown({
                    --         initial_mode = "normal",
                    --     }),
                    -- },
                },
            })

            -- telescope.load_extension("ui-select")
            telescope.load_extension('fzf')

            local builtin = require('telescope.builtin')

            vim.keymap.set("n", "<leader>ff", function()
                builtin.find_files({
                    prompt_title = "Find Files",
                    search_dirs = project_search_dirs(),
                    find_command = vim.list_extend({
                        'rg',
                        '--files',
                        '--glob',
                        '!.git/*',
                    }, project_exclude_args())
                })
            end, { noremap = true, silent = true, desc = "Find Files (Fuzzy Finder)" })

            vim.keymap.set("n", "<leader>fp", function()
                builtin.live_grep({
                    prompt_title = "Live Grep",
                    search_dirs = project_search_dirs(),
                    vimgrep_arguments = vim.list_extend({
                        'rg',
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                        '--glob',
                        '!.git/*',
                        '--glob',
                        '!node_modules/*',
                        '--glob',
                        '!*.min.js'
                    }, project_exclude_args())
                })
            end, { noremap = true, silent = true, desc = "Find Phrase (Live Grep)" })

            vim.keymap.set("n", "<leader>fa", function()
                builtin.find_files({
                    prompt_title = "Find Files (Include All)",
                    search_dirs = project_search_dirs(),
                    hidden = true,
                    find_command = {
                        'rg',
                        '--files',
                        '--hidden',
                        '--no-ignore',
                        '--glob',
                        '!.git/*'
                    }
                })
            end, { noremap = true, silent = true, desc = "Find All Files (Include All)" })

            vim.keymap.set("n", "<leader>fs", function()
                builtin.live_grep({
                    prompt_title = "Live Grep (Include All)",
                    search_dirs = project_search_dirs(),
                    vimgrep_arguments = {
                        'rg',
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                        '--no-ignore',
                        '--hidden',
                        '--glob',
                        '!.git/*',
                        '--glob',
                        '!node_modules/*',
                        '--glob',
                        '!*.min.js'
                    }
                })
            end, { noremap = true, silent = true, desc = "Find String (Include All)" })

            vim.keymap.set("n", "<leader>fH", builtin.help_tags, { noremap = true, silent = true, desc = "Help Tags" })

            -- Grep the word under the cursor
            vim.keymap.set("n", "<leader>fw", function()
                local word = vim.fn.expand("<cword>")
                require('telescope.builtin').grep_string({
                    search = word,
                    search_dirs = project_search_dirs(),
                    initial_mode = "normal",
                    prompt_title = "Ripgrep: " .. word,
                })
            end, { noremap = true, silent = true, desc = "Find Word (Ripgrep)" })

            -- Grep the visual selection
            vim.keymap.set("v", "<leader>fw", function()
                local save = vim.fn.getreg("v")
                vim.cmd('noautocmd normal! "vy')
                local text = vim.fn.getreg("v")
                vim.fn.setreg("v", save)

                text = text:gsub("\n", " ")
                text = text:gsub("^%s+", ""):gsub("%s+$", "")
                if text == "" then return end

                require("telescope.builtin").grep_string({
                    search = text,
                    search_dirs = project_search_dirs(),
                    initial_mode = "normal",
                    prompt_title = "Ripgrep: " .. text,
                })
            end, { noremap = true, silent = true, desc = "Find Word (Ripgrep)" })

            vim.keymap.set("n", "<leader>fq", function()
                local nr = vim.fn.getqflist({ nr = 0 }).nr
                require("telescope.builtin").quickfix({
                    initial_mode = "normal",
                    nr = nr,
                    cache_picker = false,
                })
            end, { noremap = true, silent = true, desc = "View Quickfix List" })

            vim.keymap.set("n", "<leader>fh", function()
                local action_state = require("telescope.actions.state")
                require("telescope.builtin").quickfixhistory({
                    initial_mode = "normal",
                    attach_mappings = function(_, map)
                        action_set.select:replace(function(prompt_bufnr)
                            local nr = action_state.get_selected_entry().nr
                            actions.close(prompt_bufnr)
                            if not nr then return end
                            vim.cmd(nr .. "chistory")
                        end)
                        return true
                    end,
                })
            end, { noremap = true, silent = true, desc = "View Quickfix History" })

            local theme = require("after.theme-utils")

            theme.on_colorscheme(function()
                local hl = { fg = theme.theme_fg("Title"), bg = "none", bold = true, italic = true }
                vim.api.nvim_set_hl(0, "TelescopePromptTitle", hl)
                vim.api.nvim_set_hl(0, "TelescopeResultsTitle", hl)
                vim.api.nvim_set_hl(0, "TelescopePreviewTitle", hl)
            end)

            vim.keymap.set('n', '<leader>fc', function()
                local config_path = vim.fn.expand('~/.config/nvim')
                vim.cmd.ex(config_path)
            end, { noremap = true, silent = true, desc = 'Open Nvim Config Folder' })
        end
    },
    -- {
    --     "nvim-telescope/telescope-ui-select.nvim",
    -- }
}
