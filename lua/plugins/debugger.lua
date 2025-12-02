-- nvim-debugger.lua
-- Complete debugger setup for Neovim with DAP
--
-- INSTALLATION:
-- Place this file in: ~/.config/nvim/lua/plugins/debugger.lua
-- (lazy.nvim will automatically load all files in lua/plugins/)
--
-- Or in your main lazy.nvim setup, add: require('plugins.debugger')

return {
    'mfussenegger/nvim-dap',
    dependencies = {
        'rcarriga/nvim-dap-ui',
        'nvim-neotest/nvim-nio',
        'theHamsta/nvim-dap-virtual-text',
    },
    config = function()
        local dap = require('dap')
        local dapui = require('dapui')
        local dapvt = require('nvim-dap-virtual-text')

        -- ============================================================================
        -- DAP VIRTUAL TEXT SETUP
        -- ============================================================================
        dapvt.setup({
            enabled = true,
            enabled_commands = true,
            highlight_changed_variables = true,
            highlight_new_as_changed = false,
            show_stop_reason = true,
            commented = false,
            only_first_definition = true,
            all_references = false,
            filter_references_pattern = '<module',
            virt_text_pos = 'eol',
            all_frames = false,
            virt_lines = false,
            virt_text_win_col = nil,
        })

        -- ============================================================================
        -- DAP UI SETUP
        -- ============================================================================
        dapui.setup({
            icons = { expanded = '▾', collapsed = '▸', current_frame = '▸' },
            mappings = {
                expand = { '<CR>', '<2-LeftMouse>' },
                open = 'o',
                remove = 'd',
                edit = 'e',
                repl = 'r',
                toggle = 't',
            },
            element_mappings = {},
            expand_lines = vim.fn.has('nvim-0.7') == 1,
            layouts = {
                {
                    elements = {
                        { id = 'scopes',      size = 0.25 },
                        { id = 'breakpoints', size = 0.25 },
                        { id = 'stacks',      size = 0.25 },
                        { id = 'watches',     size = 0.25 },
                    },
                    size = 40,
                    position = 'left',
                },
                {
                    elements = {
                        { id = 'repl',    size = 0.5 },
                        { id = 'console', size = 0.5 },
                    },
                    size = 10,
                    position = 'bottom',
                },
            },
            controls = {
                enabled = true,
                element = 'repl',
                icons = {
                    pause = '⏸',
                    play = '▶',
                    step_into = '⏎',
                    step_over = '⏭',
                    step_out = '⏮',
                    step_back = 'b',
                    run_last = '▶▶',
                    terminate = '⏹',
                    disconnect = '⏏',
                },
            },
            floating = {
                max_height = nil,
                max_width = nil,
                border = 'single',
                mappings = {
                    close = { 'q', '<Esc>' },
                },
            },
            windows = { indent = 1 },
            render = {
                max_type_length = nil,
                max_value_lines = 100,
            },
        })

        -- ============================================================================
        -- AUTO OPEN/CLOSE UI
        -- ============================================================================
        dap.listeners.after.event_initialized['dapui_config'] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated['dapui_config'] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited['dapui_config'] = function()
            dapui.close()
        end

        -- ============================================================================
        -- SIGNS AND ICONS
        -- ============================================================================
        vim.fn.sign_define('DapBreakpoint', {
            text = '🔴',
            texthl = 'DapBreakpoint',
            linehl = '',
            numhl = '',
        })
        vim.fn.sign_define('DapBreakpointCondition', {
            text = '🟡',
            texthl = 'DapBreakpoint',
            linehl = '',
            numhl = '',
        })
        vim.fn.sign_define('DapBreakpointRejected', {
            text = '🚫',
            texthl = 'DapBreakpoint',
            linehl = '',
            numhl = '',
        })
        vim.fn.sign_define('DapStopped', {
            text = '▶️',
            texthl = 'DapStopped',
            linehl = 'debugPC',
            numhl = '',
        })
        vim.fn.sign_define('DapLogPoint', {
            text = '📝',
            texthl = 'DapLogPoint',
            linehl = '',
            numhl = '',
        })

        -- ============================================================================
        -- KEY MAPPINGS
        -- ============================================================================
        local keymap = vim.keymap.set
        local opts = { noremap = true, silent = true }

        -- Breakpoint management
        keymap('n', '<Leader>db', dap.toggle_breakpoint, vim.tbl_extend('force', opts, { desc = 'Toggle Breakpoint' }))
        keymap('n', '<Leader>dB', function()
            dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
        end, vim.tbl_extend('force', opts, { desc = 'Conditional Breakpoint' }))
        keymap('n', '<Leader>dL', function()
            dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
        end, vim.tbl_extend('force', opts, { desc = 'Log Point' }))

        -- Session control
        keymap('n', '<Leader>dc', dap.continue, vim.tbl_extend('force', opts, { desc = 'Continue/Start' }))
        keymap('n', '<Leader>dC', dap.run_to_cursor, vim.tbl_extend('force', opts, { desc = 'Run to Cursor' }))
        keymap('n', '<Leader>dt', dap.terminate, vim.tbl_extend('force', opts, { desc = 'Terminate' }))
        keymap('n', '<Leader>dd', dap.disconnect, vim.tbl_extend('force', opts, { desc = 'Disconnect' }))
        keymap('n', '<Leader>dR', dap.restart, vim.tbl_extend('force', opts, { desc = 'Restart' }))

        -- Stepping
        keymap('n', '<Leader>di', dap.step_into, vim.tbl_extend('force', opts, { desc = 'Step Into' }))
        keymap('n', '<Leader>do', dap.step_over, vim.tbl_extend('force', opts, { desc = 'Step Over' }))
        keymap('n', '<Leader>dO', dap.step_out, vim.tbl_extend('force', opts, { desc = 'Step Out' }))
        keymap('n', '<Leader>dh', dap.step_back, vim.tbl_extend('force', opts, { desc = 'Step Back' }))
        keymap('n', '<Leader>dp', dap.pause, vim.tbl_extend('force', opts, { desc = 'Pause' }))

        -- UI controls
        keymap('n', '<Leader>du', dapui.toggle, vim.tbl_extend('force', opts, { desc = 'Toggle UI' }))
        keymap('n', '<Leader>de', dapui.eval, vim.tbl_extend('force', opts, { desc = 'Evaluate' }))
        keymap('v', '<Leader>de', dapui.eval, vim.tbl_extend('force', opts, { desc = 'Evaluate Selection' }))
        keymap('n', '<Leader>df', function()
            dapui.float_element()
        end, vim.tbl_extend('force', opts, { desc = 'Float Element' }))

        -- REPL and utilities
        keymap('n', '<Leader>dr', dap.repl.open, vim.tbl_extend('force', opts, { desc = 'Open REPL' }))
        keymap('n', '<Leader>dl', dap.run_last, vim.tbl_extend('force', opts, { desc = 'Run Last' }))
        keymap('n', '<Leader>dk', function()
            dap.up()
        end, vim.tbl_extend('force', opts, { desc = 'Up Stack Frame' }))
        keymap('n', '<Leader>dj', function()
            dap.down()
        end, vim.tbl_extend('force', opts, { desc = 'Down Stack Frame' }))

        -- Breakpoint list
        keymap('n', '<Leader>dq', function()
            require('dap').list_breakpoints()
        end, vim.tbl_extend('force', opts, { desc = 'List Breakpoints' }))
        keymap('n', '<Leader>dx', function()
            require('dap').clear_breakpoints()
        end, vim.tbl_extend('force', opts, { desc = 'Clear All Breakpoints' }))

        -- ============================================================================
        -- DEBUG ADAPTER CONFIGURATIONS
        -- ============================================================================

        -- GDB Adapter (for native C/C++ debugging and embedded/JTAG)
        dap.adapters.gdb = {
            type = 'executable',
            command = 'gdb',
            args = { '-i', 'dap' },
        }

        -- Alternative GDB for ARM embedded
        dap.adapters.arm_gdb = {
            type = 'executable',
            command = 'arm-none-eabi-gdb',
            args = { '-i', 'dap' },
        }

        -- LLDB Adapter (alternative to GDB)
        dap.adapters.lldb = {
            type = 'executable',
            command = 'lldb-vscode',
            name = 'lldb',
        }

        -- ============================================================================
        -- C/C++ CONFIGURATIONS
        -- ============================================================================
        dap.configurations.c = {
            -- Local debugging
            {
                name = 'Launch (GDB)',
                type = 'gdb',
                request = 'launch',
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopAtBeginningOfMainSubprogram = false,
            },

            -- Remote debugging (OpenOCD/JTAG)
            {
                name = 'Attach to OpenOCD (localhost:3333)',
                type = 'gdb',
                request = 'attach',
                target = 'localhost:3333',
                cwd = '${workspaceFolder}',
                program = function()
                    return vim.fn.input('Path to ELF: ', vim.fn.getcwd() .. '/', 'file')
                end,
            },

            -- ARM embedded with custom GDB
            {
                name = 'Attach to ARM Target (OpenOCD)',
                type = 'arm_gdb',
                request = 'attach',
                target = 'localhost:3333',
                cwd = '${workspaceFolder}',
                program = function()
                    return vim.fn.input('Path to ELF: ', vim.fn.getcwd() .. '/', 'file')
                end,
            },

            -- Custom remote target
            {
                name = 'Attach to Remote GDB Server',
                type = 'gdb',
                request = 'attach',
                target = function()
                    local host = vim.fn.input('Remote host: ', 'localhost')
                    local port = vim.fn.input('Remote port: ', '3333')
                    return host .. ':' .. port
                end,
                cwd = '${workspaceFolder}',
                program = function()
                    return vim.fn.input('Path to ELF: ', vim.fn.getcwd() .. '/', 'file')
                end,
            },

            -- Attach to running process
            {
                name = 'Attach to Process',
                type = 'gdb',
                request = 'attach',
                pid = function()
                    local handle = io.popen('ps aux | grep -v grep | awk \'{print $2 " " $11}\'')
                    local result = handle:read('*a')
                    handle:close()
                    local pid = vim.fn.input('PID: ', result)
                    return tonumber(pid)
                end,
                cwd = '${workspaceFolder}',
            },
        }

        -- Use same configurations for C++
        dap.configurations.cpp = dap.configurations.c

        -- ============================================================================
        -- RUST CONFIGURATION
        -- ============================================================================
        dap.configurations.rust = {
            {
                name = 'Launch (LLDB)',
                type = 'lldb',
                request = 'launch',
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
                args = {},
            },
        }

        -- ============================================================================
        -- PYTHON CONFIGURATION (requires debugpy)
        -- ============================================================================
        dap.adapters.python = {
            type = 'executable',
            command = 'python',
            args = { '-m', 'debugpy.adapter' },
        }

        dap.configurations.python = {
            {
                type = 'python',
                request = 'launch',
                name = 'Launch file',
                program = '${file}',
                pythonPath = function()
                    return '/usr/bin/python'
                end,
            },
        }

        vim.notify('DAP configured successfully!', vim.log.levels.INFO)
    end,
}
