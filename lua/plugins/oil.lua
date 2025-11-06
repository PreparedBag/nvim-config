return {
    'stevearc/oil.nvim',
    dependencies = { "echasnovski/mini.icons" },
    config = function()
        local oil = require("oil")
        oil.setup()

        -- Open Oil with <leader>fe
        vim.keymap.set("n", "<leader>fe", ":Oil<CR>", { noremap = true, silent = true })

        -- In Oil buffers, make <leader>r refresh
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "oil",
            callback = function(event)
                local actions = require("oil.actions")
                vim.keymap.set(
                    "n",
                    "<leader>r",
                    actions.refresh.callback,
                    { buffer = event.buf, silent = true, desc = "Refresh Oil" }
                )
            end,
        })
    end,
}
