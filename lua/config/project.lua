-- Reads optional per-project settings from .nvim-project-settings.lua in the cwd.
-- See `:h nvim-project-settings` for the file's syntax and the list of sections.
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
-- that's almost certainly a typo in the project's .nvim-project-settings.lua.
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

return M
