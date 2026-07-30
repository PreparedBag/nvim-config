-- ---------------------------------------------------------------
-- telescope picker over persistence's saved session files
--
-- session filenames encode the project path with % as the
-- separator; decode it back for display. selecting an entry
-- sources that session file to restore its buffers and layout.
-- ---------------------------------------------------------------

local function confirm(question)
    return vim.fn.confirm(question, "&Yes\n&No", 2) == 1
end

local function session_picker()
    local ok = pcall(require, "telescope")
    if not ok then
        vim.notify("telescope not available", vim.log.levels.ERROR)
        return
    end
    require("lazy").load({ plugins = { "telescope.nvim" } })

    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")

    local dir = require("persistence.config").options.dir
    local files = vim.fn.glob(dir .. "*.vim", true, true)

    if #files == 0 then
        vim.notify("No saved sessions", vim.log.levels.INFO)
        return
    end

    local entries = {}
    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        table.insert(entries, {
            file = file,
            display = name:gsub("%%%%", "/"):gsub("%%", "/"),
        })
    end

    pickers.new({
        initial_mode = "normal",
        prompt_title = "Sessions",
    }, {
        finder = finders.new_table({
            results = entries,
            entry_maker = function(e)
                return {
                    value = e.file,
                    display = e.display,
                    ordinal = e.display,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function(bufnr)
                local entry = state.get_selected_entry()
                actions.close(bufnr)
                if not entry then
                    return
                end
                vim.cmd("silent! source " .. vim.fn.fnameescape(entry.value))
            end)

            -- delete the session file under the cursor, refresh the list
            map({ "i", "n" }, "<C-d>", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then
                    return
                end

                if not confirm("Delete session '" .. entry.display .. "'?") then
                    return
                end

                vim.fn.delete(entry.value)

                -- rebuild the entry list from what's left on disk
                local dir = require("persistence.config").options.dir
                local files = vim.fn.glob(dir .. "*.vim", true, true)
                local entries = {}
                for _, file in ipairs(files) do
                    local name = vim.fn.fnamemodify(file, ":t:r")
                    table.insert(entries, {
                        file = file,
                        display = name:gsub("%%%%", "/"):gsub("%%", "/"),
                    })
                end

                local picker = state.get_current_picker(bufnr)
                picker:refresh(
                    require("telescope.finders").new_table({
                        results = entries,
                        entry_maker = function(e)
                            return {
                                value = e.file,
                                display = e.display,
                                ordinal = e.display,
                            }
                        end,
                    }),
                    { reset_prompt = false }
                )
            end)

            return true
        end,
    }):find()
end


return {
    "folke/persistence.nvim",
    event = "BufReadPre",
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {},
    keys = {
        {
            "<leader>pl",
            function() require("persistence").load() end,
            desc = "Restore Session (CWD)",
        },
        {
            "<leader>pr",
            function() require("persistence").load({ last = true }) end,
            desc = "Restore Last Session",
        },
        {
            "<leader>ps",
            function() require("persistence").save() end,
            desc = "Save Session",
        },
        {
            "<leader>pd",
            function() require("persistence").stop() end,
            desc = "Stop Saving Session",
        },
        {
            "<leader>pq",
            function()
                require("persistence").save()
                vim.cmd("qa")
            end,
            desc = "Save Session and Quit",
        },
        {
            "<leader>pp",
            session_picker,
            desc = "Pick Session",
        },
    },
}
