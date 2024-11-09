return {
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && yarn install",
        ft = { "markdown" },
        config = function()
            vim.g.mkdp_preview_options = {
                maid = {
                    themeVariables = {
                        darkMode = "false",
                        background = "#ffffff",
                        fontFamily = "Rubik, sans-serif",
                        fontSize = "14px",

                        primaryColor = "#C1D1DD",
                        primaryTextColor = "#222222",
                        primaryBorderColor = "#222222",

                        secondaryColor = "#D4B16A",
                        secondaryTextColor = "#222222",
                        secondaryBorderColor = "#222222",

                        tertiaryColor = "#ffffff",
                        tertiaryTextColor = "#222222",
                        tertiaryBorderColor = "#222222",

                        lineColor = "#0c233f",
                        textColor = "#222222",

                        -- nodeTextColor = "#222222",
                        -- nodeBorder = "#222222",
                        -- mainBkg = "#F3F4F5",
                        -- clusterBkg = "#8092A7", --subgraph background
                        -- clusterBorder = "#222222",
                        -- titleColor = "#222222",
                        edgeLabelBackground = "#ffffff",

                        pie1 = "#A1C1B0",
                        pie2 = "#C1A6A6",
                        pie3 = "#A1A8C1",
                        pie4 = "#B3B8A1",
                        pie5 = "#C1A1B5",
                        pie6 = "#A6B2C1",
                        pie7 = "#9FA8B0",
                        pie8 = "#8C9BA3",
                        pie9 = "#B9A1A1",
                        pie10 = "#C4B29F",
                        pie11 = "#A1BFC1",
                        pie12 = "#C1A8A1"
                    },
                },
            }

            vim.g.mkdp_filetypes = { "markdown" }
            vim.g.mkdp_markdown_css = '/home/sean/.config/nvim/markdown/markdown.css'
            vim.g.mkdp_highlight_css = ''
            vim.g.mkdp_port = '6969'
            vim.g.mkdp_theme = 'light'
            vim.g.mkdp_page_title = '${name}'

            local opts = { noremap = true, silent = true }
            vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<CR>", opts)
        end
    },
    -- { 'dhruvasagar/vim-table-mode' },
}
