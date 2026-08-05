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
-- repo root
--
-- resolved relative to the current buffer, never cwd, so a session
-- restore or :cd can't move it out from under us. git_guard pins
-- this at invocation and hands it to the action, which threads it
-- as `cwd` through every git call — including ones that later fire
-- from a picker's prompt buffer, which has no path of its own.
-- ---------------------------------------------------------------

local function buf_root()
    return vim.fs.root(0, ".git")
end

local function git_guard(fn)
    return function()
        local root = buf_root()
        if not root then
            vim.notify("Not a git repository", vim.log.levels.INFO)
            return
        end
        fn(root)
    end
end


-- ---------------------------------------------------------------
-- synchronous git
--
-- trimmed stdout, for single-value queries. cwd falls back to
-- buf_root() for direct calls; pickers pass the pinned root.
-- ---------------------------------------------------------------

local function capture(args, cwd)
    local res = vim.system(vim.list_extend({ "git" }, args), {
        text = true,
        cwd = cwd or buf_root(),
    }):wait()
    return vim.trim(res.stdout or ""), res.code
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
-- cwd is captured here, at call time, before the async part runs.
-- ---------------------------------------------------------------

local function run(args, cwd, password)
    local env = { GIT_TERMINAL_PROMPT = "0" }
    local cleanup = function() end
    cwd = cwd or buf_root()

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
        cwd = cwd,
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

local function run_auth(args, root)
    if not ASK_PASSWORD then
        run(args, root)
        return
    end

    local ok, pw = pcall(vim.fn.inputsecret, "SSH password (Esc to cancel): ")
    vim.cmd("redraw")

    if not ok or pw == "" then
        notify("cancelled", vim.log.levels.WARN)
        return
    end

    run(args, root, pw)
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

local function log_picker(root)
    require("telescope.builtin").git_commits({
        cwd = root,
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
-- lines are read without trimming. each entry carries the pinned
-- repo root so git commands and the previewer resolve correctly
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

-- root is the pinned worktree root; it doubles as the cwd for the
-- status query and the path prefix in status_entry, replacing the
-- old rev-parse that ran at nvim's cwd.
local function status_finder(root)
    local finders = require("telescope.finders")

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
-- Unlike the branch and stash pickers (verb chosen by keymap, one
-- action on <CR>), staging is iterative: you stay in the list,
-- toggle several files against the live diff preview, then leave
-- to commit. So the actions live inside the picker rather than as
-- separate verb keymaps.
--
-- In-picker keys:
--   t        stage / unstage the file under the cursor
--   <C-a>    stage everything (git add -A)
--   <C-u>    unstage everything (git reset)
--
-- The list re-runs status after each action (reset_prompt = false
-- keeps the filter). root is pinned when the picker opens and
-- reused by every refresh and staging call.
-- ---------------------------------------------------------------

local function status_picker(root)
    local pickers = require("telescope.pickers")
    local state = require("telescope.actions.state")
    local conf = require("telescope.config").values

    -- Build a title line with branch + tracking info
    local head = capture({ "symbolic-ref", "--short", "HEAD" }, root)
    local title
    if head == "" then
        title = "⚠ DETACHED HEAD  (t: Stage/Unstage)"
    else
        -- ahead/behind counts vs upstream, if an upstream exists
        local ab = capture({ "rev-list", "--left-right", "--count", "HEAD...@{u}" }, root)
        local tracking = ""
        local ahead, behind = ab:match("(%d+)%s+(%d+)")
        if ahead then
            local parts = {}
            if tonumber(ahead) > 0 then table.insert(parts, "↑ " .. ahead) end
            if tonumber(behind) > 0 then table.insert(parts, "↓ " .. behind) end
            if #parts > 0 then tracking = " " .. table.concat(parts, " ") end
        end
        title = string.format("Git: %s%s (t: Stage/Unstage)", head, tracking)
    end

    local function refresh(bufnr)
        state.get_current_picker(bufnr):refresh(status_finder(root), { reset_prompt = false })
    end

    pickers.new({
        initial_mode = "normal",
        prompt_title = title,
    }, {
        finder = status_finder(root),
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
                    capture({ "restore", "--staged", "--", entry.path }, root)
                else
                    capture({ "add", "--", entry.path }, root)
                end
                picker:refresh(status_finder(root), { reset_prompt = false })
            end, { desc = "Stage/Unstage" })
            map({ "i", "n" }, "<C-a>", function(bufnr)
                capture({ "add", "-A" }, root)
                refresh(bufnr)
            end, { desc = "Stage All" })
            map({ "i", "n" }, "<C-u>", function(bufnr)
                capture({ "reset" }, root)
                refresh(bufnr)
            end, { desc = "Unstage All (Reset)" })
            return true
        end,
    }):find()
end


-- ---------------------------------------------------------------
-- stash pickers
--
-- the verb is chosen by keymap; the picker is then scoped to that
-- one action, which fires on <CR>. stash refs are positional, so
-- opening a fresh picker per invocation keeps the list current.
-- root is captured at open and reused by the deferred action.
--
-- stash_action_picker wires <CR> to `action`, overriding the
-- builtin apply-on-enter. stash_apply keeps that default.
-- ---------------------------------------------------------------

local function stash_action_picker(root, action)
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")

    require("telescope.builtin").git_stash({
        cwd = root,
        initial_mode = "normal",

        attach_mappings = function(_, map)
            map({ "i", "n" }, "<CR>", function(bufnr)
                local entry = state.get_selected_entry()

                if not entry then
                    return
                end

                actions.close(bufnr)
                action(entry.value)
            end)

            return true
        end,
    })
end

local function stash_apply(root)
    require("telescope.builtin").git_stash({
        cwd = root,
        initial_mode = "normal",
    })
end

local function stash_pop(root)
    stash_action_picker(root, function(ref)
        run({ "stash", "pop", ref }, root)
    end)
end

local function stash_drop(root)
    stash_action_picker(root, function(ref)
        if confirm("Drop " .. ref .. "?") then
            run({ "stash", "drop", ref }, root)
        end
    end)
end

local function stash_branch(root)
    stash_action_picker(root, function(ref)
        prompt("Branch from " .. ref .. ": ", function(name)
            run({ "stash", "branch", name, ref }, root)
        end)
    end)
end


-- ---------------------------------------------------------------
-- branch pickers
--
-- the verb is chosen by keymap; the picker is then scoped to that
-- one action, which fires on <CR>. remote entries are normalised
-- to a bare branch name, so the same action works whether a local
-- or remote row is selected.
--
-- branch_action_picker wires <CR> to `action`, overriding the
-- builtin checkout-on-enter. branch_checkout keeps that default
-- for the plain select case.
-- ---------------------------------------------------------------

local function branch_action_picker(root, action)
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")

    require("telescope.builtin").git_branches({
        cwd = root,
        initial_mode = "normal",
        show_remote_tracking_branches = true,

        attach_mappings = function(_, map)
            map({ "i", "n" }, "<CR>", function(bufnr)
                local entry = state.get_selected_entry()

                if not entry then
                    return
                end

                actions.close(bufnr)

                local name = entry.value:gsub("^remotes/", ""):gsub("^origin/", "")
                action(name)
            end)

            return true
        end,
    })
end

local function branch_checkout(root)
    require("telescope.builtin").git_branches({
        cwd = root,
        initial_mode = "normal",
        show_remote_tracking_branches = true,
    })
end

local function branch_merge(root)
    branch_action_picker(root, function(branch)
        run({ "merge", branch }, root)
    end)
end

local function branch_delete(root)
    branch_action_picker(root, function(branch)
        run({ "branch", "-d", branch }, root)
    end)
end

local function branch_force_delete(root)
    branch_action_picker(root, function(branch)
        if confirm("Force delete local branch '" .. branch .. "'?") then
            run({ "branch", "-D", branch }, root)
        end
    end)
end

local function branch_delete_origin(root)
    branch_action_picker(root, function(branch)
        if confirm("Delete '" .. branch .. "' on origin?") then
            run_auth({ "push", "origin", "--delete", branch }, root)
        end
    end)
end


-- ---------------------------------------------------------------
-- checkout
--
-- on a branch: fast-forward to the upstream tip.
-- detached: return to the remote's default branch, resolved from
-- origin/HEAD and falling back to main or master.
-- ---------------------------------------------------------------

local function default_branch(root)
    local out = capture({ "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" }, root)

    if out ~= "" then
        return (out:gsub("^origin/", ""))
    end

    for _, name in ipairs({ "main", "master" }) do
        local _, code = capture({ "show-ref", "--verify", "--quiet", "refs/heads/" .. name }, root)

        if code == 0 then
            return name
        end
    end

    return nil
end

local function checkout_head(root)
    local current = capture({ "branch", "--show-current" }, root)

    if current ~= "" then
        run({ "merge", "--ff-only", "@{u}" }, root)
        return
    end

    local target = default_branch(root)

    if not target then
        notify("no default branch found", vim.log.levels.ERROR)
        return
    end

    run({ "checkout", target }, root)
end


-- ---------------------------------------------------------------
-- discard
--
-- unrecoverable: working tree changes leave no reflog entry.
-- ---------------------------------------------------------------

local function discard_file(root)
    local file = vim.fn.expand("%:p")

    if file == "" then
        notify("no file in this buffer", vim.log.levels.ERROR)
        return
    end

    local rel = vim.fn.fnamemodify(file, ":.")

    if not confirm("Discard all changes to '" .. rel .. "'?") then
        return
    end

    run({ "restore", "--staged", "--worktree", "--", file }, root)

    vim.schedule(function()
        vim.cmd("edit!")
    end)
end

local function discard_all(root)
    vim.ui.select(
        { "Discard all tracked changes", "Discard tracked changes + remove untracked files", "Cancel" },
        { prompt = "Restore repo from HEAD:" },
        function(choice)
            if choice == "Discard all tracked changes" then
                run({ "restore", "--staged", "--worktree", "--", "." }, root)
                vim.schedule(function() vim.cmd("checktime") end)
            elseif choice == "Discard tracked changes + remove untracked files" then
                if not confirm("This also deletes UNTRACKED files — unrecoverable. Continue?") then
                    return
                end
                run({ "restore", "--staged", "--worktree", "--", "." }, root)
                run({ "clean", "-fd" }, root)
                vim.schedule(function() vim.cmd("checktime") end)
            end
            -- Cancel or dismiss: do nothing
        end
    )
end


-- ---------------------------------------------------------------
-- keymaps
--
-- git_guard resolves the buffer's repo root once and passes it in,
-- so each action (and any prompt callback that fires later) runs
-- against the root that was current at keypress.
-- ---------------------------------------------------------------

return {
    {
        'nvim-telescope/telescope.nvim',
        keys = {
            { "<leader>gs", git_guard(status_picker), desc = "Git Status" },
            { "<leader>gl", git_guard(log_picker),    desc = "Git Log" },
            { "<leader>gr", git_guard(discard_file),  desc = "Restore Buffer from HEAD" },
            { "<leader>gR", git_guard(discard_all),   desc = "Restore All from HEAD" },
            {
                "<leader>gp",
                git_guard(function(root)
                    run_auth({
                        "pull",
                    }, root)
                end),
                desc = "Pull"
            },
            {
                "<leader>gu",
                git_guard(function(root)
                    run_auth({
                        "push",
                        "-u",
                        "origin",
                        "HEAD",
                        "--follow-tags",
                    }, root)
                end),
                desc = "Push + Tags"
            },
            {
                "<leader>gf",
                git_guard(function(root)
                    run_auth({
                        "fetch",
                        "--prune",
                        "--tags",
                        "--prune-tags",
                    }, root)
                end),
                desc = "Fetch + Prune"
            },
            {
                "<leader>gc",
                git_guard(function(root)
                    prompt("Commit message: ", function(msg)
                        run({ "commit", "-m", msg }, root)
                    end)
                end),
                desc = "Commit Staged",
            },
            {
                "<leader>ga",
                git_guard(function(root)
                    prompt("Commit message (all files): ", function(msg)
                        capture({ "add", "-A" }, root)
                        run({ "commit", "-m", msg }, root)
                    end)
                end),
                desc = "Add All + Commit",
            },
            {
                "<leader>gt",
                git_guard(function(root)
                    prompt("New tag: ", function(tag)
                        run({ "tag", "-a", tag, "-m", tag }, root)
                    end)
                end),
                desc = "New Tag",
            },

            -- Stashes
            { "<leader>gzs", git_guard(stash_apply),  desc = "Select / Apply" },
            { "<leader>gzp", git_guard(stash_pop),    desc = "Pop" },
            { "<leader>gzd", git_guard(stash_drop),   desc = "Drop" },
            { "<leader>gzb", git_guard(stash_branch), desc = "Branch from Stash" },
            {
                "<leader>gzc",
                git_guard(function(root)
                    prompt("Stash message: ", function(msg)
                        run({
                            "stash",
                            "push",
                            "-m",
                            msg,
                        }, root)
                    end)
                end),
                desc = "Stash Changes",
            },

            -- Branches
            { "<leader>gbs", git_guard(branch_checkout),      desc = "Select / Checkout" },
            { "<leader>gbm", git_guard(branch_merge),         desc = "Merge" },
            { "<leader>gbd", git_guard(branch_delete),        desc = "Delete (local)" },
            { "<leader>gbD", git_guard(branch_force_delete),  desc = "Force Delete (local)" },
            { "<leader>gbo", git_guard(branch_delete_origin), desc = "Delete on Origin" },
            { "<leader>gbr", git_guard(checkout_head),        desc = "Checkout Tip" },
            {
                "<leader>gbn",
                git_guard(function(root)
                    prompt("New branch: ", function(name)
                        run({
                            "checkout",
                            "-b",
                            name,
                        }, root)
                    end)
                end),
                desc = "New",
            },
        },
    },
}
