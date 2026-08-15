local ASK_PASSWORD = true
local LOG_LIMIT = 300

local SEP = "\31"
local LOG_PRETTY = "--pretty=%h" .. SEP .. "%d" .. SEP .. "%s" .. SEP .. "%cr" .. SEP .. "%an"

local function notify(msg, level)
    if not msg or msg == "" then
        return
    end
    vim.notify(vim.trim(msg), level or vim.log.levels.INFO, { title = "git" })
end

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

local function capture(args, cwd)
    local res = vim.system(vim.list_extend({ "git" }, args), {
        text = true,
        cwd = cwd or buf_root(),
    }):wait()
    return vim.trim(res.stdout or ""), res.code
end

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

local function confirm_file_list(title, files, on_confirm)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")

    pickers.new({
        initial_mode = "normal",
        prompt_title = title .. " (y to confirm)",
    }, {
        finder = finders.new_table({ results = files }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
            actions.select_default:replace(function(bufnr)
                actions.close(bufnr)
            end)
            map({ "i", "n" }, "y", function(bufnr)
                actions.close(bufnr)
                on_confirm()
            end, { desc = "Confirm" })
            return true
        end,
    }):find()
end

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

local function run_auth(args, root, title)
    if not ASK_PASSWORD then
        run(args, root)
        return
    end

    local ok, pw = pcall(vim.fn.inputsecret, title .. ": Enter Password (Esc to cancel): ")
    vim.cmd("redraw")

    if not ok or pw == "" then
        notify("cancelled", vim.log.levels.WARN)
        return
    end

    run(args, root, pw)
end

local function ask(text, fn, is_confirm)
    if is_confirm then
        Snacks.input({
            prompt = text .. " (y/n)",
            win = {
                width = 80,
                keys = {
                    y = { "y", "confirm", mode = { "n", "i" } },
                    n = { "n", "cancel", mode = { "n", "i" } },
                },
            },
        }, function(value)
            if value then
                fn()
            end
        end)
    else
        Snacks.input({ prompt = text }, function(answer)
            if answer and answer ~= "" then
                fn(answer)
            end
        end)
    end
end

-- ---------------------------------------------------------------
-- Checkout file from ref
--
-- Lists files that differ between the current working copy and
-- `ref` (branch or commit), each with a live reversed diff showing
-- what checking it out would apply. Invoked from both the log and
-- branch pickers below (key `f`), not a standalone keymap.
--
-- <Tab> to multi-select several files before confirming; with
-- nothing marked, acts on just the file under the cursor.
-- ---------------------------------------------------------------

local function checkout_file_picker(root, ref)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local previewers = require("telescope.previewers")
    local files = vim.fn.systemlist({ "git", "-C", root, "diff", "--name-only", ref })
    local display_ref = ref:gsub("^refs/heads/", ""):gsub("^refs/remotes/", "")
    local ref_diff_previewer = previewers.new_buffer_previewer({
        title = "Diff vs " .. display_ref,
        define_preview = function(self, entry)
            local buf = self.state.bufnr
            vim.system({ "git", "diff", "-R", ref, "--", entry[1] }, { text = true, cwd = root }, function(res)
                local lines = vim.split(res.stdout or "", "\n", { plain = true })
                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(buf) then
                        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                        vim.bo[buf].filetype = "diff"
                    end
                end)
            end)
        end,
    })
    pickers.new({
        initial_mode = "normal",
        prompt_title = "Checkout File from " .. display_ref,
    }, {
        finder = finders.new_table({ results = files }),
        sorter = conf.generic_sorter({}),
        previewer = ref_diff_previewer,
        attach_mappings = function(_, map)
            actions.select_default:replace(function(bufnr)
                local picker = state.get_current_picker(bufnr)
                local selections = picker:get_multi_selection()
                local paths = {}

                if #selections > 0 then
                    for _, e in ipairs(selections) do
                        table.insert(paths, e[1])
                    end
                else
                    local entry = state.get_selected_entry()
                    if not entry then
                        actions.close(bufnr)
                        return
                    end
                    table.insert(paths, entry[1])
                end

                actions.close(bufnr)

                local label = #paths == 1 and ("'" .. paths[1] .. "'") or (#paths .. " files")
                ask("Checkout " .. label .. " from " .. ref .. "?", function()
                    local args = { "restore", "--source=" .. ref, "--staged", "--worktree", "--" }
                    vim.list_extend(args, paths)
                    run(args, root)
                    vim.schedule(function() vim.cmd("checktime") end)
                end, true)
            end)
            return true
        end,
    }):find()
end

-- ---------------------------------------------------------------
-- Log browser
--
-- decorations arrive from %d and are split into individual refs
-- so each can be colored by kind. `ref` optionally scopes history
-- to one branch (called with no ref for the top-level keymap, and
-- with a branch name from branch_picker's drill-down, key `l`).
--
-- <CR>  checkout the selected commit (detached)
-- f     checkout a specific file from the selected commit
-- b     new branch from the selected commit
-- t     new tag on the selected commit
-- d     delete the tag on the selected commit (local)
-- o     delete the tag on the selected commit (origin)
-- ---------------------------------------------------------------

-- ---------------------------------------------------------------
-- Log highlights
-- ---------------------------------------------------------------

local function define_log_hl()
    local function fg(name)
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        return hl and hl.fg or nil
    end

    vim.api.nvim_set_hl(0, "GitLogHash", { fg = fg("Identifier"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogTag", { fg = fg("String"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogHead", { fg = fg("Function"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogRemote", { fg = fg("DiagnosticWarn"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogBranch", { fg = fg("Type"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogMeta", { fg = fg("Comment") })
end

define_log_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = define_log_hl })

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
        local group = ref_hl(ref)
        local label = ref:gsub("^tag:%s*", "")
        add(label, group)
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

local function get_tags(entry)
    local tags = {}
    for _, ref in ipairs(entry.refs) do
        if ref:match("^tag:") then
            table.insert(tags, (ref:gsub("^tag:%s*", "")))
        end
    end
    return tags
end

local function pick_tag(entry, cb)
    local tags = get_tags(entry)
    if #tags == 0 then
        notify("No tag on this commit", vim.log.levels.WARN)
        return
    end
    if #tags == 1 then
        cb(tags[1])
        return
    end
    vim.ui.select(tags, { prompt = "Which tag?" }, function(choice)
        if choice then cb(choice) end
    end)
end

local function log_picker(root, ref)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local previewers = require("telescope.previewers")

    local git_command = { "git", "log", LOG_PRETTY, "--decorate=short", "--abbrev-commit", "--max-count=" .. LOG_LIMIT }
    if ref then
        table.insert(git_command, ref)
    end
    vim.list_extend(git_command, { "--", "." })

    local display_ref = ref and ref:gsub("^refs/heads/", ""):gsub("^refs/remotes/", "")

    pickers.new({
        initial_mode = "normal",
        prompt_title = "Git Log" .. (display_ref and (" (" .. display_ref .. ")") or ""),
    }, {
        finder = finders.new_oneshot_job(git_command, { cwd = root, entry_maker = log_entry }),
        sorter = conf.generic_sorter({}),
        previewer = previewers.git_commit_diff_to_parent.new({ cwd = root }),
        attach_mappings = function(_, map)
            -- Checks out the selected commit directly (detached HEAD),
            -- explicitly replacing Telescope's default action.
            actions.select_default:replace(function(bufnr)
                local entry = state.get_selected_entry()
                actions.close(bufnr)
                if not entry then return end
                run({ "checkout", entry.value }, root)
            end)

            map("n", "f", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                actions.close(bufnr)
                checkout_file_picker(root, entry.value)
            end, { desc = "Checkout File from Commit" })

            map("n", "b", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local hash = entry.value
                actions.close(bufnr)
                ask("New branch from " .. hash .. ": ", function(name)
                    run({ "checkout", "-b", name, hash }, root)
                end)
            end, { desc = "New Branch from Commit" })

            map("n", "t", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local hash = entry.value
                actions.close(bufnr)
                ask("New tag on " .. hash .. ": ", function(tag)
                    run({ "tag", "-a", tag, "-m", tag, hash }, root)
                end)
            end, { desc = "New Tag on Commit" })

            map("n", "d", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                actions.close(bufnr)
                pick_tag(entry, function(tag_name)
                    ask("Delete tag '" .. tag_name .. "'?", function()
                        run({ "tag", "-d", tag_name }, root)
                    end, true)
                end)
            end, { desc = "Delete Tag" })

            map("n", "o", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                actions.close(bufnr)
                pick_tag(entry, function(tag_name)
                    ask("Delete tag '" .. tag_name .. "' on origin?", function()
                        run_auth({ "push", "origin", "--delete", "refs/tags/" .. tag_name }, root, "Delete Tag")
                    end, true)
                end)
            end, { desc = "Delete Tag on Origin" })

            return true
        end,
    }):find()
end

-- ---------------------------------------------------------------
-- Branch browser
--
-- <CR>  checkout, explicitly replacing Telescope's default action
-- m     merge into current branch
-- d     delete - local branch: safe delete (-d); remote-tracking
--       entry: delete on origin. Detected from the ref itself
--       (refs/heads/... vs refs/remotes/...), no separate keys.
-- x     force delete (local branches only; -D instead of -d).
--       Remote deletion has no force/non-force distinction, so on
--       a remote entry this does the same thing as `d`.
-- f     checkout a specific file from the selected branch
-- l     view this branch's commit log (drill down further to a
--       specific commit, then `f` there for a specific file)
-- ---------------------------------------------------------------

local function branch_picker(root)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local previewers = require("telescope.previewers")

    -- Refs come from %(refname) (full form, e.g. refs/heads/x or
    -- refs/remotes/origin/x) rather than %(refname:short), so every
    -- git command built from them targets an unambiguous ref even
    -- when a branch and tag happen to share the same short name -
    -- except checkout, which needs the short form specifically:
    -- a full ref always detaches HEAD instead of attaching to the
    -- branch, and only the short remote form (origin/x) triggers
    -- git's auto-create-local-tracking-branch behavior.
    local function is_remote(entry)
        return entry[1]:match("^refs/remotes/") ~= nil
    end

    local function short_name(entry)
        return (entry[1]:gsub("^refs/heads/", ""):gsub("^refs/remotes/origin/", ""))
    end

    local function checkout_ref(entry)
        if is_remote(entry) then
            return "origin/" .. short_name(entry)
        end
        return short_name(entry)
    end

    local function branch_delete(entry, force)
        local ref = entry[1]

        if is_remote(entry) then
            local name = short_name(entry)
            ask("Delete '" .. name .. "' on origin?", function()
                run_auth({ "push", "origin", "--delete", "refs/heads/" .. name }, root, "Delete Branch")
            end, true)
        else
            local name = short_name(entry)
            local flag = force and "-D" or "-d"
            local verb = force and "Force delete" or "Delete"
            ask(verb .. " local branch '" .. name .. "'?", function()
                run({ "branch", flag, name }, root)
            end, true)
        end
    end

    local branches = vim.fn.systemlist({ "git", "-C", root, "branch", "-a", "--format=%(refname)" })

    pickers.new({
        initial_mode = "normal",
        prompt_title = "Git Branches",
    }, {
        finder = finders.new_table({ results = branches }),
        sorter = conf.generic_sorter({}),
        previewer = previewers.git_branch_log.new({ cwd = root }),
        attach_mappings = function(_, map)
            actions.select_default:replace(function(bufnr)
                local entry = state.get_selected_entry()
                actions.close(bufnr)
                if not entry then return end
                run({ "checkout", checkout_ref(entry) }, root)
            end)

            map("n", "m", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local ref = entry[1]
                actions.close(bufnr)
                run({ "merge", ref }, root)
            end, { desc = "Merge" })

            map("n", "d", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                actions.close(bufnr)
                branch_delete(entry, false)
            end, { desc = "Delete" })

            map("n", "x", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                actions.close(bufnr)
                branch_delete(entry, true)
            end, { desc = "Force Delete" })

            map("n", "f", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local ref = entry[1]
                actions.close(bufnr)
                checkout_file_picker(root, ref)
            end, { desc = "Checkout File from Branch" })

            map("n", "l", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local ref = entry[1]
                actions.close(bufnr)
                log_picker(root, ref)
            end, { desc = "View Commit Log" })

            return true
        end,
    }):find()
end

-- ---------------------------------------------------------------
-- Stash browser
--
-- <CR>  apply, explicitly replacing Telescope's default action
-- p     pop (apply, then drop if clean)
-- d     drop
-- b     branch from this stash
-- n     new stash from current changes
-- ---------------------------------------------------------------

local function stash_picker(root)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local previewers = require("telescope.previewers")

    local lines = vim.fn.systemlist({ "git", "-C", root, "--no-pager", "stash", "list" })

    pickers.new({
        initial_mode = "normal",
        prompt_title = "Git Stashes",
    }, {
        finder = finders.new_table({
            results = lines,
            entry_maker = function(line)
                return {
                    value = line:match("^([^:]+):"),
                    display = line,
                    ordinal = line,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewers.git_stash_diff.new({ cwd = root }),
        attach_mappings = function(_, map)
            actions.select_default:replace(function(bufnr)
                local entry = state.get_selected_entry()
                actions.close(bufnr)
                if not entry then return end
                run({ "stash", "apply", entry.value }, root)
            end)

            map("n", "p", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local stash = entry.value
                actions.close(bufnr)
                run({ "stash", "pop", stash }, root)
            end, { desc = "Pop" })

            map("n", "d", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local stash = entry.value
                actions.close(bufnr)
                ask("Drop " .. stash .. "?", function()
                    run({ "stash", "drop", stash }, root)
                end, true)
            end, { desc = "Drop" })

            map("n", "b", function(bufnr)
                local entry = state.get_selected_entry()
                if not entry then return end
                local stash = entry.value
                actions.close(bufnr)
                ask("Branch from " .. stash .. ": ", function(name)
                    run({ "stash", "branch", name, stash }, root)
                end)
            end, { desc = "Branch from Stash" })

            map("n", "n", function(bufnr)
                actions.close(bufnr)
                ask("Stash message: ", function(msg)
                    run({ "stash", "push", "-m", msg }, root)
                end)
            end, { desc = "New Stash" })

            return true
        end,
    }):find()
end

-- ---------------------------------------------------------------
-- Tag browser
--
-- Pure browsing - add/delete tags live in the log picker (b/t/d/o
-- there), tied to a specific commit. This is just for scanning
-- release history with a diff preview per tag.
--
-- <CR>   checkout the selected tag (detached)
-- d      delete the selected tag(s) (local) - <Tab> to multi-select
--        several first; with nothing marked, acts on the tag
--        under the cursor
-- ---------------------------------------------------------------

local function tag_picker(root)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local previewers = require("telescope.previewers")

    local lines = vim.fn.systemlist({ "git", "-C", root, "tag", "--sort=-creatordate",
        "--format=%(refname:short)  %(creatordate:short)  %(subject)" })

    pickers.new({
        initial_mode = "normal",
        prompt_title = "Tags",
    }, {
        finder = finders.new_table({
            results = lines,
            entry_maker = function(line)
                return {
                    value = line:match("^(%S+)"),
                    display = line,
                    ordinal = line,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewers.git_commit_diff_to_parent.new({ cwd = root }),
        attach_mappings = function(_, map)
            actions.select_default:replace(function(bufnr)
                local entry = state.get_selected_entry()
                actions.close(bufnr)
                if not entry then return end
                run({ "checkout", entry.value }, root)
            end)

            map("n", "d", function(bufnr)
                local picker = state.get_current_picker(bufnr)
                local selections = picker:get_multi_selection()
                local names = {}

                if #selections > 0 then
                    for _, e in ipairs(selections) do
                        table.insert(names, e.value)
                    end
                else
                    local entry = state.get_selected_entry()
                    if not entry then return end
                    table.insert(names, entry.value)
                end

                actions.close(bufnr)

                local label = #names == 1 and ("'" .. names[1] .. "'") or (#names .. " tags")
                ask("Delete " .. label .. "?", function()
                    local args = { "tag", "-d" }
                    vim.list_extend(args, names)
                    run(args, root)
                end, true)
            end, { desc = "Delete Tag(s)" })

            return true
        end,
    }):find()
end

-- ---------------------------------------------------------------
-- Status highlights
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
-- Status entries
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
-- Diff previewer
--
-- staged files show the cached diff, unstaged show the worktree
-- diff, untracked show raw contents. all run at the repo root so
-- git resolves the paths. filetype=diff gives red/green coloring.
-- ---------------------------------------------------------------

local function status_diff_previewer()
    local previewers = require("telescope.previewers")

    return previewers.new_buffer_previewer({
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
                local lines = vim.split(res.stdout or "", "\n", { plain = true })

                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(buf) then
                        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                        vim.bo[buf].filetype = "diff"
                    end
                end)
            end)
        end,
    })
end

-- ---------------------------------------------------------------
-- Status browser
--
-- Unlike the branch/stash/log pickers (verb chosen by key, one
-- action per keypress), staging is iterative: you stay in the
-- list, toggle several files against the live diff preview, then
-- leave to commit. Actions live inside the picker itself.
--
-- t      stage / unstage the file under the cursor
-- <C-a>  stage everything (git add -A)
-- <C-u>  unstage everything (git reset)
-- s      stash the selected file(s) - uses Telescope's own
--        multi-select (<Tab> to mark several) when present,
--        otherwise just the file under the cursor. Works on
--        staged or unstaged files, matching `git stash push --`.
-- S      stash everything (no pathspec - matches plain `git stash`)
-- ---------------------------------------------------------------

local function status_picker(root)
    local pickers = require("telescope.pickers")
    local state = require("telescope.actions.state")
    local conf = require("telescope.config").values

    local head = capture({ "symbolic-ref", "--short", "HEAD" }, root)
    local title
    if head == "" then
        title = "⚠ DETACHED HEAD"
    else
        local ab = capture({ "rev-list", "--left-right", "--count", "HEAD...@{u}" }, root)
        local tracking = ""
        local ahead, behind = ab:match("(%d+)%s+(%d+)")
        if ahead then
            local parts = {}
            if tonumber(ahead) > 0 then table.insert(parts, "↑ " .. ahead) end
            if tonumber(behind) > 0 then table.insert(parts, "↓ " .. behind) end
            if #parts > 0 then tracking = " " .. table.concat(parts, " ") end
        end
        title = string.format("Git Status: %s%s", head, tracking)
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
        previewer = status_diff_previewer(),
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

            map("n", "s", function(bufnr)
                local picker = state.get_current_picker(bufnr)
                local selections = picker:get_multi_selection()
                local paths = {}

                if #selections > 0 then
                    for _, e in ipairs(selections) do
                        table.insert(paths, e.path)
                    end
                else
                    local entry = state.get_selected_entry()
                    if not entry then return end
                    table.insert(paths, entry.path)
                end

                ask("Stash message: ", function(msg)
                    local args = { "stash", "push", "-m", msg, "--" }
                    vim.list_extend(args, paths)
                    run(args, root)
                    vim.schedule(function()
                        if vim.api.nvim_buf_is_valid(bufnr) then
                            picker:refresh(status_finder(root), { reset_prompt = false })
                        end
                    end)
                end)
            end, { desc = "Stash Selected" })

            map("n", "S", function(bufnr)
                local picker = state.get_current_picker(bufnr)

                ask("Stash message: ", function(msg)
                    run({ "stash", "push", "-m", msg }, root)
                    vim.schedule(function()
                        if vim.api.nvim_buf_is_valid(bufnr) then
                            picker:refresh(status_finder(root), { reset_prompt = false })
                        end
                    end)
                end)
            end, { desc = "Stash All" })

            return true
        end,
    }):find()
end

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

local function discard_file(root)
    local file = vim.fn.expand("%:p")

    if file == "" then
        notify("no file in this buffer", vim.log.levels.ERROR)
        return
    end

    local rel = vim.fn.fnamemodify(file, ":.")

    ask("Restore '" .. rel .. "' from HEAD?", function()
        run({ "restore", "--staged", "--worktree", "--", file }, root)

        vim.schedule(function()
            vim.cmd("edit!")
        end)
    end, true)
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
                local preview = vim.fn.systemlist({ "git", "-C", root, "clean", "-fdn" })
                if #preview == 0 then
                    run({ "restore", "--staged", "--worktree", "--", "." }, root)
                    vim.schedule(function() vim.cmd("checktime") end)
                    return
                end

                local files = {}
                for _, line in ipairs(preview) do
                    table.insert(files, (line:gsub("^Would remove ", "")))
                end

                confirm_file_list("Will also permanently delete", files, function()
                    run({ "restore", "--staged", "--worktree", "--", "." }, root)
                    run({ "clean", "-fd" }, root)
                    vim.schedule(function() vim.cmd("checktime") end)
                end)
            end
        end
    )
end

return {
    {
        'nvim-telescope/telescope.nvim',
        keys = {
            { "<leader>gs", git_guard(status_picker), desc = "Git Status" },
            { "<leader>gl", git_guard(log_picker),    desc = "Git Log" },
            { "<leader>gb", git_guard(branch_picker), desc = "Branches" },
            { "<leader>gz", git_guard(stash_picker),  desc = "Stashes" },
            { "<leader>gt", git_guard(tag_picker),    desc = "Tags" },
            { "<leader>gr", git_guard(discard_file),  desc = "Restore Buffer from HEAD" },
            { "<leader>gx", git_guard(discard_all),   desc = "Restore All from HEAD" },
            { "<leader>gi", git_guard(checkout_head), desc = "Checkout Tip" },
            {
                "<leader>gp",
                git_guard(function(root)
                    run_auth({
                        "pull",
                    }, root, "Pull")
                end),
                desc = "Git Pull"
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
                    }, root, "Git Push")
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
                    }, root, "Git Fetch")
                end),
                desc = "Fetch + Prune"
            },
            {
                "<leader>gc",
                git_guard(function(root)
                    ask("Commit message: ", function(msg)
                        run({ "commit", "-m", msg }, root)
                    end)
                end),
                desc = "Commit Staged",
            },
            {
                "<leader>ga",
                git_guard(function(root)
                    ask("Commit message (all files): ", function(msg)
                        capture({ "add", "-A" }, root)
                        run({ "commit", "-m", msg }, root)
                    end)
                end),
                desc = "Add All + Commit",
            },
        },
    },
}
