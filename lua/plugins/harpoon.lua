return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    keys = {
        { "<leader>ha", function() require("harpoon"):list():add() end,    desc = "Add to Harpoon" },
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
                local list = harpoon:list()
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
                                value = vim.fn.fnamemodify(name, ":."),
                                context = { row = 1, col = 0 },
                            })
                            added = added + 1
                        end
                    end
                end

                vim.notify(("Added %d buffer(s) to Harpoon"):format(added), vim.log.levels.INFO)
            end,
            desc = "Add Buffers to Harpoon",
        },
        {
            "<leader>he",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(harpoon:list(), { title = "", title_pos = "center" })
            end,
            desc = "Harpoon Edit (Native)",
        },
        {
            "<leader>hm",
            function()
                local harpoon = require("harpoon")
                local conf = require("telescope.config").values

                local file_paths = {}
                for _, item in ipairs(harpoon:list().items) do
                    table.insert(file_paths, item.value)
                end

                require("telescope.pickers").new({}, {
                    prompt_title = "Harpoon",
                    initial_mode = "normal",
                    finder = require("telescope.finders").new_table({
                        results = file_paths,
                    }),
                    previewer = conf.file_previewer({}),
                    sorter = conf.generic_sorter({}),
                }):find()
            end,
            desc = "Harpoon Menu (Telescope)",
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
        vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal", bg = "none" })
        vim.api.nvim_set_hl(0, "FloatBorder", { link = "Normal", bg = "none" })

        local harpoon = require("harpoon")
        harpoon:setup({})

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
