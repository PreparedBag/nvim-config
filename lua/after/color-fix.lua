vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { link = "Normal" })
vim.api.nvim_set_hl(0, "NoiceCmdlineIcon", { link = "Normal" })
vim.api.nvim_set_hl(0, "HarpoonNormalBorder", { link = "Normal" })
vim.api.nvim_set_hl(0, "DapUIWindowSeparator", { fg = "NONE", bg = "NONE" })
vim.api.nvim_set_hl(0, "Folded", { link = "CursorLine" })

local function theme_fg(name)
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    return hl and hl.fg or nil
end

vim.api.nvim_set_hl(0, "GitLogHash", { fg = theme_fg("Number") })
vim.api.nvim_set_hl(0, "GitLogHead", { fg = theme_fg("Constant"), bold = true })
vim.api.nvim_set_hl(0, "GitLogTag", { fg = theme_fg("WarningMsg"), bold = true })
vim.api.nvim_set_hl(0, "GitLogRemote", { fg = theme_fg("ErrorMsg"), bold = true })
vim.api.nvim_set_hl(0, "GitLogBranch", { fg = theme_fg("String"), bold = true })
vim.api.nvim_set_hl(0, "GitLogMeta", { fg = theme_fg("Comment") })

vim.api.nvim_set_hl(0, "GitStatusStaged", { fg = theme_fg("String"), bold = true })
vim.api.nvim_set_hl(0, "GitStatusUnstaged", { fg = theme_fg("WarningMsg"), bold = true })
vim.api.nvim_set_hl(0, "GitStatusNone", { fg = theme_fg("Comment") })

vim.api.nvim_set_hl(0, "DapWinBar", {
    fg = "#89b4fa",
    bold = true,
})

vim.api.nvim_set_hl(0, "DapWinBarNC", {
    fg = "#6c7086",
})
