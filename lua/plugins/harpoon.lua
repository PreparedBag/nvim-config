return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>ha", function() require("harpoon"):list():add() end,    desc = "Add to Harpoon" },
        {
            "<leader>he",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(harpoon:list(), {
                    title = "",
                    title_pos = "center",
                })
            end,
            desc = "Harpoon Menu"
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

        -- attach a buffer-local save map when the quick menu opens
        harpoon:extend({
            UI_CREATE = function(cx)
                -- ---------------------------------------------------
                -- option A: reuse harpoon's own :w write handler
                -- ---------------------------------------------------
                vim.keymap.set("n", "<leader>hs", function()
                    vim.cmd("w")
                end, { buffer = cx.bufnr, desc = "Save Quick List" })

                -- ---------------------------------------------------
                -- option B: resolve buffer lines into the list, sync,
                -- and notify. comment out option A to use this.
                -- ---------------------------------------------------
                -- vim.keymap.set("n", "<leader>hs", function()
                --     harpoon:list():resolve_displayed(
                --         vim.api.nvim_buf_get_lines(cx.bufnr, 0, -1, false)
                --     )
                --     harpoon:sync()
                --     vim.notify("Harpoon list saved", vim.log.levels.INFO)
                -- end, { buffer = cx.bufnr, desc = "Save quick list" })
            end,
        })
    end
}
