local M = {}

function M.dialog(title, choices, items, on_choice)
    local has_preview = items ~= nil and #items > 0
    local ch = #choices
    local ph = 0
    if has_preview then
        ph = math.min(#items, math.floor(vim.o.lines * 0.6))
    end
    local width = 80
    local function fit(s)
        if s and #s + 4 > width then
            width = #s + 4
        end
    end
    fit(title)
    if has_preview then
        fit("Selection(s)")
    end
    for _, c in ipairs(choices) do
        fit("  " .. c)
    end
    if has_preview then
        for _, it in ipairs(items) do
            fit("  " .. it)
        end
    end
    width = math.min(width, math.floor(vim.o.columns * 0.8))
    local top = 1
    local col = math.floor((vim.o.columns - width) / 2)
    local choice_lines = {}
    for _, c in ipairs(choices) do
        table.insert(choice_lines, "  " .. c)
    end
    local cbuf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(cbuf, 0, -1, false, choice_lines)
    vim.bo[cbuf].modifiable = false
    vim.bo[cbuf].bufhidden = "wipe"
    local pwin
    if has_preview then
        local plines = {}
        for _, it in ipairs(items) do
            table.insert(plines, "  " .. it)
        end
        local pbuf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, plines)
        vim.bo[pbuf].modifiable = false
        vim.bo[pbuf].bufhidden = "wipe"
        pwin = vim.api.nvim_open_win(pbuf, false, {
            relative = "editor",
            width = width,
            height = ph,
            row = top + ch + 3,
            col = col,
            style = "minimal",
            border = "rounded",
            title = " Selection(s) ",
            title_pos = "center",
            focusable = false,
        })
    end
    local cwin = vim.api.nvim_open_win(cbuf, true, {
        relative = "editor",
        width = width,
        height = ch,
        row = top + 1,
        col = col,
        style = "minimal",
        border = "rounded",
        title = title and (" " .. title .. " ") or nil,
        title_pos = "center",
    })
    vim.wo[cwin].cursorline = true
    local sel = 1
    local function set(n)
        if n < 1 then n = 1 end
        if n > #choices then n = #choices end
        sel = n
        if vim.api.nvim_win_is_valid(cwin) then
            vim.api.nvim_win_set_cursor(cwin, { sel, 0 })
        end
    end
    set(1)
    local function close()
        if pwin and vim.api.nvim_win_is_valid(pwin) then
            vim.api.nvim_win_close(pwin, true)
        end
        if vim.api.nvim_win_is_valid(cwin) then
            vim.api.nvim_win_close(cwin, true)
        end
    end
    local function choose()
        local picked = choices[sel]
        close()
        if on_choice then
            on_choice(picked)
        end
    end
    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = cbuf,
        once = true,
        callback = close,
    })
    local opts = { buffer = cbuf, nowait = true, silent = true }
    local blocked = {
        "i", "I", "a", "A", "o", "O", "c", "C", "s", "S", "R",
        "r", "x", "p", "P", "d", "u", "v", "V", ".", "/", ":",
        "h", "l", "w", "b", "e", "g", "G", "H", "M", "L", "0", "$",
        "y", "n",
    }
    for _, key in ipairs(blocked) do
        vim.keymap.set("n", key, function() end, opts)
    end
    vim.keymap.set("n", "j", function() set(sel + 1) end, opts)
    vim.keymap.set("n", "k", function() set(sel - 1) end, opts)
    vim.keymap.set("n", "<Down>", function() set(sel + 1) end, opts)
    vim.keymap.set("n", "<Up>", function() set(sel - 1) end, opts)
    vim.keymap.set("n", "<CR>", choose, opts)
    vim.keymap.set("n", "q", close, opts)
    vim.keymap.set("n", "<Esc>", close, opts)
    for i, c in ipairs(choices) do
        if c == "Yes" then
            vim.keymap.set("n", "y", function()
                set(i); choose()
            end, opts)
        elseif c == "No" then
            vim.keymap.set("n", "n", function()
                set(i); choose()
            end, opts)
        end
    end
end

function M.select(title, items, on_choice)
    M.dialog(title, items, nil, on_choice)
end

function M.confirm(msg, on_yes)
    M.dialog(msg, { "Yes", "No" }, nil, function(choice)
        if choice == "Yes" then on_yes() end
    end)
end

function M.confirm_dialog(title, items, on_yes)
    M.dialog(title, { "Yes", "No" }, items, function(choice)
        if choice == "Yes" then on_yes() end
    end)
end

function M.is_valid_lsp_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) ~= "" then
        return false
    end
    local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    local excluded = { "oil", "help", "qf", "netrw", "man", "lazy", "mason" }
    for _, e in ipairs(excluded) do
        if ft == e then return false end
    end
    return true
end

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
