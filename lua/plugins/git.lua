-- ---------------------------------------------------------------
-- config
-- ---------------------------------------------------------------

local ASK_PASSWORD = true

local SEP = "\31"
local LOG_PRETTY = "--pretty=%h" .. SEP .. "%d" .. SEP .. "%s" .. SEP .. "%cr" .. SEP .. "%an"


-- ---------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------

local function notify(msg, level)
    if not msg or msg == "" then
        return
    end
    vim.notify(vim.trim(msg), level or vim.log.levels.INFO, { title = "git" })
end


-- ---------------------------------------------------------------
-- synchronous git
--
-- capture       trimmed stdout, for single-value queries
-- capture_lines raw lines, for porcelain output where leading
--               whitespace is significant
-- ---------------------------------------------------------------

local function capture(args)
    local res = vim.system(vim.list_extend({ "git" }, args), {
        text = true,
        cwd = vim.fn.getcwd(),
    }):wait()
    return vim.trim(res.stdout or ""), res.code
end

local function capture_lines(args)
    local res = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
    local out = (res.stdout or ""):gsub("\n$", "")

    if out == "" then
        return {}
    end

    return vim.split(out, "\n", { plain = true })
end


-- ---------------------------------------------------------------
-- ssh password handling
--
-- writes the password to a 0600 file inside a 0700 temp dir and
-- hands ssh an askpass script, so it never demands a TTY. the
-- returned cleanup function removes the whole directory.
-- ---------------------------------------------------------------

local function make_askpass(password)
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p", "0700")

    local pw_file = dir .. "/pw"
    local script = dir .. "/askpass.sh"

    vim.fn.writefile({ password }, pw_file)
    vim.fn.writefile({ "#!/bin/sh", "cat " .. vim.fn.shellescape(pw_file) }, script)

    vim.fn.setfperm(pw_file, "rw-------")
    vim.fn.setfperm(script, "rwx------")

    return script, function()
        vim.fn.delete(dir, "rf")
    end
end


-- ---------------------------------------------------------------
-- asynchronous git
--
-- output lands in notifications. every vim.fn / vim.cmd call must
-- stay inside vim.schedule, since on_exit is a fast event context.
-- ---------------------------------------------------------------

local function run(args, password)
    local env = { GIT_TERMINAL_PROMPT = "0" }
    local cleanup = function() end

    if password and password ~= "" then
        local script, rm = make_askpass(password)
        cleanup = rm
        env.SSH_ASKPASS = script
        env.SSH_ASKPASS_REQUIRE = "force"
        env.DISPLAY = os.getenv("DISPLAY") or ":0"
    end

    notify("git " .. table.concat(args, " "))

    vim.system(vim.list_extend({ "git" }, args), {
        text = true,
        cwd = vim.fn.getcwd(),
        env = env,
    }, function(res)
        vim.schedule(function()
            cleanup()

            local out = (res.stdout or "") .. (res.stderr or "")

            notify(
                out ~= "" and out or "ok",
                res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
            )

            if res.code == 0 then
                vim.cmd("checktime")
            end
        end)
    end)
end


-- ---------------------------------------------------------------
-- remote git
--
-- pcall catches Ctrl-C, Esc returns an empty string. both abort
-- before git runs, so a blank password never reaches the server.
-- ---------------------------------------------------------------

local function run_auth(args)
    if not ASK_PASSWORD then
        run(args)
        return
    end

    local ok, pw = pcall(vim.fn.inputsecret, "SSH password (Esc to cancel): ")
    vim.cmd("redraw")

    if not ok or pw == "" then
        notify("cancelled", vim.log.levels.WARN)
        return
    end

    run(args, pw)
end


-- ---------------------------------------------------------------
-- input helpers
-- ---------------------------------------------------------------

local function prompt(label, fn)
    vim.ui.input({ prompt = label }, function(answer)
        if answer and answer ~= "" then
            fn(answer)
        end
    end)
end

local function confirm(question)
    return vim.fn.confirm(question, "&Yes\n&No", 2) == 1
end


-- ---------------------------------------------------------------
-- highlight groups
--
-- log colors follow git's own convention: tags yellow, remotes
-- red, local branches green. redefined on colorscheme change so
-- they track the active theme.
-- ---------------------------------------------------------------

local function theme_fg(name)
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    return hl and hl.fg or nil
end

local function define_highlights()
    vim.api.nvim_set_hl(0, "GitLogHash", { fg = theme_fg("Number") })
    vim.api.nvim_set_hl(0, "GitLogHead", { fg = theme_fg("Constant"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogTag", { fg = theme_fg("WarningMsg"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogRemote", { fg = theme_fg("ErrorMsg"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogBranch", { fg = theme_fg("String"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogMeta", { fg = theme_fg("Comment") })

    vim.api.nvim_set_hl(0, "GitStatusStaged", { fg = theme_fg("String"), bold = true })
    vim.api.nvim_set_hl(0, "GitStatusUnstaged", { fg = theme_fg("WarningMsg"), bold = true })
    vim.api.nvim_set_hl(0, "GitStatusNone", { fg = theme_fg("Comment") })
end

define_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = define_highlights })


-- ---------------------------------------------------------------
-- log picker
--
-- decorations arrive from %d and are split into individual refs
-- so each can be colored by kind. the hash must stay in `value`
-- or telescope's checkout actions break.
-- ---------------------------------------------------------------

local function ref_hl(ref)
    if ref:match("^HEAD") then
        return "GitLogHead"
    elseif ref:match("^tag:") then
        return "GitLogTag"
    elseif ref:match("^origin/") then
        return "GitLogRemote"
    end

    return "GitLogBranch"
end

local function log_display(entry)
    local chunks, highlights, col = {}, {}, 0

    local function add(text, group)
        if text == "" then
            return
        end

        table.insert(chunks, text)

        if group then
            table.insert(highlights, { { col, col + #text }, group })
        end

        col = col + #text
    end

    add(entry.hash, "GitLogHash")
    add(" ")

    for i, ref in ipairs(entry.refs) do
        add(ref, ref_hl(ref))
        add(i < #entry.refs and ", " or " ", "GitLogMeta")
    end

    add(entry.msg)
    add(" (" .. entry.when .. ") <" .. entry.author .. ">", "GitLogMeta")

    return table.concat(chunks), highlights
end

local function log_entry(line)
    local parts = vim.split(line, SEP, { plain = true })
    local deco = (parts[2] or ""):gsub("^%s*%(", ""):gsub("%)%s*$", "")
    local refs = {}

    if deco ~= "" then
        for _, ref in ipairs(vim.split(deco, ", ", { plain = true })) do
            table.insert(refs, vim.trim(ref))
        end
    end

    return {
        value = parts[1],
        hash = parts[1],
        refs = refs,
        msg = parts[3] or "",
        when = parts[4] or "",
        author = parts[5] or "",
        ordinal = table.concat(parts, " "),
        display = log_display,
    }
end

local function log_picker()
    require("telescope.builtin").git_commits({
        initial_mode = "normal",
        entry_maker = log_entry,
        git_command = {
            "git", "log", LOG_PRETTY,
            "--decorate=short",
            "--abbrev-commit",
            "--", ".",
        },
    })
end


-- ---------------------------------------------------------------
-- status highlights
-- ---------------------------------------------------------------

local function define_status_hl()
    local function fg(name)
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        return hl and hl.fg or nil
    end

    vim.api.nvim_set_hl(0, "GitStatusStaged", { fg = fg("String"), bold = true })
    vim.api.nvim_set_hl(0, "GitStatusUnstaged", { fg = fg("WarningMsg"), bold = true })
    vim.api.nvim_set_hl(0, "GitStatusNone", { fg = fg("Comment") })
end

define_status_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = define_status_hl })


-- ---------------------------------------------------------------
-- status entries
--
-- porcelain gives two columns per file: index (staged) then
-- worktree (unstaged). leading whitespace is significant, so raw
-- lines are read without trimming. each entry carries the repo
-- root so git commands and the previewer resolve correctly
-- regardless of nvim's cwd.
-- ---------------------------------------------------------------

local function status_display(entry)
    local staged = entry.x ~= " " and entry.x or "·"
    local unstaged = entry.y ~= " " and entry.y or "·"

    local text = staged .. " " .. unstaged .. "  " .. entry.rel

    return text, {
        { { 0, 1 }, entry.x ~= " " and "GitStatusStaged" or "GitStatusNone" },
        { { 2, 3 }, entry.y ~= " " and "GitStatusUnstaged" or "GitStatusNone" },
    }
end

local function status_entry(root)
    return function(line)
        local x, y = line:sub(1, 1), line:sub(2, 2)
        local rel = line:sub(4)

        rel = rel:match("%->%s*(.+)$") or rel
        rel = rel:gsub('^"(.*)"$', "%1")

        return {
            value = rel,
            rel = rel,
            path = root .. "/" .. rel,
            root = root,
            x = x,
            y = y,
            ordinal = rel,
            display = status_display,
        }
    end
end

local function status_finder()
    local finders = require("telescope.finders")
    local root = capture({ "rev-parse", "--show-toplevel" })

    local res = vim.system({ "git", "status", "--porcelain=v1" },
        { text = true, cwd = root }):wait()

    local out = (res.stdout or ""):gsub("\n$", "")
    local lines = out ~= "" and vim.split(out, "\n", { plain = true }) or {}

    return finders.new_table({
        results = lines,
        entry_maker = status_entry(root),
    })
end


-- ---------------------------------------------------------------
-- diff previewer
--
-- staged files show the cached diff, unstaged show the worktree
-- diff, untracked show raw contents. all run at the repo root so
-- git resolves the paths. filetype=diff gives red/green coloring.
-- ---------------------------------------------------------------

local previewers = require("telescope.previewers")

local diff_previewer = previewers.new_buffer_previewer({
    title = "Git Diff",
    define_preview = function(self, entry)
        local buf = self.state.bufnr

        local cmd
        if entry.x == "?" then
            cmd = { "git", "show", ":" }
        end

        if entry.x ~= " " and entry.x ~= "?" then
            cmd = { "git", "diff", "--cached", "--", entry.rel }
        elseif entry.x == "?" then
            cmd = { "cat", entry.path }
        else
            cmd = { "git", "diff", "--", entry.rel }
        end

        vim.system(cmd, { text = true, cwd = entry.root }, function(res)
            local text = (res.stdout or "")
            local lines = vim.split(text, "\n", { plain = true })

            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                    vim.bo[buf].filetype = "diff"
                end
            end)
        end)
    end,
})


-- ---------------------------------------------------------------
-- status picker
--
-- t stages / unstages the file under the cursor. after the list
-- refreshes, the cursor is re-placed on the same file by path,
-- since staging can change its sort position.
-- ---------------------------------------------------------------

local function status_picker()
    local pickers = require("telescope.pickers")
    local state = require("telescope.actions.state")
    local conf = require("telescope.config").values

    local function refresh(bufnr)
        state.get_current_picker(bufnr):refresh(status_finder(), { reset_prompt = false })
    end

    pickers.new({
        initial_mode = "normal",
        prompt_title = "Git Status  (t: stage/unstage)",
    }, {
        finder = status_finder(),
        sorter = conf.generic_sorter({}),
        previewer = diff_previewer,

        attach_mappings = function(_, map)
            map("n", "t", function(bufnr)
                local picker = state.get_current_picker(bufnr)
                local entry = state.get_selected_entry()

                if not entry then
                    return
                end

                local is_staged = entry.x ~= " " and entry.x ~= "?"

                if is_staged then
                    capture({ "restore", "--staged", "--", entry.path })
                else
                    capture({ "add", "--", entry.path })
                end

                picker:refresh(status_finder(), { reset_prompt = false })
            end)
            map({ "i", "n" }, "<C-a>", function(bufnr)
                capture({ "add", "-A" })
                refresh(bufnr)
            end)

            map({ "i", "n" }, "<C-u>", function(bufnr)
                capture({ "reset" })
                refresh(bufnr)
            end)

            return true
        end,
    }):find()
end


-- ---------------------------------------------------------------
-- stash picker
--
-- stash refs are positional, so the picker closes after every
-- action to force a fresh list on the next invocation.
-- ---------------------------------------------------------------

local function stash_picker()
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")

    builtin.git_stash({
        initial_mode = "normal",

        attach_mappings = function(_, map)
            local function on(fn)
                return function(bufnr)
                    local entry = state.get_selected_entry()

                    if not entry then
                        return
                    end

                    actions.close(bufnr)
                    fn(entry.value)
                end
            end

            map({ "i", "n" }, "<C-p>", on(function(ref)
                run({ "stash", "pop", ref })
            end))

            map({ "i", "n" }, "<C-d>", on(function(ref)
                if confirm("Drop " .. ref .. "?") then
                    run({ "stash", "drop", ref })
                end
            end))

            map({ "i", "n" }, "<C-b>", on(function(ref)
                prompt("Branch from " .. ref .. ": ", function(name)
                    run({ "stash", "branch", name, ref })
                end)
            end))

            return true
        end,
    })
end


-- ---------------------------------------------------------------
-- branch picker
--
-- remote entries are normalised to a bare branch name, so the
-- same action works whether a local or remote row is selected.
-- ---------------------------------------------------------------

local function branch_picker()
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")

    builtin.git_branches({
        initial_mode = "normal",
        show_remote_tracking_branches = true,

        attach_mappings = function(_, map)
            local function on(fn)
                return function(bufnr)
                    local entry = state.get_selected_entry()

                    if not entry then
                        return
                    end

                    actions.close(bufnr)

                    local name = entry.value:gsub("^remotes/", ""):gsub("^origin/", "")
                    fn(name)
                end
            end

            map({ "i", "n" }, "<C-y>", on(function(branch)
                run({ "merge", branch })
            end))

            map({ "i", "n" }, "<C-d>", on(function(branch)
                run({ "branch", "-d", branch })
            end))

            map({ "i", "n" }, "<C-x>", on(function(branch)
                if confirm("Force delete local branch '" .. branch .. "'?") then
                    run({ "branch", "-D", branch })
                end
            end))

            map({ "i", "n" }, "<C-o>", on(function(branch)
                if confirm("Delete '" .. branch .. "' on origin?") then
                    run_auth({ "push", "origin", "--delete", branch })
                end
            end))

            return true
        end,
    })
end


-- ---------------------------------------------------------------
-- checkout
--
-- on a branch: fast-forward to the upstream tip.
-- detached: return to the remote's default branch, resolved from
-- origin/HEAD and falling back to main or master.
-- ---------------------------------------------------------------

local function default_branch()
    local out = capture({ "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })

    if out ~= "" then
        return (out:gsub("^origin/", ""))
    end

    for _, name in ipairs({ "main", "master" }) do
        local _, code = capture({ "show-ref", "--verify", "--quiet", "refs/heads/" .. name })

        if code == 0 then
            return name
        end
    end

    return nil
end

local function checkout_head()
    local current = capture({ "branch", "--show-current" })

    if current ~= "" then
        run({ "merge", "--ff-only", "@{u}" })
        return
    end

    local target = default_branch()

    if not target then
        notify("no default branch found", vim.log.levels.ERROR)
        return
    end

    run({ "checkout", target })
end


-- ---------------------------------------------------------------
-- discard
--
-- unrecoverable: working tree changes leave no reflog entry.
-- ---------------------------------------------------------------

local function discard_file()
    local file = vim.fn.expand("%:p")

    if file == "" then
        notify("no file in this buffer", vim.log.levels.ERROR)
        return
    end

    local rel = vim.fn.fnamemodify(file, ":.")

    if not confirm("Discard all changes to '" .. rel .. "'?") then
        return
    end

    run({ "restore", "--staged", "--worktree", "--", file })

    vim.schedule(function()
        vim.cmd("edit!")
    end)
end


-- ---------------------------------------------------------------
-- keymaps
-- ---------------------------------------------------------------

return {
    {
        'nvim-telescope/telescope.nvim',
        keys = {
            { "<leader>gs", status_picker, desc = "Git status" },
            { "<leader>gl", log_picker,    desc = "Git log" },
            { "<leader>gb", branch_picker, desc = "Git branches" },
            { "<leader>gz", stash_picker,  desc = "Git stashes" },

            {
                "<leader>gZ",
                function()
                    prompt("Stash message: ", function(msg)
                        run({ "stash", "push", "-m", msg })
                    end)
                end,
                desc = "Stash changes",
            },

            { "<leader>gr", checkout_head,                                               desc = "Checkout branch tip" },

            {
                "<leader>gn",
                function()
                    prompt("New branch: ", function(name)
                        run({ "checkout", "-b", name })
                    end)
                end,
                desc = "New branch",
            },

            {
                "<leader>gc",
                function()
                    prompt("Commit message: ", function(msg)
                        run({ "commit", "-m", msg })
                    end)
                end,
                desc = "Commit staged",
            },

            {
                "<leader>ga",
                function()
                    prompt("Commit message (all files): ", function(msg)
                        capture({ "add", "-A" })
                        run({ "commit", "-m", msg })
                    end)
                end,
                desc = "Add all + commit",
            },

            {
                "<leader>gt",
                function()
                    prompt("New tag: ", function(tag)
                        run({ "tag", "-a", tag, "-m", tag })
                    end)
                end,
                desc = "New tag",
            },

            { "<leader>gx", discard_file,                                                desc = "Discard changes to file" },

            { "<leader>gp", function() run_auth({ "push" }) end,                         desc = "Push" },
            { "<leader>gP", function() run_auth({ "pull" }) end,                         desc = "Pull" },
            { "<leader>gu", function() run_auth({ "push", "--follow-tags" }) end,        desc = "Push + tags" },
            { "<leader>gU", function() run_auth({ "push", "-u", "origin", "HEAD" }) end, desc = "Push + set upstream" },
            { "<leader>gf", function() run_auth({ "fetch", "--prune", "--tags" }) end,   desc = "Fetch + prune" },
        },
    },
}
