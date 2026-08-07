return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    keys = {
        { "<leader>ha", function() require("harpoon"):list():add() end,    desc = "Add Current Buffer to Harpoon" },
        {
            "<leader>hc",
            function()
                require("harpoon"):list():clear()
                vim.notify("Harpoon list cleared", vim.log.levels.INFO)
            end,
            desc = "Clear Harpoon List",
        },
        {
            "<leader>hA",
            function()
                local harpoon = require("harpoon")
                local added = 0
                for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                    -- Must be loaded and listed (skips scratch/unlisted buffers)
                    if vim.api.nvim_buf_is_loaded(bufnr)
                        and vim.bo[bufnr].buflisted
                        and vim.bo[bufnr].buftype == ""     -- real file buffer, not oil/terminal/qf
                        and vim.bo[bufnr].filetype ~= "oil" -- belt-and-suspenders on oil
                    then
                        local name = vim.api.nvim_buf_get_name(bufnr)
                        -- Non-empty name that points at an actual file on disk
                        if name ~= "" and vim.fn.filereadable(name) == 1 then
                            -- Store absolute (matches create_list_item below) -
                            -- no path math needed here at all.
                            harpoon:list():add({
                                value = name,
                                context = { row = 1, col = 0 },
                            })
                            added = added + 1
                        end
                    end
                end
                vim.notify(("Added %d buffer(s) to Harpoon"):format(added), vim.log.levels.INFO)
            end,
            desc = "Add Open Buffers to Harpoon",
        },
        {
            "<leader>he",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(harpoon:list(), { title = "", title_pos = "center" })
            end,
            desc = "Harpoon Edit",
        },
        { "<leader>1",  function() require("harpoon"):list():select(1) end },
        { "<leader>2",  function() require("harpoon"):list():select(2) end },
        { "<leader>3",  function() require("harpoon"):list():select(3) end },
        { "<leader>4",  function() require("harpoon"):list():select(4) end },
        { "<leader>5",  function() require("harpoon"):list():select(5) end },
        { "<leader>6",  function() require("harpoon"):list():select(6) end },
        { "<leader>7",  function() require("harpoon"):list():select(7) end },
        { "<leader>8",  function() require("harpoon"):list():select(8) end },
    },
    config = function()
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "harpoon",
            callback = function()
                local win = vim.api.nvim_get_current_win()
                local cfg = vim.api.nvim_win_get_config(win)
                cfg.border = "rounded"
                cfg.title = " Harpoon Quick List "
                cfg.title_pos = "center"
                vim.api.nvim_win_set_config(win, cfg)
            end,
        })

        local harpoon = require("harpoon")

        harpoon:setup({
            settings = {
                -- Which project's marks - the bucket. Always the stable
                -- session root, never live cwd.
                key = function()
                    return _G.session_directory
                end,
            },
            default = {
                -- Same anchor, used by create_list_item/select/BufLeave
                -- internally for anything that needs a root.
                get_root_dir = function()
                    return _G.session_directory
                end,

                -- Store the ABSOLUTE path. This is what harpoon's own
                -- select()/get_by_value/BufLeave all assume `value` is -
                -- storing anything else means reimplementing all of them.
                -- Relative is only what a human wants to SEE, so that
                -- conversion happens in `display` alone, below.
                create_list_item = function(config, name)
                    name = name or vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())

                    -- resolve_displayed() (quick-menu save/sync) can
                    -- re-invoke this with an already-relative string (the
                    -- displayed text) - resolve it against root in that
                    -- case too, so value is always absolute either way.
                    if not name:match("^/") then
                        name = config.get_root_dir() .. "/" .. name
                    end
                    name = vim.fn.fnamemodify(name, ":p")

                    local bufnr = vim.fn.bufnr(name, false)
                    local pos = { 1, 0 }
                    if bufnr ~= -1 then
                        pos = vim.api.nvim_win_get_cursor(0)
                    end

                    return {
                        value = name,
                        context = { row = pos[1], col = pos[2] },
                    }
                end,

                -- The only place relative display actually matters -
                -- computed fresh from the absolute value each time, for
                -- the quick-menu. select() is left as harpoon's own
                -- default: it already works correctly once value is
                -- absolute, cwd or no cwd, so there's nothing to override.
                display = function(list_item)
                    return require("config.project").relative_path(_G.session_directory, list_item.value)
                end,
            },
        })

        -- attach a buffer-local save map when the NATIVE quick menu opens
        harpoon:extend({
            UI_CREATE = function(cx)
                vim.keymap.set("n", "<leader>hs", function()
                    vim.cmd("w")
                end, { buffer = cx.bufnr, desc = "Save Quick List" })
            end,
        })
    end
}
