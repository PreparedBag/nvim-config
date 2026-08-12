local ASK_PASSWORD = true

local function notify(msg, level)
    if not msg or msg == "" then
        return
    end
    vim.notify(vim.trim(msg), level or vim.log.levels.INFO, { title = "git" })
end

local function normal_mode()
    vim.cmd.stopinsert()
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

local function status_picker(root)
    Snacks.picker.git_status({ cwd = root, on_show = normal_mode })
end

-- Lists every file that exists at `ref` (branch or commit), each item
-- carrying its own pre-computed diff against the current working copy
-- as its preview, so you can see what checking it out would change
-- before confirming. Invoked as an in-picker action from both the
-- branch and log pickers below (key `f`), not a standalone keymap.
local function checkout_file_picker(root, ref)
    local files = vim.fn.systemlist({ "git", "-C", root, "ls-tree", "-r", "--name-only", ref })
    local items = {}

    for _, path in ipairs(files) do
        local diff = capture({ "diff", ref, "--", path }, root)
        table.insert(items, {
            text = path,
            preview = { text = diff ~= "" and diff or "(no changes)", ft = "diff" },
        })
    end

    Snacks.picker.pick({
        items = items,
        title = "Checkout File from " .. ref,
        format = "text",
        preview = "preview",
        on_show = normal_mode,
        confirm = function(picker, item)
            picker:close()
            if not item then return end

            ask("Checkout '" .. item.text .. "' from " .. ref .. "?", function()
                run({ "restore", "--source=" .. ref, "--staged", "--worktree", "--", item.text }, root)
                vim.schedule(function() vim.cmd("checktime") end)
            end, true)
        end,
    })
end

-- ---------------------------------------------------------------
-- Log browser
--
-- `ref` optionally scopes history to one branch (via cmd_args,
-- confirmed from source: extra positional args passed straight to
-- `git log`) - called with no ref for the top-level log keymap,
-- and with a branch name from branch_picker's drill-down (key `l`).
--
-- <CR>  Snacks' own default action, left unset here
-- f     checkout a specific file from the selected commit
-- b     new branch from the selected commit
-- t     new tag on the selected commit
-- ---------------------------------------------------------------

local function log_picker(root, ref)
    Snacks.picker.git_log({
        cwd = root,
        cmd_args = ref and { ref } or nil,
        on_show = normal_mode,
        actions = {
            log_checkout_file = function(picker, item)
                picker:close()
                if not item then return end
                checkout_file_picker(root, item.commit)
            end,
            log_branch_new = function(picker, item)
                picker:close()
                if not item then return end
                local hash = item.commit
                ask("New branch from " .. hash .. ": ", function(name)
                    run({ "checkout", "-b", name, hash }, root)
                end)
            end,
            log_tag_new = function(picker, item)
                picker:close()
                if not item then return end
                local hash = item.commit
                ask("New tag on " .. hash .. ": ", function(tag)
                    run({ "tag", "-a", tag, "-m", tag, hash }, root)
                end)
            end,
        },
        win = {
            input = {
                keys = {
                    ["f"] = { "log_checkout_file", mode = { "n" } },
                    ["b"] = { "log_branch_new", mode = { "n" } },
                    ["t"] = { "log_tag_new", mode = { "n" } },
                },
            },
        },
    })
end

-- ---------------------------------------------------------------
-- Branch browser
--
-- <CR>  checkout (Snacks' own default action, left unset here)
-- m     merge into current branch
-- d     delete (local)
-- D     force delete (local)
-- o     delete on origin
-- f     checkout a specific file from the selected branch
-- l     view this branch's commit log (drill down further to a
--       specific commit, then `f` there for a specific file)
-- ---------------------------------------------------------------

local function branch_picker(root)
    local function name_of(item)
        return (item.branch:gsub("^remotes/", ""):gsub("^origin/", ""))
    end

    Snacks.picker.git_branches({
        cwd = root,
        all = true,
        on_show = normal_mode,
        actions = {
            branch_merge = function(picker, item)
                picker:close()
                if not item then return end
                run({ "merge", name_of(item) }, root)
            end,
            branch_delete = function(picker, item)
                picker:close()
                if not item then return end
                local name = name_of(item)
                ask("Delete local branch '" .. name .. "'?", function()
                    run({ "branch", "-d", name }, root)
                end, true)
            end,
            branch_force_delete = function(picker, item)
                picker:close()
                if not item then return end
                local name = name_of(item)
                ask("Force delete local branch '" .. name .. "'?", function()
                    run({ "branch", "-D", name }, root)
                end, true)
            end,
            branch_delete_origin = function(picker, item)
                picker:close()
                if not item then return end
                local name = name_of(item)
                ask("Delete '" .. name .. "' on origin?", function()
                    run_auth({ "push", "origin", "--delete", name }, root, "Delete Branch")
                end, true)
            end,
            branch_checkout_file = function(picker, item)
                picker:close()
                if not item then return end
                checkout_file_picker(root, name_of(item))
            end,
            branch_log = function(picker, item)
                picker:close()
                if not item then return end
                log_picker(root, name_of(item))
            end,
        },
        win = {
            input = {
                keys = {
                    ["m"] = { "branch_merge", mode = { "n" } },
                    ["d"] = { "branch_delete", mode = { "n" } },
                    ["D"] = { "branch_force_delete", mode = { "n" } },
                    ["o"] = { "branch_delete_origin", mode = { "n" } },
                    ["f"] = { "branch_checkout_file", mode = { "n" } },
                    ["l"] = { "branch_log", mode = { "n" } },
                },
            },
        },
    })
end

-- ---------------------------------------------------------------
-- Stash browser
--
-- <CR>  apply (Snacks' own default action, left unset here)
-- p     pop (apply, then drop if clean)
-- d     drop
-- b     branch from this stash
-- n     new stash from current changes
-- ---------------------------------------------------------------

local function stash_picker(root)
    Snacks.picker.git_stash({
        cwd = root,
        on_show = normal_mode,
        actions = {
            stash_pop = function(picker, item)
                picker:close()
                if not item then return end
                run({ "stash", "pop", item.stash }, root)
            end,
            stash_drop = function(picker, item)
                picker:close()
                if not item then return end
                ask("Drop " .. item.stash .. "?", function()
                    run({ "stash", "drop", item.stash }, root)
                end, true)
            end,
            stash_branch = function(picker, item)
                picker:close()
                if not item then return end
                ask("Branch from " .. item.stash .. ": ", function(name)
                    run({ "stash", "branch", name, item.stash }, root)
                end)
            end,
            stash_new = function(picker)
                picker:close()
                ask("Stash message: ", function(msg)
                    run({ "stash", "push", "-m", msg }, root)
                end)
            end,
        },
        win = {
            input = {
                keys = {
                    ["p"] = { "stash_pop", mode = { "n" } },
                    ["d"] = { "stash_drop", mode = { "n" } },
                    ["b"] = { "stash_branch", mode = { "n" } },
                    ["n"] = { "stash_new", mode = { "n" } },
                },
            },
        },
    })
end

-- ---------------------------------------------------------------
-- Tag browser
--
-- No built-in Snacks source for tags exists (confirmed: only log,
-- status, diff, branches, stash are defined) - built the same way
-- as checkout_file_picker, from a plain items list.
--
-- <CR>  checkout
-- d     delete (local)
-- o     delete on origin
-- ---------------------------------------------------------------

local function tag_picker(root)
    local lines = vim.fn.systemlist({ "git", "-C", root, "tag", "--sort=-creatordate",
        "--format=%(refname:short)  %(creatordate:short)  %(subject)" })

    local items = {}
    for _, line in ipairs(lines) do
        table.insert(items, { text = line })
    end

    Snacks.picker.pick({
        items = items,
        title = "Tags",
        format = "text",
        on_show = normal_mode,
        confirm = function(picker, item)
            picker:close()
            if item then
                run({ "checkout", item.text:match("^(%S+)") }, root)
            end
        end,
        actions = {
            tag_delete = function(picker, item)
                picker:close()
                if not item then return end
                local name = item.text:match("^(%S+)")
                ask("Delete tag '" .. name .. "'?", function()
                    run({ "tag", "-d", name }, root)
                end, true)
            end,
            tag_delete_origin = function(picker, item)
                picker:close()
                if not item then return end
                local name = item.text:match("^(%S+)")
                ask("Delete tag '" .. name .. "' on origin?", function()
                    run_auth({ "push", "origin", "--delete", name }, root, "Delete Tag")
                end, true)
            end,
        },
        win = {
            input = {
                keys = {
                    ["d"] = { "tag_delete", mode = { "n" } },
                    ["o"] = { "tag_delete_origin", mode = { "n" } },
                },
            },
        },
    })
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
    Snacks.picker.select(
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
                ask("Will also permanently delete:\n" .. table.concat(preview, "\n"), function()
                    run({ "restore", "--staged", "--worktree", "--", "." }, root)
                    run({ "clean", "-fd" }, root)
                    vim.schedule(function() vim.cmd("checktime") end)
                end, true)
            end
        end
    )
end

return {
    {
        'folke/snacks.nvim',
        keys = {
            { "<leader>gs", git_guard(status_picker), desc = "Git Status" },
            { "<leader>gl", git_guard(log_picker),    desc = "Git Log" },
            { "<leader>gb", git_guard(branch_picker), desc = "Branches" },
            { "<leader>gz", git_guard(stash_picker),  desc = "Stashes" },
            { "<leader>gt", git_guard(tag_picker),    desc = "Tags" },
            { "<leader>gr", git_guard(discard_file),  desc = "Restore Buffer from HEAD" },
            { "<leader>gR", git_guard(discard_all),   desc = "Restore All from HEAD" },
            { "<leader>gI", git_guard(checkout_head), desc = "Checkout Tip" },
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
