local M = {}
local marker = vim.fn.stdpath("data") .. "/nvim-dev"

-- Known flags and their fallback values. Flags show up in the float as
-- soon as they're listed here, even before they've ever been toggled.
M.defaults = { DEV_ENABLED = false, FULL_MARKDOWN = false }

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

    local names = M.names()
    if #names == 0 then
        return vim.notify("No flags defined", vim.log.levels.INFO)
    end

    local function render(buf)
        local lines = {}
        for i, name in ipairs(names) do
            local icon = M.get(name) and ICON.on or ICON.off
            lines[i] = "    " .. icon .. "  " .. name -- 4-space left indent
        end

        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

        for i, name in ipairs(names) do
            local on = M.get(name)
            local icon = on and ICON.on or ICON.off
            local lnum = i - 1
            local icon_start = 4 -- byte col after the indent
            local name_start = icon_start + #icon + 2

            vim.api.nvim_buf_set_extmark(buf, ns, lnum, icon_start, {
                end_col = icon_start + #icon, hl_group = on and "FlagOn" or "FlagOff",
            })
            vim.api.nvim_buf_set_extmark(buf, ns, lnum, name_start, {
                end_col = name_start + #name, hl_group = "FlagName",
            })

            if i < #names then
                if PAD_BETWEEN > 0 then
                    vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, { virt_lines = blanks(PAD_BETWEEN) })
                end
            else
                -- bottom pad, then a fixed hint row (blank when clean, so the
                -- window never resizes as `dirty` flips on and off)
                local vlines = blanks(PAD_BOTTOM)
                vlines[#vlines + 1] = dirty()
                    and { { "    restart required for changes", "FlagHint" } }
                    or { { "", "Normal" } }
                vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, { virt_lines = vlines })
            end
        end

        vim.bo[buf].modifiable = false
    end

    local function toggle(self)
        local name = names[vim.api.nvim_win_get_cursor(self.win)[1]]
        if name then
            M.toggle(name)
            render(self.buf)
        end
    end

    local win = Snacks.win({
        title = " Flags ",
        title_pos = "center",
        border = "rounded",
        width = 44,
        height = #names + PAD_TOP + PAD_BETWEEN * (#names - 1) + PAD_BOTTOM + 1, -- +1 hint row
        wo = {
            cursorline = true,
            number = false,
            relativenumber = false,
            winbar = " ", -- top pad; one non-navigable row
            winhighlight = "Normal:NormalFloat,FloatBorder:FlagName,FloatTitle:FlagName,WinBar:NormalFloat,WinBarNC:NormalFloat",
        },
        bo = { filetype = "flags", modifiable = false },
        keys = {
            q = "close",
            ["<cr>"] = toggle,
            ["<Tab>"] = toggle,
        },
    })

    cur_win = win.win
    render(win.buf)
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
