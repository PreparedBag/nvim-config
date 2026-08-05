-- lua/config/numbase.lua
-- Self-contained number-base tooling for C (no external plugins):
--   <leader>np       toggle inline overlay showing the other two bases
--   <leader>nc       rewrite the number under the cursor in place (hex->dec->bin)
--   <leader>n{h,d,b,o}  show a conversion as a message AND copy it to clipboard

vim.opt.nrformats = { "alpha", "hex", "bin" }

local M = {}

local ns = vim.api.nvim_create_namespace("numbase_preview")
local enabled = false

-- TODO: uncomment for file specific enable
-- local filetypes = { c = true, cpp = true, h = true }

-- Find the number token spanning the cursor.
-- Returns (text, base, start_col, end_col); cols are 1-indexed inclusive.
local function number_under_cursor()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local patterns = {
        { pat = "0[xX]%x+",   base = "hex" },
        { pat = "0[bB][01]+", base = "bin" },
        { pat = "%d+",        base = "dec" },
    }
    for _, p in ipairs(patterns) do
        local init = 1
        while true do
            local s, e = line:find(p.pat, init)
            if not s then break end
            if col >= s and col <= e then
                return line:sub(s, e), p.base, s, e
            end
            init = e + 1
        end
    end
end

local function to_value(str, base)
    if base == "bin" then
        return tonumber(str:sub(3), 2) -- strip 0b, parse base 2
    end
    return tonumber(str)               -- 0x.. and decimal parse natively
end

-- How many whole bytes are needed to represent value (min 1).
local function byte_count(value)
    local bytes, limit = 1, 256
    while value >= limit do
        bytes = bytes + 1
        limit = limit * 256
    end
    return bytes
end

local function to_bin(n)
    if n == 0 then return "0b0" end
    local b = ""
    while n > 0 do
        b = (n % 2) .. b
        n = math.floor(n / 2)
    end
    return "0b" .. b
end

local function format_base(value, base)
    if base == "hex" then
        return string.format("0x%0" .. (byte_count(value) * 2) .. "X", value)
    end
    if base == "bin" then return to_bin(value) end
    if base == "oct" then return value == 0 and "0" or ("0" .. string.format("%o", value)) end
    return tostring(value)
end

-- Inline preview of the other two bases ---------------------------------------

local function preview_text(value, base)
    local hex = format_base(value, "hex")
    local dec, bin = tostring(value), to_bin(value)
    if base == "hex" then return "  " .. dec .. "  " .. bin end
    if base == "bin" then return "  " .. hex .. "  " .. dec end
    return "  " .. hex .. "  " .. bin
end

local function refresh()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    -- TODO: uncomment for file specific enable
    -- if not enabled or not filetypes[vim.bo.filetype] then return end
    if not enabled or vim.bo.buftype ~= "" then return end

    local str, base = number_under_cursor()
    if not str then return end
    local value = to_value(str, base)
    if not value then return end
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    vim.api.nvim_buf_set_extmark(0, ns, row, 0, {
        virt_text = { { preview_text(value, base), "Comment" } },
        virt_text_pos = "eol",
        hl_mode = "combine", -- let cursorline / row highlight show through
    })
end

-- In-place base cycle: hex -> dec -> bin -> hex -------------------------------

local next_base = { hex = "dec", dec = "bin", bin = "hex" }

local function cycle_base()
    local str, base, s, e = number_under_cursor()
    if not (str and s and e) then
        vim.notify("No number under cursor", vim.log.levels.WARN)
        return
    end
    local value = to_value(str, base)
    if not value then return end
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    -- set_text cols are 0-indexed, end-exclusive: [s-1, e)
    vim.api.nvim_buf_set_text(0, row, s - 1, row, e, { format_base(value, next_base[base]) })
end

-- Show a conversion as a message and copy it to the clipboard -----------------

local function show_and_copy(base)
    local str, cur_base = number_under_cursor()
    if not str then
        vim.notify("No number under cursor", vim.log.levels.WARN)
        return
    end
    local value = to_value(str, cur_base)
    if not value then
        vim.notify("Could not parse: " .. str, vim.log.levels.WARN)
        return
    end
    local out = format_base(value, base)
    -- TODO: adjust here for copying to clipboard and/or local
    vim.fn.setreg("+", out)
    vim.fn.setreg('"', out)
    vim.notify(str .. " = " .. out)
end

-- Setup -----------------------------------------------------------------------

function M.setup()
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = vim.api.nvim_create_augroup("numbase_preview", { clear = true }),
        callback = refresh,
    })

    vim.keymap.set("n", "<leader>np", function()
        enabled = not enabled
        refresh()
        vim.notify("Number base preview: " .. (enabled and "on" or "off"))
    end, { desc = "Toggle Number Base Preview" })

    vim.keymap.set("n", "<leader>nc", cycle_base,
        { desc = "Cycle Number Base (Hex/Dec/Bin)" })

    local conv = {
        nh = "hex", nd = "dec", nb = "bin", no = "oct",
    }
    for suffix, base in pairs(conv) do
        local label = base:sub(1, 1):upper() .. base:sub(2)
        vim.keymap.set("n", "<leader>" .. suffix, function() show_and_copy(base) end,
            { desc = "Base: " .. label .. " (Show + Copy)" })
    end
end

return M
