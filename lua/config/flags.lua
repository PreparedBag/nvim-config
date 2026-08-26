local M = {}
local marker = vim.fn.stdpath("data") .. "/nvim-dev"

-- Known flags and their fallback values. Flags show up in the float as
-- soon as they're listed here, even before they've ever been toggled.
--
-- Submenu convention: a flag named PARENT_CHILD nests under PARENT when
-- PARENT is itself a known flag. e.g. LSP_ENABLED_JAVA_ENABLED shows as
-- JAVA_ENABLED inside the LSP_ENABLED group, and only while LSP is on.
M.defaults = {
    DAP_ENABLED = false,
    LSP_ENABLED = false,
    LSP_ENABLED_CLANGD = true,
    LSP_ENABLED_PYLSP = true,
    LSP_ENABLED_LUA_LS = true,
    LSP_ENABLED_TS_LS = false,
    LSP_ENABLED_HTML = true,
    LSP_ENABLED_CSSLS = true,
    LSP_ENABLED_JDTLS = false,
    LSP_ENABLED_GOPLS = false,
    LSP_ENABLED_RUST = false,
    LSP_ENABLED_BASHLS = false,
    HTML_VIEWER = true,
    FULL_MARKDOWN = false,
}

-- Float styling: bold/blue/italic name, colored checkbox icons, dim hint.
vim.api.nvim_set_hl(0, "FlagName", { fg = "#89b4fa", bold = true, italic = true, default = true })
vim.api.nvim_set_hl(0, "FlagOn",   { fg = "#a6e3a1", default = true })
vim.api.nvim_set_hl(0, "FlagOff",  { fg = "#6c7086", default = true })
vim.api.nvim_set_hl(0, "FlagHint", { italic = true, fg = "#6c7086", default = true })

local ns = vim.api.nvim_create_namespace("flags_float")
local ICON = { on = "󰄲", off = "󰄱" } -- nerd-font checkboxes; fallback: { on = "☑", off = "☐" }

-- Padding, in rows. Top pad is drawn by a blank winbar (non-navigable);
-- bottom pad + hint are virtual lines. No gap between rows.
local PAD_TOP, PAD_BETWEEN, PAD_BOTTOM = 1, 0, 1

-- Row indent: base for roots, plus this much per submenu depth level.
local INDENT_BASE, INDENT_STEP = 4, 3

-- Only one float at a time.
local cur_win

-- ---------------------------------------------------------------
-- Store: flags persist as `key=value` lines in the marker file.
-- ---------------------------------------------------------------

local function read()
    local flags = {}
    if vim.fn.filereadable(marker) == 1 then
        for _, line in ipairs(vim.fn.readfile(marker)) do
            local k, v = line:match("^%s*([%w_]+)%s*=%s*(%S+)%s*$")
            if k then
                flags[k] = (v == "true")
            end
        end
    end
    return flags
end

local function write(flags)
    local out = {}
    for k, v in pairs(flags) do
        table.insert(out, k .. "=" .. tostring(v))
    end
    table.sort(out)
    vim.fn.writefile(out, marker)
end

function M.get(name)
    local v = read()[name]
    if v == nil then v = M.defaults[name] end
    return v or false
end

-- Every flag written to disk, merged with the known defaults, sorted.
function M.names()
    local seen = read()
    for k in pairs(M.defaults) do
        seen[k] = seen[k] or false
    end
    local names = vim.tbl_keys(seen)
    table.sort(names)
    return names
end

function M.set(name, value)
    value = value and true or false
    local flags = read()
    flags[name] = value
    write(flags)
    _G[name] = value
    return value
end

function M.toggle(name)
    return M.set(name, not M.get(name))
end

-- True if any flag differs from its value at startup.
local function dirty()
    for _, name in ipairs(M.names()) do
        if M.get(name) ~= (M._startup[name] or false) then
            return true
        end
    end
    return false
end

-- ---------------------------------------------------------------
-- Submenu tree. Parentage is derived from names: the parent of a
-- flag is the longest known flag that is a prefix of it at an
-- underscore boundary. No parent => it's a root.
-- ---------------------------------------------------------------

local function parent_of(name, is_flag)
    local best, i = nil, name:find("_")
    while i do
        local prefix = name:sub(1, i - 1)
        if is_flag[prefix] then best = prefix end
        i = name:find("_", i + 1)
    end
    return best
end

-- roots (sorted) and a parent -> sorted-children map.
local function tree()
    local names = M.names()
    local is_flag = {}
    for _, n in ipairs(names) do is_flag[n] = true end

    local roots, children = {}, {}
    for _, name in ipairs(names) do
        local p = parent_of(name, is_flag)
        if p then
            children[p] = children[p] or {}
            table.insert(children[p], name)
        else
            table.insert(roots, name)
        end
    end
    table.sort(roots)
    for _, c in pairs(children) do table.sort(c) end
    return roots, children
end

-- Ordered rows to render: { name, label, depth }. A group's children
-- are included only while the group is enabled, so toggling a group
-- expands/collapses its submenu live.
local function visible_rows()
    local _, children = tree()
    local roots = (tree())
    local rows = {}
    local function add(name, depth, label)
        rows[#rows + 1] = { name = name, depth = depth, label = label }
        if M.get(name) and children[name] then
            for _, child in ipairs(children[name]) do
                add(child, depth + 1, child:sub(#name + 2)) -- strip "PARENT_"
            end
        end
    end
    for _, r in ipairs(roots) do
        add(r, 0, r)
    end
    return rows
end

-- ---------------------------------------------------------------
-- Interactive toggle float. <CR>/<Tab> flip the flag under the
-- cursor and re-render live; q closes. A blank winbar gives the top
-- pad; virtual lines give the bottom pad and the "restart" hint.
-- ---------------------------------------------------------------

-- n empty virtual lines, for padding.
local function blanks(n)
    local t = {}
    for _ = 1, n do
        t[#t + 1] = { { "", "Normal" } }
    end
    return t
end

function M.open()
    if cur_win and vim.api.nvim_win_is_valid(cur_win) then
        vim.api.nvim_win_close(cur_win, true)
        cur_win = nil
        return
    end

    if #M.names() == 0 then
        return vim.notify("No flags defined", vim.log.levels.INFO)
    end

    -- Window height for n visible rows: winbar + rows + between-pad +
    -- bottom-pad + one hint row.
    local function win_height(n)
        return n + PAD_TOP + PAD_BETWEEN * math.max(n - 1, 0) + PAD_BOTTOM + 1
    end

    -- Current visible rows, rebuilt every render. `toggle` reads this
    -- to map the cursor line back to a flag.
    local rows = visible_rows()

    local function render(buf, win)
        rows = visible_rows()

        local lines = {}
        for i, row in ipairs(rows) do
            local icon = M.get(row.name) and ICON.on or ICON.off
            local pad = string.rep(" ", INDENT_BASE + row.depth * INDENT_STEP)
            lines[i] = pad .. icon .. "  " .. row.label
        end

        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

        for i, row in ipairs(rows) do
            local on = M.get(row.name)
            local icon = on and ICON.on or ICON.off
            local lnum = i - 1
            local icon_start = INDENT_BASE + row.depth * INDENT_STEP -- byte col after indent
            local name_start = icon_start + #icon + 2

            vim.api.nvim_buf_set_extmark(buf, ns, lnum, icon_start, {
                end_col = icon_start + #icon, hl_group = on and "FlagOn" or "FlagOff",
            })
            vim.api.nvim_buf_set_extmark(buf, ns, lnum, name_start, {
                end_col = name_start + #row.label, hl_group = "FlagName",
            })

            if i < #rows then
                if PAD_BETWEEN > 0 then
                    vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, { virt_lines = blanks(PAD_BETWEEN) })
                end
            else
                -- bottom pad, then a fixed hint row (blank when clean, so the
                -- window never resizes as `dirty` flips on and off)
                local vlines = blanks(PAD_BOTTOM)
                vlines[#vlines + 1] = dirty()
                    and { { "    restart and ':Lazy sync' required", "FlagHint" } }
                    or { { "", "Normal" } }
                vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, { virt_lines = vlines })
            end
        end

        vim.bo[buf].modifiable = false

        -- Grow/shrink the float to fit the current rows, and keep the
        -- cursor on a real line when a submenu collapses.
        if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_height(win, win_height(#rows))
            if vim.api.nvim_win_get_cursor(win)[1] > #rows then
                vim.api.nvim_win_set_cursor(win, { #rows, 0 })
            end
        end
    end

    local function toggle(self)
        local row = rows[vim.api.nvim_win_get_cursor(self.win)[1]]
        if row then
            M.toggle(row.name)
            render(self.buf, self.win)
        end
    end

    local win = Snacks.win({
        title = " Feature Flags ",
        title_pos = "center",
        border = "rounded",
        width = 44,
        height = win_height(#rows),
        wo = {
            cursorline = true,
            number = false,
            relativenumber = false,
            winbar = " ", -- top pad; one non-navigable row
            winhighlight = "Normal:NormalFloat,FloatBorder:FlagName,FloatTitle:FlagName,WinBar:NormalFloat,WinBarNC:NormalFloat",
        },
        bo = { filetype = "flags", modifiable = false },
        keys = {
            ["<esc>"] = "close",
            ["<cr>"] = toggle,
            ["<Tab>"] = toggle,
        },
    })

    cur_win = win.win
    render(win.buf, win.win)
end

-- Hydrate _G for all known flags at load, and snapshot the startup values
-- so the float can tell when a change needs a restart.
M._startup = {}
for _, name in ipairs(M.names()) do
    _G[name] = M.get(name)
    M._startup[name] = _G[name]
end

vim.keymap.set("n", "<leader>M", M.open, { desc = "Toggle Feature Flags" })

return M
