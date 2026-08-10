return {
    'mfussenegger/nvim-dap',
    enabled = require("config.flags").get("DAP_ENABLED"),
    ft = { 'c', 'cpp' },
    dependencies = {
        'rcarriga/nvim-dap-ui',
        'nvim-neotest/nvim-nio',
        'theHamsta/nvim-dap-virtual-text',
        'nvim-telescope/telescope.nvim',
    },

    -- These load the plugin lazily; the real handlers are set in config().
    keys = {
        -- { '<Leader>d',   desc = 'Start DAP' },
        -- { '<Leader>ds',  desc = 'Start Debug Session' },
        -- { '<Leader>dc',  desc = 'Continue' },
        -- { '<Leader>dtp', desc = 'Pick Target' },
        -- { '<Leader>dte', desc = 'Set ELF' },
        -- { '<Leader>dtf', desc = 'Flash ELF' },
        -- { '<Leader>dts', desc = 'Start Server' },
        -- { '<Leader>dtc', desc = 'Stop Server' },
        -- { '<Leader>dtr', desc = 'Recover Target' },
        -- { '<Leader>dtt', desc = 'Terminate' },
        -- { '<Leader>dq',  desc = 'Stop Debug Session' },
        -- { '<Leader>db',  desc = 'Toggle Breakpoint' },
    },

    config = function()
        local dap = require('dap')
        local dapui = require('dapui')
        local dapvt = require('nvim-dap-virtual-text')

        local presets = {
            ['STM32L433CC'] = {
                device    = 'STM32L433CC',
                interface = 'SWD',
                speed     = '4000',
                gdb_port  = 2331,
            },
            -- Add more to enable the picker, e.g.:
            -- ['STM32F411CE'] = {
            --     device = 'STM32F411CE',
            --     interface = 'SWD',
            --     speed = '4000',
            --     gdb_port = 2331,
            -- },
        }

        local active = nil       -- resolved config table
        local selected_elf = nil -- path to ELF being debugged
        local I, W, E = vim.log.levels.INFO, vim.log.levels.WARN, vim.log.levels.ERROR
        local function notify(msg, lvl) vim.notify(msg, lvl or I) end

        -- Resolve `active`: project file > single preset > picker.
        local function resolve_config(cb)
            if active then
                if cb then cb() end
                return
            end

            local project_dap = require('config.project').section('dap')
            local available = project_dap or presets

            local names = vim.tbl_keys(available)
            if #names == 1 then
                active = available[names[1]]
                notify('DAP config: ' .. names[1])
                if cb then cb() end
                return
            end

            vim.ui.select(names, { prompt = 'Debug target:' }, function(choice)
                if not choice then return end
                active = available[choice]
                notify('DAP config: ' .. choice)
                if cb then cb() end
            end)
        end

        -- ========================================================================
        -- 2. STATE  (single source of truth)
        --    active/inactive = dap.session()  |  running/paused = listeners
        -- ========================================================================
        local COL = {
            run = '#98c379',
            pause = '#e5c07b',
            off = '#9ca3b0',
        }
        local running = false

        local function state()
            if not dap.session() then return 'inactive' end
            return running and 'running' or 'paused'
        end

        -- --- Visual: dapui window titles + REPL state label --------------------
        local titles = {
            dapui_scopes = 'SCOPES',
            dapui_breakpoints = 'BREAKPOINTS',
            dapui_stacks = 'STACKS',
            dapui_watches = 'WATCHES',
            dapui_console = 'CONSOLE',
            ['dap-repl'] = 'REPL',
        }
        local function is_repl(ft) return ft == 'dap-repl' end

        local function winbar_for(ft)
            local base = titles[ft]
            if not base then return nil end
            if not is_repl(ft) then
                return '%=%#DapWinBar# ' .. base .. ' %*%='
            end
            local s = state()
            local hl, label = 'DapStateOff', 'INACTIVE'
            if s == 'running' then
                hl, label = 'DapStateRun', 'RUNNING'
            elseif s == 'paused' then
                hl, label = 'DapStatePause', 'PAUSED'
            end
            return '%=%#' .. hl .. '# REPL · ' .. label .. ' %*%='
        end

        local function style_win(win)
            if not vim.api.nvim_win_is_valid(win) then return end
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            local wb = winbar_for(ft)
            if not wb then return end

            local opt = vim.api.nvim_set_option_value
            opt('winbar', wb, { win = win })
            opt('winhighlight', 'WinBar:CursorLine,WinBarNC:CursorLine', { win = win })
            for _, o in ipairs({ 'cursorline', 'number', 'relativenumber' }) do
                opt(o, false, { win = win })
            end
            opt('signcolumn', 'no', { win = win })
        end

        -- Re-read truth and repaint everything. Scheduled so dap.session()
        -- reflects post-event state (terminate/exit/restart/attach).
        local function refresh()
            vim.schedule(function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    style_win(win)
                end
            end)
        end

        local theme = require("after.theme-utils")

        theme.on_colorscheme(function()
            vim.api.nvim_set_hl(0, "DapWinBar", { fg = COL.off, bold = true })
            vim.api.nvim_set_hl(0, "DapUIWindowSeparator", { fg = "none", bg = "none" })
            vim.api.nvim_set_hl(0, 'DapStateRun', { fg = COL.run, bold = true })
            vim.api.nvim_set_hl(0, 'DapStatePause', { fg = COL.pause, bold = true })
            vim.api.nvim_set_hl(0, 'DapStateOff', { fg = COL.off, bold = true })
        end)

        -- --- State listeners (the actual sync) --------------------------------
        local function mark(v)
            running = v; refresh()
        end

        dap.listeners.after.event_initialized['ui'] = function() mark(true) end
        dap.listeners.after.event_stopped['ui']     = function() mark(false) end
        dap.listeners.after.event_continued['ui']   = function() mark(true) end
        dap.listeners.after.event_terminated['ui']  = function() mark(false) end
        dap.listeners.after.event_exited['ui']      = function() mark(false) end
        dap.listeners.after.disconnect['ui']        = function() mark(false) end

        -- cpptools is unreliable about event_continued, so also mark running
        -- off the request responses themselves.
        for _, req in ipairs({ 'continue', 'next', 'stepIn', 'stepOut', 'stepBack', 'reverseContinue' }) do
            dap.listeners.after[req]['ui'] = function() mark(true) end
        end

        vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter', 'FileType' }, {
            callback = function() style_win(vim.api.nvim_get_current_win()) end,
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches", "dapui_repl", "dapui_console" },
            callback = function()
                vim.opt_local.cursorline = false
                vim.opt_local.cursorcolumn = false
            end,
        })


        -- ========================================================================
        -- dap-virtual-text
        -- ========================================================================
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

        -- ========================================================================
        -- dap-ui  (controls disabled -> no button row; state shown in winbar)
        -- ========================================================================
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
                        { id = 'breakpoints', size = 0.15 },
                        { id = 'watches',     size = 0.55 },
                        { id = 'scopes',      size = 0.15 },
                        { id = 'stacks',      size = 0.15 },
                    },
                    size = 45,
                    position = 'left',
                },
                {
                    elements = { { id = 'repl', size = 1.0 } },
                    size = 10,
                    position = 'bottom',
                },
            },
            controls = { enabled = false },
            floating = {
                max_height = 0.9,
                max_width = 0.9,
                border = 'single',
                mappings = { close = { 'q', '<Esc>' } },
            },
            windows = { indent = 1 },
            render = { max_type_length = 100, max_value_lines = 100, indent = 1 },
        })

        -- Auto open/close UI + auto-scroll REPL
        dap.listeners.after.event_initialized['dapui'] = function()
            vim.defer_fn(function() pcall(dapui.open) end, 100)
        end
        dap.listeners.before.event_terminated['dapui'] = function() pcall(dapui.close) end
        dap.listeners.before.event_exited['dapui']     = function() pcall(dapui.close) end

        dap.listeners.after.event_output['scroll']     = function()
            vim.schedule(function()
                for _, win in ipairs(vim.fn.win_findbuf(vim.fn.bufnr('dap-repl'))) do
                    vim.api.nvim_win_call(win, function() vim.cmd('normal! G') end)
                end
            end)
        end

        -- ========================================================================
        -- Signs
        -- ========================================================================
        vim.fn.sign_define('DapBreakpoint', { text = '🔴', texthl = 'DapBreakpoint' })
        vim.fn.sign_define('DapBreakpointCondition', { text = '🟡', texthl = 'DapBreakpoint' })
        vim.fn.sign_define('DapBreakpointRejected', { text = '🚫', texthl = 'DapBreakpointRejected' })
        vim.fn.sign_define('DapStopped', { text = '▶️', texthl = 'DapStopped', linehl = 'debugPC' })
        vim.fn.sign_define('DapLogPoint', { text = '📝', texthl = 'DapLogPoint' })

        -- ========================================================================
        -- Adapter + configuration (address/port pulled from `active` at launch)
        -- ========================================================================
        dap.adapters.cppdbg = {
            id = 'cppdbg',
            type = 'executable',
            command = vim.fn.stdpath('data') .. '/mason/bin/OpenDebugAD7',
        }

        dap.configurations.c = {
            {
                name = 'J-Link (STM32 via cpptools)',
                type = 'cppdbg',
                request = 'launch',
                program = function()
                    if selected_elf then return selected_elf end
                    notify('No ELF set — use <Leader>dte', E)
                    return nil
                end,
                cwd = '${workspaceFolder}',
                stopAtEntry = false,
                MIMode = 'gdb',
                targetArchitecture = 'arm',
                miDebuggerPath = 'gdb-multiarch',
                miDebuggerServerAddress = function()
                    return 'localhost:' .. tostring((active and active.gdb_port) or 2331)
                end,
                debugServerPath = '',
                debugServerArgs = '',
                serverStarted = 'Waiting for GDB connection',
                filterStderr = true,
                filterStdout = false,
                serverLaunchTimeout = 5000,
                externalConsole = false,
                setupCommands = {
                    { text = '-enable-pretty-printing', description = 'Pretty print', ignoreFailures = true },
                    { text = '-gdb-set mi-async on',    description = 'Async',        ignoreFailures = true },
                },
                -- Runs AFTER the remote connection (miDebuggerServerAddress)
                -- is actually established — setupCommands can fire too early
                -- for `monitor` to be recognized yet.
                postRemoteConnectCommands = {
                    { text = 'monitor reset', description = 'Reset to vector before halting', ignoreFailures = true },
                },
            },
        }
        dap.configurations.cpp = dap.configurations.c
        dap.defaults.fallback.force_external_terminal = false
        dap.defaults.fallback.external_terminal = nil

        -- ========================================================================
        -- ELF picker (Telescope)
        -- ========================================================================
        local function select_elf(cb)
            require('telescope.builtin').find_files({
                prompt_title = 'Select ELF for Debugging',
                cwd = vim.fn.getcwd(),
                hidden = true,
                find_command = { 'rg', '--files', '--hidden', '--no-ignore', '--glob', '!.git/*' },
                attach_mappings = function(bufnr)
                    local actions = require('telescope.actions')
                    local astate = require('telescope.actions.state')
                    actions.select_default:replace(function()
                        actions.close(bufnr)
                        local sel = astate.get_selected_entry()
                        if not sel then return end
                        selected_elf = sel.path or sel[1]
                        notify('ELF: ' .. selected_elf)
                        if cb then vim.defer_fn(cb, 100) end
                    end)
                    return true
                end,
            })
        end

        -- ========================================================================
        -- Flash via JLinkExe (independent of the debug session)
        -- ========================================================================
        local function flash_elf()
            if not active then
                resolve_config(flash_elf)
                return
            end
            if not selected_elf then
                select_elf(flash_elf)
                return
            end
            if vim.fn.filereadable(selected_elf) ~= 1 then
                notify('ELF not found: ' .. selected_elf, E)
                return
            end

            local script = '/tmp/jlink_flash.jlink'
            local f = io.open(script, 'w')
            if not f then
                notify('Cannot write flash script', E)
                return
            end
            f:write(('erase\nloadfile %s\nreset\ngo\nexit\n'):format(selected_elf))
            f:close()

            notify('Flashing ' .. selected_elf .. '...')
            local out = {}
            vim.fn.jobstart({
                'JLinkExe', '-device', active.device, '-if', active.interface,
                '-speed', active.speed, '-autoconnect', '1', '-CommandFile', script,
            }, {
                on_stdout = function(_, d)
                    for _, l in ipairs(d or {}) do if l ~= '' then table.insert(out, l) end end
                end,
                on_stderr = function(_, d)
                    for _, l in ipairs(d or {}) do if l ~= '' then table.insert(out, l) end end
                end,
                on_exit = function(_, code)
                    if code == 0 then
                        notify('Flash complete!')
                    else
                        local tail = table.concat({ unpack(out, math.max(1, #out - 8)) }, '\n')
                        notify('Flash failed (' .. code .. ')\n' .. tail, E)
                    end
                    os.remove(script)
                end,
            })
        end

        -- ========================================================================
        -- J-Link GDB Server: start (auto-launch) / stop (ordered teardown)
        -- ========================================================================
        local jlink_job = nil
        local server_ready = false

        local function launch_session()
            if dap.session() then return end -- already attached
            dap.continue()
        end

        local function start_server()
            if jlink_job then
                notify('GDB Server already running')
                return
            end
            if not active then
                resolve_config(start_server)
                return
            end
            if not selected_elf then
                select_elf(start_server)
                return
            end

            server_ready = false
            local cmd = {
                'JLinkGDBServer',
                '-device', active.device,
                '-if', active.interface,
                '-speed', active.speed,
                '-port', tostring(active.gdb_port),
            }

            jlink_job = vim.fn.jobstart(cmd, {
                on_stdout = function(_, data)
                    for _, line in ipairs(data or {}) do
                        -- fire-once: line can arrive fragmented or repeat
                        if not server_ready and line:match('Waiting for GDB connection') then
                            server_ready = true
                            notify('GDB Server ready on :' .. active.gdb_port)
                            -- JLinkGDBServer can misreport its own state if commanded
                            -- too soon after this line; 500ms clears that window.
                            vim.defer_fn(launch_session, 500)
                        end
                    end
                end,
                on_stderr = function(_, data)
                    local lines = {}
                    for _, l in ipairs(data or {}) do if l ~= '' then table.insert(lines, l) end end
                    if #lines > 0 then notify('J-Link: ' .. table.concat(lines, '\n'), W) end
                end,
                on_exit = function(_, code)
                    jlink_job = nil
                    server_ready = false
                    -- server died: tear down any dangling session so state clears
                    if dap.session() then pcall(dap.terminate) end
                    notify('GDB Server stopped' .. (code ~= 0 and (' (code ' .. code .. ')') or ''),
                        code ~= 0 and W or I)
                end,
            })

            if not jlink_job or jlink_job <= 0 then
                jlink_job = nil
                notify('Failed to start GDB Server', E)
            else
                notify('Starting GDB Server...')
            end
        end

        local function kill_server()
            if jlink_job then
                pcall(vim.fn.jobstop, jlink_job); jlink_job = nil
            end
            server_ready = false
        end

        -- Terminate the session, then kill the server once it's gone.
        -- Doesn't touch the chip's run state at all — if it ends up halted,
        -- <Leader>dtr recovers it explicitly.
        local function stop_server()
            if dap.session() then
                dap.terminate(nil, nil, function() vim.schedule(kill_server) end)
                vim.defer_fn(function()
                    if jlink_job then
                        pcall(dap.close) -- terminate never confirmed; drop our reference to it
                        kill_server()
                    end
                end, 1500) -- safety net
            else
                kill_server()
            end
        end

        -- Full teardown for <Leader>dq
        local function teardown()
            local function finish()
                pcall(dap.close) -- no-op if the session already closed itself
                pcall(dapui.close)
                pcall(function() dap.repl.close() end)
                vim.cmd('silent! sign unplace *')
                running = false
                kill_server()
                refresh()
                notify('DAP torn down')
            end
            if dap.session() then
                dap.terminate(nil, nil, function() vim.schedule(finish) end)
                vim.defer_fn(function() if dap.session() then finish() end end, 1500)
            else
                finish()
            end
        end

        -- Manual recover: reset + resume, no erase/reflash. Only ever run
        -- explicitly via <Leader>dtr.
        local function recover_target()
            if not active then
                resolve_config(recover_target)
                return
            end

            local script = '/tmp/jlink_recover.jlink'
            local f = io.open(script, 'w')
            if not f then
                notify('Cannot write recover script', E)
                return
            end
            f:write('r\ng\nexit\n') -- reset (halts), then go (resume)
            f:close()

            notify('Recovering target...')
            vim.fn.jobstart({
                'JLinkExe', '-device', active.device, '-if', active.interface,
                '-speed', active.speed, '-autoconnect', '1', '-CommandFile', script,
            }, {
                on_exit = function(_, code)
                    notify(code == 0 and 'Target recovered' or ('Recover failed (' .. code .. ')'),
                        code == 0 and I or E)
                    os.remove(script)
                end,
            })
        end

        -- True restart: end the current cppdbg/gdb session and relaunch a
        -- fresh one against the SAME still-running JLinkGDBServer. This goes
        -- through the full launch sequence again — including
        -- postRemoteConnectCommands' `monitor reset` — which is the one path
        -- that's proven reliable. (Sending `monitor reset` ad-hoc through the
        -- live REPL is not: cppdbg's evaluate handler tries to treat it as a
        -- variable first, which fails, and the fallback to running it as a
        -- raw command doesn't land consistently.)
        local function restart_target()
            if not jlink_job then
                notify('No GDB server running — use <Leader>ds', W)
                return
            end
            if dap.session() then
                dap.terminate(nil, nil, function() vim.schedule(launch_session) end)
            else
                launch_session()
            end
        end

        -- ========================================================================
        -- Extract the expression under the cursor (word + . -> [] chains)
        -- ========================================================================
        local function expr_under_cursor()
            local line = vim.fn.getline('.')
            local col = vim.fn.col('.') - 1

            local finish = col
            while finish <= #line and line:sub(finish, finish):match('[%w_]') do
                finish = finish + 1
            end

            local start = col
            while start > 0 and line:sub(start, start):match('[%w_%.%->%[%]]') do
                start = start - 1
            end
            if start == 0 then start = 1 else start = start + 1 end

            return line:sub(start, finish - 1)
        end

        -- ========================================================================
        -- Keymaps
        -- ========================================================================
        local function map(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { noremap = true, silent = true, desc = desc })
        end

        -- Target / session lifecycle
        map('<Leader>ds', start_server, 'Start Debug Session')
        map('<Leader>dtp', function()
            active = nil; resolve_config()
        end, 'Pick Target')
        map('<Leader>dte', function() select_elf() end, 'Set ELF')
        map('<Leader>dtf', flash_elf, 'Flash ELF')
        -- map('<Leader>dts', start_server, 'Start Server')
        -- map('<Leader>dtc', stop_server, 'Stop Server')
        map('<Leader>dtr', recover_target, 'Recover Target')
        map('<Leader>dtt', dap.terminate, 'Terminate')
        map('<Leader>dq', teardown, 'Stop Debug Session')

        map('<Leader>dc', dap.continue, 'Continue')
        map('<Leader>dr', restart_target, 'Restart Target')
        map('<Leader>dp', dap.pause, 'Pause')

        -- Stepping
        map('<Leader>di', dap.step_into, 'Step Into')
        map('<Leader>do', dap.step_over, 'Step Over')
        map('<Leader>dO', dap.step_out, 'Step Out')
        map('<Leader>dC', dap.run_to_cursor, 'Run to Cursor')

        -- Breakpoints
        map('<Leader>db', dap.toggle_breakpoint, 'Toggle Breakpoint')
        map('<Leader>dB', function()
            dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
        end, 'Conditional Breakpoint')
        map('<Leader>dx', dap.clear_breakpoints, 'Clear Breakpoints')

        -- Eval / watches / print
        vim.keymap.set({ 'n', 'v' }, '<Leader>de', dapui.eval,
            { noremap = true, silent = true, desc = 'Eval' })
        map('<Leader>dw', function()
            local w = expr_under_cursor()
            if w == '' then
                notify('No variable under cursor', W)
                return
            end
            dapui.elements.watches.add(w)
            notify("Watch: '" .. w .. "'")
        end, 'Add to Watches')
        map('<Leader>dW', function()
            local w = expr_under_cursor()
            if w == '' then
                notify('No variable under cursor', W)
                return
            end
            dap.repl.execute('`p ' .. w)
            notify("Printed '" .. w .. "'")
        end, 'Print Variable')

        -- Stack navigation
        map('<Leader>dj', dap.up, 'Stack Up')
        map('<Leader>dk', dap.down, 'Stack Down')

        -- UI toggle
        map('<Leader>du', function()
            local open = false
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match('DAP') then
                    open = true
                    break
                end
            end
            if open then
                dapui.close()
            else
                dapui.close()
                vim.defer_fn(function()
                    dapui.open({ reset = true })
                    vim.schedule(function() vim.cmd('wincmd =') end)
                end, 50)
            end
        end, 'Toggle UI')

        -- Jump to watches window (toggle back)
        map('<Leader>dg', function()
            if vim.bo.filetype == 'dapui_watches' then
                if vim.g.dap_return_win and vim.api.nvim_win_is_valid(vim.g.dap_return_win) then
                    vim.api.nvim_set_current_win(vim.g.dap_return_win)
                    vim.g.dap_return_win = nil
                end
                return
            end
            vim.g.dap_return_win = vim.api.nvim_get_current_win()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
                if ft == 'dapui_watches' then
                    vim.api.nvim_set_current_win(win)
                    return
                end
            end
            notify('Watches window not found', W)
        end, 'Toggle Watches')

        -- Logging
        map('<Leader>dv', function()
            dap.set_log_level('TRACE')
            notify('DAP log: ' .. vim.fn.stdpath('cache') .. '/dap.log')
        end, 'Verbose Logging')

        notify('DAP Configured Successfully!')
    end,
}
