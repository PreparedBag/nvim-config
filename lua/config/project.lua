-- Reads optional per-project settings from .nvim-project-settings.lua in
-- the cwd. See `:h preparedbag-config` for the file's syntax and the list of
-- sections.
--
-- Always re-reads from disk on each call rather than caching — the file is
-- tiny, and this way an edit takes effect on the very next picker/session
-- start with no reload step to remember.
local M = {}

-- Returns the whole parsed table, or nil if there's no file, or it failed
-- to load, or didn't return a table.
function M.get()
    local path = vim.fn.getcwd() .. "/.nvim-project-settings.lua"
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

-- Returns just one top-level section (e.g. "dap", "telescope"), or nil if
-- absent. Warns (rather than erroring) if present but not a table, since
-- that's almost certainly a typo in the project's .nvim-config.lua.
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

-- Reads optional per-project settings from .nvim-project-settings.lua in
-- the cwd. See `:h nvim-config` for the file's syntax and the list of
-- sections.
--
-- Always re-reads from disk on each call rather than caching — the file is
-- tiny, and this way an edit takes effect on the very next picker/session
-- start with no reload step to remember.
local M = {}

-- Returns the whole parsed table, or nil if there's no file, or it failed
-- to load, or didn't return a table.
function M.get()
    local path = vim.fn.getcwd() .. "/.nvim-project-settings.lua"
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

-- Returns just one top-level section (e.g. "dap", "telescope"), or nil if
-- absent. Warns (rather than erroring) if present but not a table, since
-- that's almost certainly a typo in the project's .nvim-config.lua.
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

-- Genuine relative path from `base` to `target` (with ../ as needed).
-- Neither plenary's Path:make_relative nor vim.fs.relpath do this — both
-- only strip a matching prefix and fall back to the full path otherwise.
-- Used by telescope.lua's path_display and harpoon.lua's create_list_item.
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
