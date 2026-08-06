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
                            harpoon:list():add({
                                value = require("config.project").relative_path(vim.loop.cwd(), name),
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

        -- harpoon's default create_list_item normalizes via plenary's
        -- Path:make_relative, which only strips a matching cwd prefix and
        -- falls back to the full absolute path for anything outside cwd
        -- (e.g. a ../shared file). This override computes a genuine
        -- ../-relative path instead, same fix as telescope.lua's
        -- path_display, so <leader>ha stores it correctly too.
        harpoon:setup({
            default = {
                create_list_item = function(config, name)
                    name = name or vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
                    local root = config.get_root_dir()
                    local rel = require("config.project").relative_path(root, name)

                    local bufnr = vim.fn.bufnr(name, false)
                    local pos = { 1, 0 }
                    if bufnr ~= -1 then
                        pos = vim.api.nvim_win_get_cursor(0)
                    end

                    return {
                        value = rel,
                        context = { row = pos[1], col = pos[2] },
                    }
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
