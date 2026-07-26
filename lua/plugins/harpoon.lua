return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    keys = {
        { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Add to Harpoon" },
        {
            "<leader>he",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(harpoon:list(), { title = "", title_pos = "center" })
            end,
            desc = "Harpoon Edit (native)",
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
        { "<leader>1", function() require("harpoon"):list():select(1) end },
        { "<leader>2", function() require("harpoon"):list():select(2) end },
        { "<leader>3", function() require("harpoon"):list():select(3) end },
        { "<leader>4", function() require("harpoon"):list():select(4) end },
        { "<leader>5", function() require("harpoon"):list():select(5) end },
        { "<leader>6", function() require("harpoon"):list():select(6) end },
        { "<leader>7", function() require("harpoon"):list():select(7) end },
        { "<leader>8", function() require("harpoon"):list():select(8) end },
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
