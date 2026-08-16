local M = {}

local active_maps = {}

local function session_dir()
    return _G.session_directory or vim.fn.getcwd()
end

local function settings_path()
    return session_dir() .. "/.nvim-project-settings.lua"
end

function M.get()
    local path = settings_path()
    if vim.fn.filereadable(path) == 0 then
        return nil
    end
    local ok, cfg = pcall(dofile, path)
    if not ok or type(cfg) ~= "table" then
        vim.notify(".nvim-project-settings.lua failed to load: " .. tostring(cfg), vim.log.levels.WARN)
        return nil
    end
    return cfg
end

local TEMPLATE = [[return {
    dap = {
        ['STM32L433CC'] = {
            device    = 'stm32l433cc',
            interface = 'swd',
            speed     = '4000',
            gdb_port  = 2331,
        },
    },
    telescope = {
        extra_dirs = { },
        exclude = { },
    },
    commands = {
        {
            key = "<leader>ce",
            desc = "Example Command",
            cmd = "ls -l",
            keep_open = true,
        }
    },
}]]

function M.edit_settings()
    local path = settings_path()
    if vim.fn.filereadable(path) == 0 then
        local dir = session_dir()
        if vim.fn.isdirectory(dir) == 0 then
            vim.notify("No session directory to write settings into", vim.log.levels.WARN)
            return
        end
        vim.fn.writefile(vim.split(TEMPLATE, "\n"), path)
        vim.notify("Created " .. path, vim.log.levels.INFO)
    end
    vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.section(name)
    local cfg = M.get()
    if not cfg then
        return nil
    end

    local section = cfg[name]
    if section ~= nil and type(section) ~= "table" then
        vim.notify(".nvim-project-settings.lua: '" .. name .. "' should be a table", vim.log.levels.WARN)
        return nil
    end

    return section
end

local function resolve_dir(cwd)
    if cwd == nil or cwd == "root" then
        return session_dir()
    end
    return cwd
end

local function run_in_terminal(cmd, cwd, keep_open)
    local ok, tt = pcall(require, "toggleterm.terminal")
    if not ok then
        vim.notify("toggleterm not available", vim.log.levels.ERROR)
        return
    end
    tt.Terminal:new({
        cmd = cmd,
        dir = resolve_dir(cwd),
        direction = "float",
        close_on_exit = not keep_open,
    }):open()
end

function M.unload_commands()
    for _, m in ipairs(active_maps) do
        pcall(vim.keymap.del, m.mode, m.key)
    end
    active_maps = {}
end

function M.load_commands()
    M.unload_commands()
    local commands = M.section("commands")
    if not commands then
        return
    end
    for i, c in ipairs(commands) do
        if type(c) ~= "table" or type(c.key) ~= "string" or type(c.cmd) ~= "string" then
            vim.notify(
                (".nvim-project-settings.lua: commands[%d] needs string 'key' and 'cmd' - skipped"):format(i),
                vim.log.levels.WARN
            )
        else
            local mode = c.mode or "n"
            local cwd = c.cwd
            local keep_open = c.keep_open == true
            local cmd = c.cmd
            vim.keymap.set(mode, c.key, function()
                run_in_terminal(cmd, cwd, keep_open)
            end, { silent = true, desc = c.desc or ("Run: " .. cmd) })
            table.insert(active_maps, { mode = mode, key = c.key })
        end
    end
end

function M.setup()
    M.load_commands()

    vim.keymap.set("n", "<leader>pe", function()
        require("config.project").edit_settings()
    end, { silent = true, desc = "Edit Project Settings" })
end

function M.relative_path(base, target)
    local sep = package.config:sub(1, 1) == "\\" and "\\" or "/"

    local is_absolute = target:sub(1, 1) == sep or target:match("^%a:[\\/]")
    if not is_absolute then
        return target -- already relative (e.g. a plain single-dir rg/fd result)
    end

    local function split(p)
        local parts = {}
        for part in p:gmatch("[^" .. sep .. "]+") do
            table.insert(parts, part)
        end
        return parts
    end

    local base_parts = split(vim.fn.fnamemodify(base, ":p"))
    local target_parts = split(target)

    local common = 0
    while common < #base_parts and common < #target_parts
        and base_parts[common + 1] == target_parts[common + 1] do
        common = common + 1
    end

    local MAX_UP_LEVELS = 2
    local ups = #base_parts - common
    if ups > MAX_UP_LEVELS then
        return target -- too many ../ levels to stay readable; show the full path
    end

    local rel_parts = {}
    for _ = 1, ups do
        table.insert(rel_parts, "..")
    end
    for i = common + 1, #target_parts do
        table.insert(rel_parts, target_parts[i])
    end

    return table.concat(rel_parts, sep)
end

return M
