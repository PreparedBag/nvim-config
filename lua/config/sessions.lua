local ui = require("config.utils")
local uv = vim.uv or vim.loop

local SESSIONS_DIR = vim.fn.stdpath("state") .. "/sessions/"
local NAMES_FILE = SESSIONS_DIR .. "names.json"
vim.fn.mkdir(SESSIONS_DIR, "p")

local function dap_session_active()
    local dap = package.loaded['dap']
    return dap ~= nil and dap.session() ~= nil
end

local function modified_buffers()
    local modified = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
            table.insert(modified, vim.api.nvim_buf_get_name(buf))
        end
    end
    return modified
end

local function current_branch()
    if vim.fn.isdirectory(".git") == 0 and vim.fn.filereadable(".git") == 0 then
        return nil
    end
    local branch = vim.fn.systemlist("git branch --show-current")[1]
    return vim.v.shell_error == 0 and branch or nil
end

-- Same encoding persistence.nvim used (path separators -> %%), so
-- any session files it already saved keep loading correctly.
local function session_file(opts)
    opts = opts or {}
    local name = vim.fn.getcwd():gsub("[\\/:]+", "%%")
    if opts.branch ~= false then
        local branch = current_branch()
        if branch and branch ~= "main" and branch ~= "master" then
            name = name .. "%%" .. branch:gsub("[\\/:]+", "%%")
        end
    end
    return SESSIONS_DIR .. name .. ".vim"
end

local function load_session(file)
    if file and vim.fn.filereadable(file) ~= 0 then
        vim.cmd("silent! source " .. vim.fn.fnameescape(file))
    end
end

local function load_current()
    local file = session_file()
    if vim.fn.filereadable(file) == 0 then
        file = session_file({ branch = false })
    end
    load_session(file)
end

local function load_last()
    local files = vim.fn.glob(SESSIONS_DIR .. "*.vim", true, true)
    table.sort(files, function(a, b)
        return uv.fs_stat(a).mtime.sec > uv.fs_stat(b).mtime.sec
    end)
    load_session(files[1])
end

-- ---------------------------------------------------------------
-- Custom names - a small JSON sidecar mapping session file path to
-- a user-chosen display name. The filename itself stays CWD-based
-- (load_current/load_last depend on that); this is purely cosmetic
-- metadata for the picker.
-- ---------------------------------------------------------------

local function load_names()
    if vim.fn.filereadable(NAMES_FILE) == 0 then
        return {}
    end
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(NAMES_FILE), "\n"))
    return ok and data or {}
end

local function save_names(names)
    vim.fn.writefile({ vim.json.encode(names) }, NAMES_FILE)
end

local function update_session_name()
    local file = session_file()
    local names = load_names()
    _G.session_name = names[file] or vim.fn.fnamemodify(_G.session_directory or vim.fn.getcwd(), ":t")
end

local function is_dap_buf(buf)
    local ft = vim.bo[buf].filetype
    return ft == "dap-repl" or ft:match("^dapui_") ~= nil or ft == "dap-float"
end

local function clean_for_session()
    local visible = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        visible[vim.api.nvim_win_get_buf(win)] = true
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            local drop
            if is_dap_buf(buf) then
                drop = true
            elseif not visible[buf] then
                drop = not vim.bo[buf].modified
            else
                drop = false
            end

            if drop then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
        end
    end
end

local function save_session()
    clean_for_session()
    local real_cwd = vim.fn.getcwd()
    vim.cmd('cd ' .. vim.fn.fnameescape(_G.session_directory))
    vim.cmd("mks! " .. vim.fn.fnameescape(session_file()))
    vim.cmd('cd ' .. vim.fn.fnameescape(real_cwd))
    vim.notify("Session saved", vim.log.levels.INFO)
end

local function rename_current_session()
    local file = session_file()
    if vim.fn.filereadable(file) == 0 then
        save_session()
    end

    vim.ui.input({ prompt = "Session name: " }, function(new_name)
        if not new_name or new_name == "" then return end
        local names = load_names()
        names[file] = new_name
        save_names(names)
        update_session_name()
        vim.notify("Renamed session to: " .. new_name)
    end)
end

local function wipe_all_buffers(on_done)
    local modified = modified_buffers()

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

    ui.dialog(
        #modified .. " buffer(s) have unsaved changes. Save before switching sessions?",
        { "Save all", "Discard", "Cancel" },
        modified,
        function(choice)
            if choice == "Save all" then
                vim.cmd("wall")
                wipe()
            elseif choice == "Discard" then
                wipe()
            end
        end
    )
end

local function switch_session(load_fn)
    wipe_all_buffers(function()
        load_fn()
        _G.session_directory = vim.fn.getcwd()
        update_session_name()
        require("config.project").load_commands()
    end)
end

local function save_and_quit_confirmed()
    save_session()
    local modified = modified_buffers()
    if #modified == 0 then
        vim.cmd("qa")
        return
    end
    ui.dialog(
        #modified .. " buffer(s) have unsaved changes",
        { "Save all and quit", "Quit without saving", "Cancel" },
        modified,
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

-- ---------------------------------------------------------------
-- Picker: column 1 = name (custom if set, else last path segment),
-- column 2 = full cwd. Padded to line up like a real table.
-- ---------------------------------------------------------------

local NAME_COL_WIDTH = 28

local function session_display(entry)
    local text = string.format("%-" .. NAME_COL_WIDTH .. "s  %s", entry.name, entry.cwd)
    return text, {
        { { 0, #entry.name }, "Identifier" },
        { { NAME_COL_WIDTH + 2, #text }, "Comment" },
    }
end

local function session_entries()
    local names = load_names()
    local files = vim.fn.glob(SESSIONS_DIR .. "*.vim", true, true)
    local entries = {}
    for _, file in ipairs(files) do
        local raw = vim.fn.fnamemodify(file, ":t:r")
        local cwd = raw:gsub("%%%%", "/"):gsub("%%", "/")
        local name = names[file] or vim.fn.fnamemodify(cwd, ":t")
        table.insert(entries, { file = file, name = name, cwd = cwd })
    end
    return entries
end

local function make_finder()
    return require("telescope.finders").new_table({
        results = session_entries(),
        entry_maker = function(e)
            return {
                value = e.file,
                name = e.name,
                cwd = e.cwd,
                ordinal = e.name .. " " .. e.cwd,
                display = session_display,
            }
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
            actions.select_default:replace(function(bufnr)
                local entry = state.get_selected_entry()
                actions.close(bufnr)
                if not entry then return end

                switch_session(function()
                    vim.cmd("silent! source " .. vim.fn.fnameescape(entry.value))
                end)
            end)

            map({ "i", "n" }, "<C-d>", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local picker = state.get_current_picker(bufnr)
                ui.confirm("Delete session '" .. entry.name .. "'?", function()
                    vim.fn.delete(entry.value)
                    local names = load_names()
                    names[entry.value] = nil
                    save_names(names)
                    picker:refresh(make_finder(), { reset_prompt = false })
                end)
            end, { desc = "Delete Session" })

            return true
        end,
    }):find()
end

_G.Session_Picker = session_picker
_G.session_directory = vim.fn.getcwd()
update_session_name()

vim.keymap.set("n", "<leader>ps", save_session, { desc = "Save Session" })
vim.keymap.set("n", "<leader>pq", save_and_quit, { desc = "Save Session and Quit" })
vim.keymap.set("n", "<leader>pn", rename_current_session, { desc = "Rename Session" })
vim.keymap.set("n", "<leader>pr", function()
    switch_session(load_current)
end, { desc = "Restore Session (CWD)" })
vim.keymap.set("n", "<leader>pl", function()
    switch_session(load_last)
end, { desc = "Restore Last Session" })
vim.keymap.set("n", "<leader>pp", session_picker, { desc = "Pick Session" })
