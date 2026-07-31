-- Number-base tooling for C:
--   nvim-conv — prints a conversion as a message (non-destructive lookup)
--   preview   — custom: <leader>np toggles an inline overlay showing the other
--               two bases next to the number under the cursor
--   cycle     — custom: <leader>nt rewrites the number under the cursor in
--               place, cycling hex -> dec -> bin

-------------------------------------------------------------------------------
-- Custom base tooling (shared parser)
-------------------------------------------------------------------------------
local mod = {}
do
    local ns = vim.api.nvim_create_namespace("numbase_preview")
    local enabled = false
    local filetypes = { c = true, cpp = true, h = true } -- edit to taste

    -- Find the number token spanning the cursor.
    -- Returns (text, base, start_col, end_col) with 1-indexed inclusive cols.
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
        if base == "hex" then return string.format("0x%X", value) end
        if base == "bin" then return to_bin(value) end
        if base == "oct" then return value == 0 and "0" or ("0" .. string.format("%o", value)) end
        return tostring(value)
    end

    -- Inline preview of the other two bases -----------------------------------

    local function preview_text(value, base)
        local hex, dec, bin = string.format("0x%X", value), tostring(value), to_bin(value)
        if base == "hex" then return "  " .. dec .. "  " .. bin end
        if base == "bin" then return "  " .. hex .. "  " .. dec end
        return "  " .. hex .. "  " .. bin
    end

    local function refresh()
        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
        if not enabled or not filetypes[vim.bo.filetype] then return end
        local str, base = number_under_cursor()
        if not str then return end
        local value = to_value(str, base)
        if not value then return end
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        vim.api.nvim_buf_set_extmark(0, ns, row, 0, {
            virt_text = { { preview_text(value, base), "Comment" } },
            virt_text_pos = "eol",
        })
    end

    -- In-place base cycle: hex -> dec -> bin -> hex ---------------------------

    local next_base = { hex = "dec", dec = "bin", bin = "hex" }

    local function cycle_base()
        local str, base, s, e = number_under_cursor()
        if not str then
            vim.notify("No number under cursor", vim.log.levels.WARN)
            return
        end
        local value = to_value(str, base)
        if not value then return end
        local replacement = format_base(value, next_base[base])
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        -- set_text cols are 0-indexed, end-exclusive: [s-1, e)
        vim.api.nvim_buf_set_text(0, row, s - 1, row, e, { replacement })
    end

    -- Copy the number under the cursor, formatted in `base`, to the system clipboard.
    function mod.copy(base)
        local str, cur_base = number_under_cursor()
        if not str then
            vim.notify("No number under cursor", vim.log.levels.WARN)
            return
        end
        local value = to_value(str, cur_base)
        if not value then return end
        -- NOTE: switch between copy to system clipboard or local register
        vim.fn.setreg("+", format_base(value, base))
        vim.fn.setreg('"', format_base(value, base))
    end

    -- Registered from the nvim-conv spec's init so it exists at startup.
    function mod.setup()
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = vim.api.nvim_create_augroup("numbase_preview", { clear = true }),
            callback = refresh,
        })
        vim.keymap.set("n", "<leader>np", function()
            enabled = not enabled
            refresh()
            vim.notify("Number Base Preview: " .. (enabled and "on" or "off"))
        end, { desc = "Toggle number base preview" })
        vim.keymap.set("n", "<leader>nt", cycle_base,
            { desc = "Cycle Number Base (Hex/Dec/Bin)" })
    end
end

-- Run an nvim-conv command on the number under the cursor.
-- Run an nvim-conv command on the number under the cursor, and copy the result.
local function conv(cmd, base)
    return function()
        vim.cmd(cmd .. " " .. vim.fn.expand("<cword>")) -- shows the popup/message
        mod.copy(base)                                   -- copies to clipboard
    end
end

-------------------------------------------------------------------------------
-- Plugin specs
-------------------------------------------------------------------------------
return {
    {
        "simonefranza/nvim-conv",
        cmd = { "ConvDec", "ConvHex", "ConvOct", "ConvBin", "ConvStr", "ConvBytes" },
        keys = {
            { "<leader>nh", conv("ConvHex", "hex"), desc = "Display Hex + Copy" },
            { "<leader>nd", conv("ConvDec", "dec"), desc = "Display Decimal + Copy" },
            { "<leader>nb", conv("ConvBin", "bin"), desc = "Display Binary + Copy" },
            { "<leader>no", conv("ConvOct", "oct"), desc = "Display Octal + Copy" },
        },
        init = function()
            vim.g.conv_precision = 2
            mod.setup() -- wires up the custom <leader>np overlay and <leader>nt cycle
        end,
    },
}
