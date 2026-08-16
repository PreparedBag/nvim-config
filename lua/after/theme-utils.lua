local M = {}

local function theme_field(name, field)
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    return hl and hl[field] or nil
end

function M.theme_fg(name)
    return theme_field(name, "fg")
end

function M.theme_bg(name)
    return theme_field(name, "bg")
end

local callbacks = {}
local function run_all()
    for _, fn in ipairs(callbacks) do
        pcall(fn)
    end
end
function M.on_colorscheme(fn)
    table.insert(callbacks, fn)
    pcall(fn)
end

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("theme_utils", { clear = true }),
    callback = run_all,
})
M.on_colorscheme(function()
    -- vim.api.nvim_set_hl(0, "NormalFloat", { link = "Normal", bg = "none" })
    -- vim.api.nvim_set_hl(0, "FloatBorder", { link = "Normal", bg = "none" })
    vim.api.nvim_set_hl(0, "FloatTitle", {
        fg = M.theme_fg("Title"),
        bg = "none",
        bold = true,
        italic = true,
    })
    vim.api.nvim_set_hl(0, "Folded", { link = "CursorLine" })
end)

return M
