local M = {}

local marker = vim.fn.stdpath("data") .. "/nvim-dev"

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
    return read()[name] or false
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

return M
