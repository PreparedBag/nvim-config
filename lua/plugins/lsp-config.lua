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
            -- Helper function to enable autocomplete
            local function enable_autocomplete()
                local cmp = require('cmp')
                cmp.setup({ completion = { autocomplete = { "TextChanged" } } })
            end

            -- Helper function to disable autocomplete
            local function disable_autocomplete()
                local cmp = require('cmp')
                cmp.setup({ completion = { autocomplete = {} } })
            end

            -- Shared helper functions
            local function find_project_root()
                local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
                if vim.v.shell_error == 0 and git_root ~= "" then
                    return git_root
                end
                return vim.fn.getcwd()
            end

            local function find_c_files(root)
                local c_files = {}
                local find_cmd = string.format("find '%s' -type f -name '*.c' 2>/dev/null", root)
                local handle = io.popen(find_cmd)
                if handle then
                    for file in handle:lines() do
                        table.insert(c_files, file)
                    end
                    handle:close()
                end
                return c_files
            end

            local function write_compile_commands(root, commands)
                local output_file = root .. "/compile_commands.json"
                local file = io.open(output_file, "w")
                if not file then
                    return nil
                end

                -- Pretty-print JSON manually
                file:write("[\n")
                for i, entry in ipairs(commands) do
                    file:write("  {\n")
                    file:write(string.format('    "directory": "%s",\n', entry.directory:gsub('\\', '\\\\')))
                    file:write(string.format('    "command": "%s",\n', entry.command:gsub('\\', '\\\\')))
                    file:write(string.format('    "file": "%s"\n', entry.file:gsub('\\', '\\\\')))
                    if i < #commands then
                        file:write("  },\n")
                    else
                        file:write("  }\n")
                    end
                end
                file:write("]\n")

                file:close()
                return output_file
            end

            -- <leader>lgc - Generate via CMake
            vim.keymap.set('n', '<leader>lgc', function()
                vim.fn.system("cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build")
                vim.fn.system("ln -sf build/compile_commands.json .")
                vim.cmd("LspRestart")
            end, opts)

            -- <leader>lgw - Generate via west build
            vim.keymap.set('n', '<leader>lgw', function()
                vim.fn.system("west build -t compile_commands")
                vim.cmd("LspRestart")
            end, opts)

            -- <leader>lgg - Generate generic compile_commands.json
            vim.keymap.set('n', '<leader>lgg', function()
                vim.notify("Generating generic compile_commands.json...", vim.log.levels.INFO)

                local root = find_project_root()
                local c_files = find_c_files(root)

                if #c_files == 0 then
                    vim.notify("No .c files found in " .. root, vim.log.levels.WARN)
                    return
                end

                local compile_commands = {}
                local flags = {
                    "-std=c11",
                    "-Wall",
                    "-Wextra",
                    "-I.",
                    "-I" .. root,
                    "-I/usr/include",
                    "-I/usr/local/include",
                }

                for _, file in ipairs(c_files) do
                    local entry = {
                        directory = root,
                        command = "gcc " .. table.concat(flags, " ") .. " -c " .. file,
                        file = file
                    }
                    table.insert(compile_commands, entry)
                end

                local output = write_compile_commands(root, commands)
                if output then
                    vim.notify(string.format("Generated %s with %d entries", output, #c_files), vim.log.levels.INFO)
                    vim.cmd("LspRestart")
                else
                    vim.notify("Failed to write compile_commands.json", vim.log.levels.ERROR)
                end
            end, opts)

            -- <leader>lgz - Generate Zephyr-aware compile_commands.json
            vim.keymap.set('n', '<leader>lgz', function()
                vim.notify("Generating Zephyr compile_commands.json...", vim.log.levels.INFO)

                local root = find_project_root()
                local c_files = find_c_files(root)

                if #c_files == 0 then
                    vim.notify("No .c files found in " .. root, vim.log.levels.WARN)
                    return
                end

                -- Look for Zephyr-specific paths
                local zephyr_base = os.getenv("ZEPHYR_BASE") or (root .. "/zephyr")
                local build_dir = root .. "/build"
                local autoconf_h = build_dir .. "/zephyr/include/generated/autoconf.h"

                local compile_commands = {}
                local flags = {
                    "-std=c11",
                    "-Wall",
                    "-Wextra",
                    "-I.",
                    "-I" .. root,
                    "-I" .. root .. "/include",
                    "-I" .. zephyr_base .. "/include",
                    "-I" .. zephyr_base .. "/include/zephyr",
                    "-I" .. zephyr_base .. "/drivers",
                    "-I" .. zephyr_base .. "/soc",
                    "-I" .. build_dir .. "/zephyr/include/generated",
                    "-I/usr/include",
                    "-I/usr/local/include",
                }

                -- Add Kconfig-generated defines if autoconf.h exists
                if vim.fn.filereadable(autoconf_h) == 1 then
                    table.insert(flags, "-include")
                    table.insert(flags, autoconf_h)
                    vim.notify("Including Kconfig autoconf.h", vim.log.levels.INFO)
                else
                    vim.notify("Warning: autoconf.h not found at " .. autoconf_h, vim.log.levels.WARN)
                end

                for _, file in ipairs(c_files) do
                    local entry = {
                        directory = root,
                        command = "gcc " .. table.concat(flags, " ") .. " -c " .. file,
                        file = file
                    }
                    table.insert(compile_commands, entry)
                end

                local output = write_compile_commands(root, compile_commands)
                if output then
                    vim.notify(string.format("Generated Zephyr %s with %d entries", output, #c_files), vim.log.levels.INFO)
                    vim.cmd("LspRestart")
                else
                    vim.notify("Failed to write compile_commands.json", vim.log.levels.ERROR)
                end
            end, opts)

            -- Track signature help window state
            local signature_active = true

            -- Helper function to check if buffer should have LSP attached
            local function is_valid_lsp_buffer(bufnr)
                local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
                local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

                -- Skip special buffer types
                if buftype ~= '' then
                    return false
                end

                -- Skip certain filetypes that shouldn't have LSP
                local excluded_filetypes = {
                    'oil',
                    'help',
                    'qf',
                    'netrw',
                    'man',
                    'lazy',
                    'mason',
                }

                for _, ft in ipairs(excluded_filetypes) do
                    if filetype == ft then
                        return false
                    end
                end

                return true
            end

            -- LSP on_attach callback - sets up buffer-local keymaps
            local on_attach = function(client, bufnr)
                -- Only attach to valid file buffers
                if not is_valid_lsp_buffer(bufnr) then
                    vim.lsp.buf_detach_client(bufnr, client.id)
                    return
                end

                local opts = { noremap = true, silent = true, buffer = bufnr }

                -- Code action
                vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, opts)

                -- Diagnostic float
                vim.keymap.set('n', '<leader>ld', vim.diagnostic.open_float, opts)

                -- Diagnostic function to check LSP configuration for C/C++ macro/static definitions
                -- vim.keymap.set('n', '<leader>ld', function()
                --     local bufnr = vim.api.nvim_get_current_buf()
                --     local clients = vim.lsp.get_clients({ bufnr = bufnr })
                --
                --     if #clients == 0 then
                --         vim.notify("No LSP client attached", vim.log.levels.WARN)
                --         return
                --     end
                --
                --     vim.notify("=== LSP Diagnostic Info ===", vim.log.levels.INFO)
                --
                --     for _, client in ipairs(clients) do
                --         vim.notify(string.format("\nClient: %s", client.name), vim.log.levels.INFO)
                --         vim.notify(string.format("Root dir: %s", client.config.root_dir or "none"), vim.log.levels.INFO)
                --
                --         -- Check for common C/C++ language servers
                --         if client.name == "clangd" then
                --             vim.notify("\nclangd detected - Checking configuration:", vim.log.levels.INFO)
                --             vim.notify("Recommended clangd settings for macros:", vim.log.levels.INFO)
                --             vim.notify("  --query-driver=<your-gcc-path>", vim.log.levels.INFO)
                --             vim.notify("  --compile-commands-dir=<build-dir>", vim.log.levels.INFO)
                --             vim.notify("  --background-index", vim.log.levels.INFO)
                --             vim.notify("  --completion-style=detailed", vim.log.levels.INFO)
                --
                --         elseif client.name == "ccls" then
                --             vim.notify("\nccls detected - Check .ccls or compile_commands.json", vim.log.levels.INFO)
                --
                --         end
                --
                --         -- Show capabilities
                --         if client.server_capabilities then
                --             vim.notify("\nServer capabilities:", vim.log.levels.INFO)
                --             vim.notify(string.format("  definitionProvider: %s", 
                --                 vim.inspect(client.server_capabilities.definitionProvider)), vim.log.levels.INFO)
                --             vim.notify(string.format("  referencesProvider: %s", 
                --                 vim.inspect(client.server_capabilities.referencesProvider)), vim.log.levels.INFO)
                --         end
                --     end
                --
                --     -- Check for compile_commands.json
                --     local root_dir = clients[1].config.root_dir
                --     if root_dir then
                --         local compile_commands = root_dir .. "/compile_commands.json"
                --         local build_compile_commands = root_dir .. "/build/compile_commands.json"
                --
                --         if vim.fn.filereadable(compile_commands) == 1 then
                --             vim.notify(string.format("\n✓ Found: %s", compile_commands), vim.log.levels.INFO)
                --         elseif vim.fn.filereadable(build_compile_commands) == 1 then
                --             vim.notify(string.format("\n✓ Found: %s", build_compile_commands), vim.log.levels.INFO)
                --         else
                --             vim.notify("\n✗ compile_commands.json not found!", vim.log.levels.WARN)
                --             vim.notify("Generate it with: cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON", vim.log.levels.INFO)
                --         end
                --     end
                --
                --     -- Check current file
                --     local filepath = vim.api.nvim_buf_get_name(bufnr)
                --     vim.notify(string.format("\nCurrent file: %s", filepath), vim.log.levels.INFO)
                --
                --     -- Get word under cursor
                --     local word = vim.fn.expand("<cword>")
                --     vim.notify(string.format("Word under cursor: %s", word), vim.log.levels.INFO)
                --
                -- end, { desc = "LSP diagnostics for macro/static definitions" })

                -- Common fixes for missing macro/static definitions:
                --
                -- 1. FOR CLANGD:
                --    Add to your LSP config:
                --    ```lua
                --    require('lspconfig').clangd.setup({
                --        cmd = {
                --            "clangd",
                --            "--background-index",
                --            "--clang-tidy",
                --            "--completion-style=detailed",
                --            "--header-insertion=never",
                --            "--query-driver=/path/to/your/gcc",  -- Important for system headers
                --        },
                --        root_dir = require('lspconfig.util').root_pattern(
                --            'compile_commands.json',
                --            '.clangd',
                --            '.git'
                --        ),
                --    })
                --    ```
                --
                -- 2. GENERATE compile_commands.json:
                --    For CMake projects:
                --    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build
                --    
                --    For Zephyr/West projects:
                --    west build -t compile_commands.json
                --    
                --    Then symlink to project root:
                --    ln -s build/compile_commands.json compile_commands.json
                --
                -- 3. CREATE .clangd configuration file in project root:
                --    ```yaml
                --    CompileFlags:
                --      Add: 
                --        - "-I/path/to/include/dirs"
                --        - "-DCONFIG_NET_SAMPLE_NUM_WEBSOCKET_HANDLERS=4"  # Define missing macros
                --      Remove: 
                --        - "-m*"  # Remove machine-specific flags if needed
                --    ```
                --
                -- 4. FOR ZEPHYR PROJECTS specifically:
                --    Make sure clangd can find your Kconfig options:
                --    - The compile_commands.json should include -include autoconf.h
                --    - Check that build/zephyr/include/generated/autoconf.h exists
                --
                -- 5. MANUAL DEFINITION SEARCH:
                --    Use ripgrep to find where the macro is defined:
                --    :terminal rg "CONFIG_NET_SAMPLE_NUM_WEBSOCKET_HANDLERS" 

                vim.keymap.set('n', '<C-h>', vim.lsp.buf.signature_help, opts)

                -- Signature help (insert mode - only if not already active)
                vim.keymap.set('i', '<C-h>', function()
                    if not signature_active then
                        vim.lsp.buf.signature_help()
                        signature_active = true
                    end
                end, opts)

                vim.keymap.set("n", "gd", function()
                    local bufnr = vim.api.nvim_get_current_buf()
                    local clients = vim.lsp.get_clients({ bufnr = bufnr })

                    if #clients == 0 then
                        vim.notify("gd: No LSP client attached", vim.log.levels.WARN)
                        return
                    end

                    local client = clients[1]
                    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

                    vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
                        if err then
                            vim.notify(string.format("gd: Error - %s", vim.inspect(err)), vim.log.levels.ERROR)
                            return
                        end

                        if result == nil or vim.tbl_isempty(result) then 
                            vim.notify("gd: No definition found", vim.log.levels.WARN)
                            return 
                        end

                        if vim.islist(result) then
                            vim.notify(string.format("gd: Jumping to first of %d result(s)", #result), vim.log.levels.INFO)
                            vim.lsp.util.show_document(result[1], client.offset_encoding, { focus = true })
                        else
                            vim.notify("gd: Jumping to single result", vim.log.levels.INFO)
                            vim.lsp.util.show_document(result, client.offset_encoding, { focus = true })
                        end
                    end)
                end, opts)

                -- LSP references via Telescope with fallback to ripgrep
                vim.keymap.set('n', '<leader>lr', function()
                    vim.notify("lr: Starting references lookup", vim.log.levels.INFO)

                    -- Get the first LSP client to retrieve the offset encoding
                    local bufnr = vim.api.nvim_get_current_buf()
                    local clients = vim.lsp.get_clients({ bufnr = bufnr })

                    if #clients == 0 then
                        vim.notify("lr: No LSP client attached", vim.log.levels.WARN)
                        return
                    end

                    -- Use the first client's offset encoding
                    local client = clients[1]
                    local word = vim.fn.expand("<cword>")

                    vim.notify(string.format("lr: Using client '%s' with encoding '%s'", 
                        client.name, client.offset_encoding), vim.log.levels.INFO)
                    vim.notify(string.format("lr: Searching for '%s'", word), vim.log.levels.INFO)

                    -- Try LSP references first
                    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

                    vim.lsp.buf_request(0, "textDocument/references", params, function(err, result, ctx, config)
                        if err then
                            vim.notify(string.format("lr: LSP error - %s", vim.inspect(err)), vim.log.levels.ERROR)
                            return
                        end

                        if result == nil or vim.tbl_isempty(result) then
                            vim.notify(string.format("lr: No LSP references found for '%s'", word), vim.log.levels.WARN)
                            vim.notify("lr: Falling back to ripgrep search...", vim.log.levels.INFO)

                            -- Fallback to ripgrep search via Telescope
                            vim.schedule(function()
                                require('telescope.builtin').grep_string({
                                    search = word,
                                    initial_mode = "normal",
                                    prompt_title = string.format("Ripgrep: %s (LSP found nothing)", word),
                                })
                            end)
                            return
                        end

                        vim.notify(string.format("lr: Found %d LSP reference(s)", #result), vim.log.levels.INFO)

                        -- Use Telescope to show LSP results
                        vim.schedule(function()
                            require('telescope.builtin').lsp_references({
                                fname_width = 0,
                                trim_text = true,
                                show_line = true,
                                initial_mode = "normal",
                                offset_encoding = client.offset_encoding,
                            })
                            vim.notify("lr: Telescope picker opened", vim.log.levels.INFO)
                        end)
                    end)
                end, opts)


                -- Alternative: Direct ripgrep search (useful for macros/Kconfig)
                vim.keymap.set('n', '<leader>lR', function()
                    local word = vim.fn.expand("<cword>")
                    vim.notify(string.format("lR: Searching entire project for '%s' with ripgrep", word), vim.log.levels.INFO)

                    require('telescope.builtin').grep_string({
                        search = word,
                        initial_mode = "normal",
                        prompt_title = string.format("Ripgrep: %s", word),
                    })
                end, { desc = "Search project with ripgrep (bypass LSP)" })


                -- Search for macro definitions specifically
                vim.keymap.set('n', '<leader>lm', function()
                    local word = vim.fn.expand("<cword>")
                    vim.notify(string.format("lm: Searching for macro definition of '%s'", word), vim.log.levels.INFO)

                    -- Search for #define or Kconfig patterns
                    require('telescope.builtin').grep_string({
                        search = string.format([[#define\s+%s|config\s+%s]], word, word),
                        use_regex = true,
                        initial_mode = "normal",
                        prompt_title = string.format("Macro Definition: %s", word),
                    })
                end, { desc = "Search for macro/Kconfig definition" })

            end

            -- Global keymaps (not buffer-specific)
            local opts = { noremap = true, silent = true }

            -- <leader>lc - Stop LSP clients and disable autocomplete entirely
            vim.keymap.set('n', '<leader>lc', function()
                -- Stop all LSP clients for the current buffer
                local bufnr = vim.api.nvim_get_current_buf()
                local clients = vim.lsp.get_clients({ bufnr = bufnr })

                for _, client in ipairs(clients) do
                    vim.lsp.stop_client(client.id)
                end

                -- Disable autocomplete
                disable_autocomplete()

                -- Clear the command line
                vim.api.nvim_input('<Esc>')

                vim.notify("LSP stopped and autocomplete disabled")
            end, opts)

            -- <leader>ls - Start LSP and enable autocomplete
            vim.keymap.set('n', '<leader>ls', function()
                local ok = pcall(vim.cmd, "edit")
                if not ok then
                    vim.notify("Please save pending changes or discard...", vim.log.levels.WARN)
                    return
                end

                local bufnr = vim.api.nvim_get_current_buf()
                local clients = vim.lsp.get_clients({ bufnr = bufnr })

                for _, client in ipairs(clients) do
                    on_attach(client, bufnr)
                end

                enable_autocomplete()
                vim.notify("LSP started and autocomplete enabled")
            end, opts)

            -- Track signature help window state
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

            -- Re-enable autocomplete when switching buffers (for split navigation)
            vim.api.nvim_create_autocmd("BufEnter", {
                callback = function()
                    local bufnr = vim.api.nvim_get_current_buf()
                    local clients = vim.lsp.get_clients({ bufnr = bufnr })

                    -- Only re-enable if LSP is attached to this buffer
                    if #clients > 0 then
                        enable_autocomplete()
                    end
                end,
            })

            -- Setup all LSP servers using the new vim.lsp.config API (Neovim 0.11+)
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local servers = { "clangd", "pyright", "lua_ls", "ts_ls", "html", "cssls" }

            -- HTML LSP with specific settings
            vim.lsp.config.html = {
                cmd = { 'vscode-html-language-server', '--stdio' },
                filetypes = { 'html' },
                root_markers = { '.git' },
                settings = {
                    css = { validate = false },
                    less = { validate = false },
                    scss = { validate = false },
                },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            -- Setup remaining LSP servers
            vim.lsp.config.clangd = {
                cmd = { 'clangd' },
                filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
                root_markers = { '.git' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.pyright = {
                cmd = { 'pyright-langserver', '--stdio' },
                filetypes = { 'python' },
                root_markers = { '.git', 'pyproject.toml', 'setup.py' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.lua_ls = {
                cmd = { 'lua-language-server' },
                filetypes = { 'lua' },
                root_markers = { '.git', '.luarc.json' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.ts_ls = {
                cmd = { 'typescript-language-server', '--stdio' },
                filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
                root_markers = { '.git', 'package.json' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.config.cssls = {
                cmd = { 'vscode-css-language-server', '--stdio' },
                filetypes = { 'css', 'scss', 'less' },
                root_markers = { '.git' },
                on_attach = on_attach,
                capabilities = capabilities,
            }

            -- Use mason-lspconfig handlers to enable LSP without triggering deprecated API
            require("mason-lspconfig").setup({
                ensure_installed = servers,
                handlers = {
                    -- Default handler that enables LSP servers
                    function(server_name)
                        vim.lsp.enable(server_name)
                    end,
                }
            })
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
                completion = {
                    autocomplete = { "TextChanged" }
                }
            })
        end
    }
}
