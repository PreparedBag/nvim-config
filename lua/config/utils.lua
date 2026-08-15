local M = {}

local DEAD_KEYS = {
    "i", "I", "a", "A", "o", "O", "c", "C", "s", "S", "R",
    "r", "x", "p", "P", "d", "u", "v", "V", ".", "/", ":",
}

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

local function lock(map)
    for _, key in ipairs(DEAD_KEYS) do
        map("n", key, function() end)
    end
    map("n", "q", require("telescope.actions").close)
end

local function theme(title, want_preview, selections)
    local opts = {
        initial_mode = "normal",
        prompt_title = title or "",
        layout_config = { width = 80, height = 4 + selections },
    }

    if not want_preview then
        opts.previewer = false
    end

    return require("telescope.themes").get_dropdown(opts)
end

function M.select(items, opts, on_choice)
    opts = opts or {}
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")

    pickers.new(theme(opts.prompt, false, #items), {

        finder = finders.new_table({ results = items }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
            actions.select_default:replace(function(bufnr)
                local entry = state.get_selected_entry()
                actions.close(bufnr)
                if entry and on_choice then
                    on_choice(entry[1])
                end

            end)
            lock(map)
            return true
        end,
    }):find()
end

function M.confirm(msg, on_yes)
    M.select({ "Yes", "No" }, { prompt = msg }, function(choice)
        if choice == "Yes" then
            on_yes()
        end
    end)
end

function M.confirm_list(msg, items, on_yes)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local previewers = require("telescope.previewers")

    local list_previewer = previewers.new_buffer_previewer({
        title = "Files",
        define_preview = function(self)
            local buf = self.state.bufnr
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, items)
            end
        end,
    })

    pickers.new(theme(msg, true, 2), {
        finder = finders.new_table({ results = { "Yes", "No" } }),
        sorter = conf.generic_sorter({}),
        previewer = list_previewer,
        attach_mappings = function(_, map)
            actions.select_default:replace(function(bufnr)
                local entry = state.get_selected_entry()
                actions.close(bufnr)
                if entry and entry[1] == "Yes" then
                    on_yes()
                end
            end)
            lock(map)
            return true
        end,
    }):find()
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
