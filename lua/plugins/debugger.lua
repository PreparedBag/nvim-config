return {
    'mfussenegger/nvim-dap',
    dependencies = {
        'rcarriga/nvim-dap-ui',
        'nvim-neotest/nvim-nio',
        'theHamsta/nvim-dap-virtual-text',
        'nvim-telescope/telescope.nvim',
    },

    config = function()
        local dap = require('dap')
        local dapui = require('dapui')
        local dapvt = require('nvim-dap-virtual-text')

        local jlink_job_id = nil
        local selected_elf_path = nil

        -- running | paused | stopped | disconnected
        local dap_run_state = 'disconnected'

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
                        { id = 'breakpoints', size = 0.25 },
                        { id = 'watches',     size = 0.25 },
                        { id = 'scopes',      size = 0.25 },
                        { id = 'stacks',      size = 0.25 },
                    },
                    size = 0.25,
                    position = 'left',
                },
                {
                    elements = {
                        { id = 'repl', size = 1.00 },
                    },
                    size = 15,
                    position = 'bottom',
                },
            },

            -- Controls are disabled (your preference).
            controls = {
                enabled = false,
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
                max_height = 0.9,
                max_width = 0.9,
                border = 'single',
                mappings = {
                    close = { 'q', '<Esc>' },
                },
            },
            windows = { indent = 1 },
            render = {
                max_type_length = 100,
                max_value_lines = 100,
                indent = 1,
            },
        })

        -- ============================================================================
        -- Auto-scroll REPL to bottom on new output
        -- ============================================================================
        dap.listeners.after.event_output['dapui_scroll'] = function()
            vim.schedule(function()
                local repl_wins = vim.fn.win_findbuf(vim.fn.bufnr('dap-repl'))
                for _, win in ipairs(repl_wins) do
                    vim.api.nvim_win_call(win, function()
                        vim.cmd('normal! G')
                    end)
                end
            end)
        end

        -- ============================================================================
        -- Auto open/close UI
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

        -- Clean up DAP UI state when session ends
        dap.listeners.before['event_terminated']['cleanup'] = function()
            vim.cmd('sign unplace *') -- Remove all signs
            -- Reset any special buffer options
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) then
                    pcall(vim.api.nvim_buf_del_var, buf, 'dap_session')
                    -- Clear any DAP-related buffer options
                end
            end
        end

        dap.listeners.before['event_exited']['cleanup'] = function()
            vim.cmd('sign unplace *')
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) then
                    pcall(vim.api.nvim_buf_del_var, buf, 'dap_session')
                end
            end
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
            texthl = 'DapBreakpointRejected',
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
        -- DEBUG ADAPTER CONFIGURATIONS
        -- ============================================================================
        dap.adapters.cppdbg = {
            id = 'cppdbg',
            type = 'executable',
            command = vim.fn.stdpath('data') .. '/mason/bin/OpenDebugAD7',
        }

        -- ============================================================================
        -- REPL-only winbar with realtime state
        -- ============================================================================
        local function style_dap_winbar()
            local ft = vim.bo.filetype

            local titles = {
                dapui_scopes      = 'SCOPES',
                dapui_breakpoints = 'BREAKPOINTS',
                dapui_stacks      = 'STACKS',
                dapui_watches     = 'WATCHES',
                dapui_console     = 'CONSOLE',
                dapui_repl        = 'REPL',
                ['dap-repl']      = 'REPL',
            }

            local base = titles[ft]
            if not base then
                return
            end

            local title = base
            if ft == 'dapui_repl' or ft == 'dap-repl' then
                local session = dap.session()

                local prefix
                if not session then
                    prefix = (dap_run_state == 'stopped') and '⏹  STOPPED — ' or '⛔ DISCONNECTED — '
                else
                    prefix = (dap_run_state == 'running') and '▶ RUNNING — ' or '⏸  PAUSED — '
                end

                title = prefix .. base
            end

            vim.opt_local.winbar = '%=%#DapWinBar# ' .. title .. ' %*%='
            vim.opt_local.winhighlight = 'WinBar:CursorLine,WinBarNC:CursorLine'

            -- UI-only cleanup (don't affect code buffers)
            if ft:match('^dapui_') or ft == 'dap-repl' then
                vim.opt_local.cursorline = false
                vim.opt_local.number = false
                vim.opt_local.relativenumber = false
                vim.opt_local.signcolumn = 'no'
            end
        end

        vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter', 'FileType' }, {
            callback = style_dap_winbar,
        })

        local function refresh_repl_winbar()
            vim.schedule(function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local ft = vim.bo[buf].filetype
                    if ft == 'dapui_repl' or ft == 'dap-repl' then
                        vim.api.nvim_win_call(win, function()
                            style_dap_winbar()
                        end)
                    end
                end
            end)
        end

        local function set_dap_state(state)
            dap_run_state = state
            refresh_repl_winbar()
        end

        -- cpptools sometimes doesn't emit event_continued reliably, so we:
        -- 1) set "paused" on actual stop events
        -- 2) set "running" immediately when we invoke continue/step/run-to-cursor
        dap.listeners.after.event_stopped['repl_state'] = function()
            set_dap_state('paused')
        end
        dap.listeners.before.event_terminated['repl_state'] = function()
            set_dap_state('stopped')
        end
        dap.listeners.before.event_exited['repl_state'] = function()
            set_dap_state('stopped')
        end
        dap.listeners.after.disconnect['repl_state'] = function()
            set_dap_state('disconnected')
        end

        local function dap_mark_running_and(fn)
            return function(...)
                set_dap_state('running')
                return fn(...)
            end
        end

        local function dap_mark_stopped_and(fn)
            return function(...)
                set_dap_state('stopped')
                return fn(...)
            end
        end

        local function dap_mark_disconnected_and(fn)
            return function(...)
                set_dap_state('disconnected')
                return fn(...)
            end
        end

        local dap_continue = dap_mark_running_and(dap.continue)
        local dap_step_into = dap_mark_running_and(dap.step_into)
        local dap_step_over = dap_mark_running_and(dap.step_over)
        local dap_step_out = dap_mark_running_and(dap.step_out)
        local dap_run_to_cursor = dap_mark_running_and(dap.run_to_cursor)

        local dap_disconnect = dap_mark_disconnected_and(dap.disconnect)
        local dap_terminate = dap_mark_stopped_and(dap.terminate)

        -- ============================================================================
        -- Telescope ELF picker
        -- ============================================================================
        local function select_elf_file(cb)
            require('telescope.builtin').find_files({
                prompt_title = 'Select ELF File for Debugging',
                cwd = vim.fn.getcwd(),
                hidden = true,
                find_command = {
                    'rg',
                    '--files',
                    '--hidden',
                    '--no-ignore',
                    '--glob',
                    '!.git/*',
                },
                attach_mappings = function(prompt_bufnr, _)
                    local actions = require('telescope.actions')
                    local action_state = require('telescope.actions.state')

                    actions.select_default:replace(function()
                        actions.close(prompt_bufnr)
                        local selection = action_state.get_selected_entry()
                        if not selection then
                            return
                        end

                        selected_elf_path = selection.path
                        vim.notify('ELF file set to: ' .. selected_elf_path, vim.log.levels.INFO)

                        if cb then
                            vim.defer_fn(function()
                                cb()
                            end, 100)
                        end
                    end)

                    return true
                end,
            })
        end

        -- ============================================================================
        -- Flash ELF via JLinkExe
        -- ============================================================================
        local function flash_elf()
            if not selected_elf_path then
                vim.notify('No ELF selected — please choose one', vim.log.levels.WARN)
                select_elf_file(flash_elf)
                return
            end
            vim.notify('Flashing ' .. selected_elf_path .. '...', vim.log.levels.INFO)
            local script_path = '/tmp/jlink_flash.jlink'
            local script_content = string.format('erase\nloadfile %s\nreset\ngo\nexit\n', selected_elf_path)
            local file = io.open(script_path, 'w')
            if not file then
                vim.notify('Failed to create flash script', vim.log.levels.ERROR)
                return
            end
            file:write(script_content)
            file:close()
            local flash_cmd = {
                'JLinkExe',
                '-device',
                'STM32L071CZ',
                '-if',
                'SWD',
                '-speed',
                '4000',
                '-autoconnect',
                '1',
                '-CommandFile',
                script_path,
            }
            vim.fn.jobstart(flash_cmd, {
                on_exit = function(_, exit_code)
                    if exit_code == 0 then
                        vim.notify('Flash complete!', vim.log.levels.INFO)
                    else
                        vim.notify('Flash failed with code: ' .. exit_code, vim.log.levels.ERROR)
                    end
                    os.remove(script_path)
                end,
                on_stdout = function(_, data)
                    if data then
                        for _, line in ipairs(data) do
                            if line ~= '' then
                                print(line)
                            end
                        end
                    end
                end,
            })
        end

        -- ============================================================================
        -- Start/Stop J-Link GDB Server
        -- ============================================================================
        local function start_debugger_session()
            if not selected_elf_path then
                vim.notify('No ELF selected — cannot start debugger', vim.log.levels.ERROR)
                return
            end
            vim.notify('Connecting debugger...', vim.log.levels.INFO)
            dap_continue()
        end

        local function start_jlink_gdb_server()
            if jlink_job_id and jlink_job_id > 0 then
                vim.notify('J-Link GDB Server already running', vim.log.levels.INFO)
                return
            end

            if not selected_elf_path then
                vim.notify('No ELF selected — please choose one', vim.log.levels.WARN)
                select_elf_file(start_jlink_gdb_server)
                return
            end

            local cmd = {
                'JLinkGDBServer',
                '-device',
                'STM32L071CZ',
                '-if',
                'SWD',
                '-speed',
                '4000',
                '-port',
                '2331',
                '-swoport',
                '2332',
                '-telnetport',
                '2333',
                '-noir',
            }

            jlink_job_id = vim.fn.jobstart(cmd, {
                stdout_buffered = false,
                stderr_buffered = false,

                on_exit = function(_, exit_code)
                    jlink_job_id = nil
                    if exit_code ~= 0 then
                        vim.notify('J-Link GDB Server exited with code: ' .. exit_code, vim.log.levels.WARN)
                    else
                        vim.notify('J-Link GDB Server stopped', vim.log.levels.INFO)
                    end
                end,

                on_stdout = function(_, data)
                    if not data then
                        return
                    end
                    for _, line in ipairs(data) do
                        if line ~= '' and line:match('Waiting for GDB connection') then
                            vim.notify('J-Link GDB Server ready on port 2331', vim.log.levels.INFO)
                            vim.defer_fn(function()
                                start_debugger_session()
                            end, 500)
                        end
                    end
                end,

                on_stderr = function(_, data)
                    if not data then
                        return
                    end
                    local lines = {}
                    for _, line in ipairs(data) do
                        if line ~= '' then
                            table.insert(lines, line)
                        end
                    end
                    if #lines > 0 then
                        vim.notify('J-Link: ' .. table.concat(lines, '\n'), vim.log.levels.WARN)
                    end
                end,
            })

            if not jlink_job_id or jlink_job_id <= 0 then
                jlink_job_id = nil
                vim.notify('Failed to start J-Link GDB Server', vim.log.levels.ERROR)
            else
                vim.notify('Starting J-Link GDB Server...', vim.log.levels.INFO)
            end
        end

        local function stop_jlink_gdb_server()
            if not jlink_job_id or jlink_job_id <= 0 then
                vim.notify('J-Link GDB Server not running', vim.log.levels.INFO)
                set_dap_state('disconnected')
                return
            end

            vim.notify('Stopping J-Link GDB Server...', vim.log.levels.INFO)

            if dap.session() then
                dap_disconnect()
            else
                set_dap_state('disconnected')
            end

            pcall(vim.fn.jobstop, jlink_job_id)
        end

        -- ============================================================================
        -- C/C++ CONFIGURATIONS (cpptools)
        -- ============================================================================
        dap.configurations.c = {
            {
                name = 'J-Link (STM32 via cpptools)',
                type = 'cppdbg',
                request = 'launch',
                program = function()
                    if selected_elf_path then
                        return selected_elf_path
                    end
                    vim.notify('No ELF file set! Use <Leader>dte to set one.', vim.log.levels.ERROR)
                    return nil
                end,
                cwd = '${workspaceFolder}',
                stopAtEntry = false,
                MIMode = 'gdb',
                targetArchitecture = 'arm',
                miDebuggerPath = 'gdb-multiarch',
                miDebuggerServerAddress = 'localhost:2331',

                debugServerPath = '',
                debugServerArgs = '',
                serverStarted = 'Waiting for GDB connection',
                filterStderr = true,
                filterStdout = false,
                serverLaunchTimeout = 5000,
                externalConsole = false,

                setupCommands = {
                    {
                        text = '-enable-pretty-printing',
                        description = 'Enable pretty printing',
                        ignoreFailures = true,
                    },
                    {
                        text = '-gdb-set mi-async on',
                        description = 'Enable async mode',
                        ignoreFailures = true,
                    },
                },

                launchCompleteCommand = 'exec-continue',
            },
        }

        dap.configurations.cpp = dap.configurations.c
        dap.defaults.fallback.force_external_terminal = false
        dap.defaults.fallback.external_terminal = nil

        -- ============================================================================
        -- KEY MAPPINGS
        -- ============================================================================
        local keymap = vim.keymap.set
        local opts = { noremap = true, silent = true }

        -- Target setup
        keymap('n', '<Leader>dte', function()
            select_elf_file()
        end, vim.tbl_extend('force', opts, { desc = 'Set ELF' }))

        keymap('n', '<Leader>dtf', flash_elf, vim.tbl_extend('force', opts, { desc = 'Flash ELF' }))
        keymap('n', '<Leader>dts', start_jlink_gdb_server, vim.tbl_extend('force', opts, { desc = 'Start Server' }))
        keymap('n', '<Leader>dtc', stop_jlink_gdb_server, vim.tbl_extend('force', opts, { desc = 'Stop Server' }))

        -- Session control
        keymap('n', '<Leader>dc', function()
            vim.defer_fn(function()
                dap_continue()
            end, 200)
        end, vim.tbl_extend('force', opts, { desc = 'Continue/Start (deferred)' }))

        keymap('n', '<Leader>dtt', dap_terminate, vim.tbl_extend('force', opts, { desc = 'Terminate' }))
        keymap('n', '<Leader>dR', dap_mark_running_and(dap.restart), vim.tbl_extend('force', opts, { desc = 'Restart' }))
        keymap('n', '<Leader>dp', dap.pause, vim.tbl_extend('force', opts, { desc = 'Pause' }))

        -- Stepping
        keymap('n', '<Leader>di', dap_step_into, vim.tbl_extend('force', opts, { desc = 'Step Into' }))
        keymap('n', '<Leader>do', dap_step_over, vim.tbl_extend('force', opts, { desc = 'Step Over' }))
        keymap('n', '<Leader>dO', dap_step_out, vim.tbl_extend('force', opts, { desc = 'Step Out' }))

        -- Breakpoints
        keymap('n', '<Leader>db', dap.toggle_breakpoint, vim.tbl_extend('force', opts, { desc = 'Toggle Breakpoint' }))
        keymap('n', '<Leader>dB', function()
            dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
        end, vim.tbl_extend('force', opts, { desc = 'Conditional Breakpoint' }))
        keymap('n', '<Leader>dx', function()
            dap.clear_breakpoints()
        end, vim.tbl_extend('force', opts, { desc = 'Clear Breakpoints' }))

        -- UI toggle
        keymap('n', '<Leader>du', function()
            local is_open = false
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                local buf_name = vim.api.nvim_buf_get_name(buf)
                if buf_name:match('DAP') then
                    is_open = true
                    break
                end
            end

            if is_open then
                dapui.close()
            else
                dapui.close()
                vim.defer_fn(function()
                    dapui.open({ reset = true })
                    vim.schedule(function()
                        vim.cmd('wincmd =')
                    end)
                end, 50)
            end
        end, vim.tbl_extend('force', opts, { desc = 'Toggle UI' }))

        -- Evaluation
        keymap('n', '<Leader>de', dapui.eval, vim.tbl_extend('force', opts, { desc = 'Eval Expression' }))
        keymap('v', '<Leader>de', dapui.eval, vim.tbl_extend('force', opts, { desc = 'Eval Selection' }))

        -- Add to watches
        keymap('n', '<Leader>dw', function()
            local word = vim.fn.expand('<cword>')
            dapui.elements.watches.add(word)
            vim.notify("Added '" .. word .. "' to watches", vim.log.levels.INFO)
        end, vim.tbl_extend('force', opts, { desc = 'Add to Watches' }))

        -- Run to cursor
        keymap('n', '<Leader>dC', dap_run_to_cursor, vim.tbl_extend('force', opts, { desc = 'Run to Cursor' }))

        -- REPL
        keymap('n', '<Leader>dr', dap.repl.open, vim.tbl_extend('force', opts, { desc = 'Open REPL' }))

        -- Stack navigation
        keymap('n', '<Leader>dk', function()
            dap.up()
        end, vim.tbl_extend('force', opts, { desc = 'Stack Up' }))
        keymap('n', '<Leader>dj', function()
            dap.down()
        end, vim.tbl_extend('force', opts, { desc = 'Stack Down' }))

        -- Logging
        keymap('n', '<Leader>dv', function()
            dap.set_log_level('TRACE')
            vim.notify('DAP log: ' .. vim.fn.stdpath('cache') .. '/dap.log', vim.log.levels.INFO)
        end, vim.tbl_extend('force', opts, { desc = 'Verbose Logging' }))

        -- Window navigation
        local function jump_to_dap_window(filetype_pattern)
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
                if ft:match(filetype_pattern) then
                    vim.api.nvim_set_current_win(win)
                    return
                end
            end
            vim.notify('DAP window not found: ' .. filetype_pattern, vim.log.levels.WARN)
        end

        keymap('n', '<Leader>dgs', function()
            jump_to_dap_window('dapui_scopes')
        end, vim.tbl_extend('force', opts, { desc = 'Go to Scopes' }))

        keymap('n', '<Leader>dgw', function()
            jump_to_dap_window('dapui_watches')
        end, vim.tbl_extend('force', opts, { desc = 'Go to Watches' }))

        keymap('n', '<Leader>dgt', function()
            jump_to_dap_window('dapui_stacks')
        end, vim.tbl_extend('force', opts, { desc = 'Go to Stacks' }))

        keymap('n', '<Leader>dgb', function()
            jump_to_dap_window('dapui_breakpoints')
        end, vim.tbl_extend('force', opts, { desc = 'Go to Breakpoints' }))

        keymap('n', '<Leader>dgr', function()
            jump_to_dap_window('dapui_repl')
        end, vim.tbl_extend('force', opts, { desc = 'Go to REPL' }))

        keymap('n', '<Leader>dgc', function()
            jump_to_dap_window('dapui_console')
        end, vim.tbl_extend('force', opts, { desc = 'Go to Console' }))

        -- ============================================================================
        -- Extra stop diagnostics (optional)
        -- ============================================================================
        dap.listeners.after.event_stopped['print_stop_reason'] = function(_, body)
            local parts = {}

            if body.reason then
                table.insert(parts, 'reason=' .. tostring(body.reason))
            end
            if body.hitBreakpointIds then
                table.insert(parts, 'hitBreakpointIds=' .. vim.inspect(body.hitBreakpointIds))
            end
            if body.description then
                table.insert(parts, 'desc=' .. tostring(body.description))
            end
            if body.text then
                table.insert(parts, 'text=' .. tostring(body.text))
            end

            vim.schedule(function()
                vim.notify('DAP stopped: ' .. table.concat(parts, ' | '), vim.log.levels.WARN)
            end)
        end

        vim.notify('DAP configured successfully!', vim.log.levels.INFO)
    end,
}
