return {
    "ahmedkhalf/project.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
        require("project_nvim").setup({
            detection_methods = { "lsp", "pattern" },
            patterns = {
                ".git", "compile_commands.json", "Makefile",
                "package.json", ".luarc.json", "pyproject.toml",
            },
        })
        require("telescope").load_extension("projects")

        vim.keymap.set("n", "<leader>fj", "<cmd>Telescope projects<cr>",
            { desc = "Projects" })
    end,
}
