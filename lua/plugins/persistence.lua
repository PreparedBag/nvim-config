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

-- Close transient plugin UIs before saving a session, but only if they're
-- already loaded — never force-load them here (that triggers the config
-- chain and can hit a circular require).
local function clean_for_session()
    if package.loaded["dapui"] then
        pcall(function() require("dapui").close() end)
    end
    if package.loaded["dap"] then
        pcall(function() require("dap").repl.close() end)
    end
end

local function save_session()
    clean_for_session()
    require("persistence").save()
end

local function save_and_quit()
    clean_for_session()
    require("persistence").save()
    vim.schedule(function() vim.cmd("confirm qa") end)
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
    config = function(_, opts)
        require("persistence").setup(opts)
        -- Disable auto-save-on-exit. Sessions are only written when you
        -- explicitly call save() via <leader>ps or <leader>pq.
        require("persistence").stop()
    end,
    keys = {
        { "<leader>ps", save_session,  desc = "Save Session" },
        { "<leader>pq", save_and_quit, desc = "Save Session and Quit" },
        {
            "<leader>pr",
            function() require("persistence").load() end,
            desc = "Restore Session (CWD)",
        },
        {
            "<leader>pp",
            session_picker,
            desc = "Pick Session",
        },
    },
}
