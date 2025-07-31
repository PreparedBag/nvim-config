return {
    {
        "williamboman/mason.nvim",
        event = "BufReadPre",
        config = function()
            require("mason").setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "neovim/nvim-lspconfig" },
        config = function()
            local servers = { "clangd", "pyright", "lua_ls", "ts_ls", "html", "cssls" }
            require("mason-lspconfig").setup({
                ensure_installed = servers
            })
            local lspconfig = require("lspconfig")
            lspconfig.html.setup({
                settings = {
                    css = { validate = false },
                    less = { validate = false },
                    scss = { validate = false },
                }
            })

            local signature_active = true
            local on_attach = function(_, bufnr)
                local opts = { noremap = true, silent = true, buffer = bufnr }
                vim.keymap.set("n", "gd", function()
                    local params = vim.lsp.util.make_position_params()
                    vim.lsp.buf_request(0, "textDocument/definition", params, function(_, result)
                        if result == nil or vim.tbl_isempty(result) then return end
                        if vim.tbl_islist(result) then
                            vim.lsp.util.jump_to_location(result[1], "utf-8")
                        else
                            vim.lsp.util.jump_to_location(result, "utf-8")
                        end
                    end)
                end, opts)
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, opts)
                vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, opts)
                vim.keymap.set('n', '<leader>lc', function()
                    vim.lsp.stop_client(vim.lsp.get_active_clients({ bufnr = 0 }))
                end, opts)
                vim.keymap.set('n', '<leader>ls', function()
                    vim.cmd("edit")
                end, opts)
                vim.keymap.set('n', '<C-h>', vim.lsp.buf.signature_help, opts)
                vim.keymap.set('i', '<C-h>', function()
                    if not signature_active then
                        vim.lsp.buf.signature_help()
                        signature_active = true
                    end
                end, opts)
                vim.keymap.set('n', '<leader>lt', function()
                    local cmp = require('cmp')
                    local cfg = cmp.get_config()
                    local auto = cfg.completion.autocomplete or {}
                    local is_enabled = vim.tbl_contains(auto, "TextChanged")
                    local new_value = is_enabled and {} or { "TextChanged" }
                    cmp.setup({ completion = { autocomplete = new_value } })
                    require("noice").notify("Autocomplete " .. (is_enabled and "disabled" or "enabled"))
                end, { noremap = true, silent = true, desc = "Toggle Autocomplete" })
                vim.keymap.set('n', '<leader>lr', function()
                    require('telescope.builtin').lsp_references {
                        fname_width = 0,
                        trim_text = true,
                        show_line = true,
                        initial_mode = "normal",
                    }
                end, opts)
            end

            vim.api.nvim_create_autocmd({ "InsertCharPre", "CursorMoved" }, {
                callback = function()
                    local active = false
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local config = vim.api.nvim_win_get_config(win)
                        if config.relative == "cursor" and config.anchor == "NW" then
                            active = true
                            break
                        end
                    end
                    signature_active = active
                end,
            })

            for _, server in ipairs(servers) do
                local capabilities = require("cmp_nvim_lsp").default_capabilities()
                lspconfig[server].setup({
                    on_attach = on_attach,
                    capabilities = capabilities,
                })
            end
        end
    },
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            vim.o.completeopt = "menu,menuone,noselect"

            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-j>"] = cmp.mapping.select_next_item(),
                    ["<C-k>"] = cmp.mapping.select_prev_item(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = function()
                        if cmp.visible() then
                            cmp.abort()
                        else
                            cmp.complete()
                        end
                    end,
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp", keyword_length = 1 },
                }),
            })
        end
    }
}
