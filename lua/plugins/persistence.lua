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

local function clean_for_session()
    -- dap UI (only if loaded)
    if package.loaded["dap"] then
        pcall(function() require("dap").repl.close() end)
    end
    if package.loaded["dapui"] then
        pcall(function() require("dapui").close() end)
    end

    -- Wipe Oil and other non-file buffers so they aren't saved into the session.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            local bt = vim.bo[buf].buftype
            local name = vim.api.nvim_buf_get_name(buf)
            -- keep only normal, named, file-backed buffers
            if bt ~= "" or name == "" or name:match("^%w+://") then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
        end
    end
end

local function save_session()
    clean_for_session()
    require("persistence").save()
    vim.notify("Session saved", vim.log.levels.INFO)
end

local function dap_session_active()
    local dap = package.loaded['dap']
    return dap ~= nil and dap.session() ~= nil
end

local function save_and_quit_confirmed()
    clean_for_session()
    require("persistence").save()
    local modified = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
            table.insert(modified, vim.api.nvim_buf_get_name(buf))
        end
    end
    if #modified == 0 then
        vim.cmd("qa")
        return
    end
    vim.ui.select(
        { "Save all and quit", "Quit without saving", "Cancel" },
        { prompt = #modified .. " buffer(s) have unsaved changes:" },
        function(choice)
            if choice == "Save all and quit" then
                vim.cmd("wqa")
            elseif choice == "Quit without saving" then
                vim.cmd("qa!")
            end
        end
    )
end

local function save_and_quit()
    if dap_session_active() then
        vim.ui.select(
            { "Quit anyway", "Cancel" },
            { prompt = "Debug session still active — stop it with <Leader>dq first?" },
            function(choice)
                if choice == "Quit anyway" then save_and_quit_confirmed() end
            end
        )
        return
    end
    save_and_quit_confirmed()
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
                _G.original_working_directory = vim.fn.getcwd()
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
