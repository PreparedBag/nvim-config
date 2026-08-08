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

local function log_picker(root)
    Snacks.picker.git_log({ cwd = root, on_show = normal_mode })
end

local function status_picker(root)
    Snacks.picker.git_status({ cwd = root, on_show = normal_mode })
end

local function branch_action_picker(root, fn)
    Snacks.picker.git_branches({
        cwd = root,
        all = true,
        on_show = normal_mode,
        confirm = function(picker, item)
            picker:close()
            if item then
                fn((item.branch:gsub("^remotes/", ""):gsub("^origin/", "")))
            end
        end,
    })
end

local function branch_confirm(root, message, build, auth)
    branch_action_picker(root, function(branch)
        ask(message(branch), function()
            if auth then
                run_auth(build(branch), root, auth)
            else
                run(build(branch), root)
            end
        end, true)
    end)
end

local function branch_checkout(root)
    Snacks.picker.git_branches({ cwd = root, all = true, on_show = normal_mode })
end

local function branch_merge(root)
    branch_action_picker(root, function(branch)
        run({ "merge", branch }, root)
    end)
end

local function branch_delete(root)
    branch_confirm(root,
        function(b) return "Delete local branch '" .. b .. "'?" end,
        function(b) return { "branch", "-d", b } end)
end

local function branch_force_delete(root)
    branch_confirm(root,
        function(b) return "Force delete local branch '" .. b .. "'?" end,
        function(b) return { "branch", "-D", b } end)
end

local function branch_delete_origin(root)
    branch_confirm(root,
        function(b) return "Delete '" .. b .. "' on origin?" end,
        function(b) return { "push", "origin", "--delete", b } end,
        "Delete Branch")
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
            { "<leader>gr", git_guard(discard_file),  desc = "Restore Buffer from HEAD" },
            { "<leader>gR", git_guard(discard_all),   desc = "Restore All from HEAD" },
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
            {
                "<leader>gt",
                git_guard(function(root)
                    ask("New tag: ", function(tag)
                        run({ "tag", "-a", tag, "-m", tag }, root)
                    end)
                end),
                desc = "New Tag",
            },

            { "<leader>gbs", git_guard(branch_checkout),      desc = "Select / Checkout" },
            { "<leader>gbm", git_guard(branch_merge),         desc = "Merge" },
            { "<leader>gbd", git_guard(branch_delete),        desc = "Delete (local)" },
            { "<leader>gbD", git_guard(branch_force_delete),  desc = "Force Delete (local)" },
            { "<leader>gbo", git_guard(branch_delete_origin), desc = "Delete on Origin" },
            { "<leader>gbr", git_guard(checkout_head),        desc = "Checkout Tip" },
            {
                "<leader>gbn",
                git_guard(function(root)
                    ask("New branch: ", function(name)
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
