vim.env.OLLAMA_HOST = "http://192.168.2.7:11434"

return {
    "olimorris/codecompanion.nvim",
    lazy = false,
    priority = 100,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "hrsh7th/nvim-cmp",
        "nvim-telescope/telescope.nvim",
        {
            "stevearc/dressing.nvim",
            opts = {},
        },
    },
    init = function()
        vim.env.OLLAMA_HOST = "http://192.168.2.7:11434"
    end,
    config = function()
        -- Store current model
        local current_model = "qwen3-coder:16k"

        require("codecompanion").setup({
            strategies = {
                chat = {
                    adapter = "ollama",
                    roles = {
                        llm = "Ollama",
                        user = "You",
                    },
                    variables = {
                        ["buffer"] = {
                            callback = "helpers.variables.buffer",
                            description = "Share the current buffer with the LLM",
                            opts = {
                                has_params = true,
                            },
                        },
                        ["editor"] = {
                            callback = "helpers.variables.editor",
                            description = "Share the code that you see in Neovim",
                        },
                    },
                },
                inline = {
                    adapter = "ollama",
                },
                agent = {
                    adapter = "ollama",
                },
            },

            adapters = {
                http = {
                    ollama = function()
                        return require("codecompanion.adapters").extend("ollama", {
                            url = "http://192.168.2.7:11434/api/chat",
                            env = {
                                url = "http://192.168.2.7:11434",
                            },
                            raw = {
                                "--silent",
                                "--no-buffer",
                            },
                            schema = {
                                model = {
                                    default = current_model,
                                },
                                num_ctx = {
                                    default = 16384,
                                },
                                num_predict = {
                                    default = -1,
                                },
                                temperature = {
                                    default = 0.7,
                                },
                                top_p = {
                                    default = 0.9,
                                },
                                stream = {
                                    default = true,
                                },
                            },
                        })
                    end,
                    opts = {
                        allow_insecure = false,
                        proxy = nil,
                    },
                },
            },

            display = {
                action_palette = {
                    width = 95,
                    height = 10,
                },
                chat = {
                    window = {
                        layout = "vertical",
                        border = "rounded",
                        height = 0.8,
                        width = 0.45,
                        relative = "editor",
                        opts = {
                            breakindent = true,
                            cursorcolumn = false,
                            cursorline = false,
                            foldcolumn = "0",
                            linebreak = true,
                            list = false,
                            signcolumn = "no",
                            spell = false,
                            wrap = true,
                        },
                    },
                    intro_message = "Welcome! Ask me anything or use @ to add context.",
                    show_settings = true,
                    show_token_count = true,
                },
                diff = {
                    enabled = true,
                    provider = "mini_diff",
                },
                inline = {
                    diff = {
                        enabled = true,
                    },
                },
            },

            prompt_library = {
                ["Custom Prompt"] = {
                    strategy = "chat",
                    description = "Create your own custom prompt",
                    opts = {
                        index = 1,
                        is_default = true,
                        is_slash_cmd = false,
                        short_name = "custom",
                        auto_submit = false,
                    },
                    prompts = {
                        {
                            role = "system",
                            content = "You are an expert programmer. Respond concisely and accurately.",
                        },
                    },
                },
                ["Code Expert"] = {
                    strategy = "chat",
                    description = "Get help with code",
                    opts = {
                        index = 2,
                        is_slash_cmd = false,
                        short_name = "expert",
                        auto_submit = false,
                    },
                    prompts = {
                        {
                            role = "system",
                            content =
                            "You are a senior software engineer specializing in clean code, best practices, and optimization. Provide clear, concise explanations with code examples when relevant.",
                        },
                    },
                },
                ["Explain Code"] = {
                    strategy = "chat",
                    description = "Explain how selected code works",
                    opts = {
                        index = 3,
                        is_slash_cmd = false,
                        short_name = "explain",
                        modes = { "v" },
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content =
                            "Explain the following code in detail, including what it does, how it works, and any important concepts:",
                        },
                        {
                            role = "user",
                            content = function(context)
                                local code = require("codecompanion.helpers.actions").get_code(
                                    context.start_line,
                                    context.end_line
                                )
                                return "```" .. context.filetype .. "\n" .. code .. "\n```"
                            end,
                        },
                    },
                },
                ["Fix Code"] = {
                    strategy = "inline",
                    description = "Fix bugs in selected code",
                    opts = {
                        index = 4,
                        is_slash_cmd = false,
                        short_name = "fix",
                        modes = { "v" },
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content =
                            "You are an expert debugger. Fix any bugs or errors in the code. Return ONLY the corrected code without explanations or markdown formatting.",
                        },
                        {
                            role = "user",
                            content = function(context)
                                local code = require("codecompanion.helpers.actions").get_code(
                                    context.start_line,
                                    context.end_line
                                )
                                return code
                            end,
                        },
                    },
                },
                ["Optimize Code"] = {
                    strategy = "inline",
                    description = "Optimize selected code for performance",
                    opts = {
                        index = 5,
                        is_slash_cmd = false,
                        short_name = "optimize",
                        modes = { "v" },
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content =
                            "You are an expert in code optimization. Improve the performance and efficiency of the code. Return ONLY the optimized code without explanations or markdown formatting.",
                        },
                        {
                            role = "user",
                            content = function(context)
                                local code = require("codecompanion.helpers.actions").get_code(
                                    context.start_line,
                                    context.end_line
                                )
                                return code
                            end,
                        },
                    },
                },
                ["Add Comments"] = {
                    strategy = "inline",
                    description = "Add helpful comments to code",
                    opts = {
                        index = 6,
                        is_slash_cmd = false,
                        short_name = "comment",
                        modes = { "v" },
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content =
                            "Add clear, helpful comments to the code explaining what it does. Return ONLY the code with added comments, no explanations or markdown formatting.",
                        },
                        {
                            role = "user",
                            content = function(context)
                                local code = require("codecompanion.helpers.actions").get_code(
                                    context.start_line,
                                    context.end_line
                                )
                                return code
                            end,
                        },
                    },
                },
                ["Generate Tests"] = {
                    strategy = "chat",
                    description = "Generate unit tests for code",
                    opts = {
                        index = 7,
                        is_slash_cmd = false,
                        short_name = "tests",
                        modes = { "v" },
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content =
                            "Generate comprehensive unit tests for the provided code. Include edge cases and follow testing best practices for the language.",
                        },
                        {
                            role = "user",
                            content = function(context)
                                local code = require("codecompanion.helpers.actions").get_code(
                                    context.start_line,
                                    context.end_line
                                )
                                return "```" .. context.filetype .. "\n" .. code .. "\n```"
                            end,
                        },
                    },
                },
                ["Refactor Code"] = {
                    strategy = "inline",
                    description = "Refactor code for better readability",
                    opts = {
                        index = 8,
                        is_slash_cmd = false,
                        short_name = "refactor",
                        modes = { "v" },
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content =
                            "Refactor the code to improve readability, maintainability, and follow best practices. Return ONLY the refactored code without explanations or markdown formatting.",
                        },
                        {
                            role = "user",
                            content = function(context)
                                local code = require("codecompanion.helpers.actions").get_code(
                                    context.start_line,
                                    context.end_line
                                )
                                return code
                            end,
                        },
                    },
                },
                ["Generate Docs"] = {
                    strategy = "inline",
                    description = "Generate documentation for code",
                    opts = {
                        index = 9,
                        is_slash_cmd = false,
                        short_name = "docs",
                        modes = { "v" },
                        auto_submit = true,
                    },
                    prompts = {
                        {
                            role = "system",
                            content = function(context)
                                local doc_style = "JSDoc"
                                if context.filetype == "python" then
                                    doc_style = "docstring"
                                elseif context.filetype == "lua" then
                                    doc_style = "LuaDoc"
                                elseif context.filetype == "rust" then
                                    doc_style = "rustdoc"
                                end
                                return "Generate proper " ..
                                    doc_style ..
                                    " documentation for the code. Return ONLY the code with documentation added, no explanations or markdown formatting."
                            end,
                        },
                        {
                            role = "user",
                            content = function(context)
                                local code = require("codecompanion.helpers.actions").get_code(
                                    context.start_line,
                                    context.end_line
                                )
                                return code
                            end,
                        },
                    },
                },
            },

            inline = {
                diff = {
                    enabled = true,
                },
            },

            opts = {
                log_level = "ERROR",
                send_code = true,
                use_default_actions = true,
                use_default_prompt_library = false,
                silence_notifications = false,
            },
        })

        -- Model switching function
        local function switch_model()
            local models = {
                "qwen3-coder:32k",
                "qwen3-coder:16k",
                "llama3.1:latest",
                "gemma3:12b",
                "deepseek-r1:32b",
            }

            -- Find current model index
            local current_index = 1
            for i, model in ipairs(models) do
                if model == current_model then
                    current_index = i
                    break
                end
            end

            -- Cycle to next model
            local next_index = current_index % #models + 1
            current_model = models[next_index]

            -- Show notification
            vim.notify("Switched to model: " .. current_model, vim.log.levels.INFO)
        end

        -- Create user command for model switching
        vim.api.nvim_create_user_command("CodeCompanionSwitchModel", switch_model, {
            desc = "Switch Ollama model"
        })

        -- Set up keymap for model switching
        vim.keymap.set("n", "<leader>om", switch_model, {
            noremap = true,
            silent = true,
            desc = "Switch Ollama model"
        })
    end,

    -- Keybindings
    keys = {
        -- Chat interface
        {
            "<leader>oo",
            "<cmd>CodeCompanionActions<cr><ESC>",
            mode = { "n", "v" },
            desc = "AI Actions",
        },
        {
            "<leader>oc",
            "<cmd>CodeCompanionChat Toggle<cr>",
            mode = { "n", "v" },
            desc = "AI Chat",
        },
        {
            "<leader>oC",
            "<cmd>CodeCompanionChat Add<cr>",
            mode = "v",
            desc = "AI Chat (Add Selection)",
        },

        -- Inline assistance
        {
            "<leader>oi",
            "<cmd>CodeCompanion<cr>",
            mode = { "n", "v" },
            desc = "AI Inline",
        },

        -- Quick prompts
        {
            "<leader>oe",
            function()
                require("codecompanion").prompt("explain")
            end,
            mode = "v",
            desc = "AI Explain",
        },
        {
            "<leader>of",
            function()
                require("codecompanion").prompt("fix")
            end,
            mode = "v",
            desc = "AI Fix",
        },
        {
            "<leader>op",
            function()
                require("codecompanion").prompt("optimize")
            end,
            mode = "v",
            desc = "AI Optimize",
        },
        {
            "<leader>ot",
            function()
                require("codecompanion").prompt("tests")
            end,
            mode = "v",
            desc = "AI Tests",
        },
        {
            "<leader>od",
            function()
                require("codecompanion").prompt("docs")
            end,
            mode = "v",
            desc = "AI Docs",
        },
        {
            "<leader>or",
            function()
                require("codecompanion").prompt("refactor")
            end,
            mode = "v",
            desc = "AI Refactor",
        },
    },
}
