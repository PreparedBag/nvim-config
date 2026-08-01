-- ---------------------------------------------------------------
-- telescope picker over persistence's saved session files
--
-- session filenames encode the project path with % as the
-- separator; decode it back for display. selecting an entry
-- sources that session file to restore its buffers and layout.
-- telescope is guaranteed loaded here via the spec's `dependencies`.
-- ---------------------------------------------------------------

local function confirm(question)
    return vim.fn.confirm(question, "&Yes\n&No", 2) == 1
end

-- Read the saved sessions off disk, decoding the %-encoded path for display.
local function session_entries()
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
    return entries
end

-- Build a fresh finder from the current on-disk sessions.
-- Called on open and again on refresh after a delete.
local function make_finder()
    return require("telescope.finders").new_table({
        results = session_entries(),
        entry_maker = function(e)
            return { value = e.file, display = e.display, ordinal = e.display }
        end,
    })
end

local function session_picker()
    local pickers = require("telescope.pickers")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")

    if #session_entries() == 0 then
        vim.notify("No saved sessions", vim.log.levels.INFO)
        return
    end

    pickers.new({
        initial_mode = "normal",
        prompt_title = "Sessions",
    }, {
        finder = make_finder(),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
            -- <CR>: source the selected session file
            actions.select_default:replace(function(bufnr)
                local entry = state.get_selected_entry()
                actions.close(bufnr)
                if not entry then return end
                vim.cmd("silent! source " .. vim.fn.fnameescape(entry.value))
            end)

            -- <C-d>: delete the session under the cursor, then refresh the list
            map({ "i", "n" }, "<C-d>", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                if not confirm("Delete session '" .. entry.display .. "'?") then return end

                vim.fn.delete(entry.value)
                state.get_current_picker(bufnr):refresh(make_finder(), { reset_prompt = false })
            end, { desc = "Delete Session" })

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
