local ui = require("config.utils")

local function dap_session_active()
    local dap = package.loaded['dap']
    return dap ~= nil and dap.session() ~= nil
end

-- Async. Prompts (only if there are unsaved buffers), wipes every
-- buffer, then calls on_done(). Cancelling the prompt skips both
-- the wipe and on_done, so the caller's follow-up never runs.
local function wipe_all_buffers(on_done)
    local modified = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
            table.insert(modified, vim.api.nvim_buf_get_name(buf))
        end
    end

    local function wipe()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
        end
        on_done()
    end

    if #modified == 0 then
        wipe()
        return
    end

    ui.select(
        #modified .. " buffer(s) have unsaved changes. Save before switching sessions?",
        { "Save all", "Discard", "Cancel" },
        function(choice)
            if choice == "Save all" then
                vim.cmd("wall")
                wipe()
            elseif choice == "Discard" then
                wipe()
            end
            -- Cancel or Esc: do nothing, leave the session as-is.
        end
    )
end

-- DAP UI buffers: repl + all nvim-dap-ui panels + floats
local function is_dap_buf(buf)
    local ft = vim.bo[buf].filetype
    return ft == "dap-repl" or ft:match("^dapui_") ~= nil or ft == "dap-float"
end

local function clean_for_session()
    -- Buffers currently shown in a window (any tab).
    local visible = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        visible[vim.api.nvim_win_get_buf(win)] = true
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            local drop
            if is_dap_buf(buf) or vim.bo[buf].filetype == "oil" then
                drop = true
            elseif not visible[buf] then
                drop = not vim.bo[buf].modified -- wipe hidden, but never lose unsaved work
            else
                drop = false                    -- visible & non-DAP -> keep (help, oil, term, files)
            end

            if drop then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
        end
    end
end

local function switch_session(load_fn)
    wipe_all_buffers(function()
        load_fn()
        _G.session_directory = vim.fn.getcwd()
    end)
end

local function save_session()
    clean_for_session()
    local real_cwd = vim.fn.getcwd()
    vim.cmd('cd ' .. vim.fn.fnameescape(_G.session_directory))
    require("persistence").save()
    vim.cmd('cd ' .. vim.fn.fnameescape(real_cwd))
    vim.notify("Session saved", vim.log.levels.INFO)
end

local function save_and_quit_confirmed()
    save_session()
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
    ui.select(
        #modified .. " buffer(s) have unsaved changes:",
        { "Save all and quit", "Quit without saving", "Cancel" },
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
        ui.select(
            "Debug session still active — stop it with <Leader>dq first?",
            { "Quit anyway", "Cancel" },
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

                switch_session(function()
                    vim.cmd("silent! source " .. vim.fn.fnameescape(entry.value))
                end)
            end)

            -- <C-d>: delete the session under the cursor, then refresh
            -- the list. entry + picker are grabbed up front because
            -- the confirm is async and selection could otherwise move.
            map({ "i", "n" }, "<C-d>", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local picker = state.get_current_picker(bufnr)
                ui.confirm("Delete session '" .. entry.display .. "'?", function()
                    vim.fn.delete(entry.value)
                    picker:refresh(make_finder(), { reset_prompt = false })
                end)
            end, { desc = "Delete Session" })

            return true
        end,
    }):find()
end
_G.Session_Picker = session_picker

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
            function()
                switch_session(function() require("persistence").load() end)
            end,
            desc = "Restore Session (CWD)",
        },
        {
            "<leader>pl",
            function()
                switch_session(function() require("persistence").load({ last = true }) end)
            end,
            desc = "Restore Last Session",
        },
        {
            "<leader>pp",
            session_picker,
            desc = "Pick Session",
        },
    },
}
