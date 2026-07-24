-- set false once SSH keys are working; then remote ops never prompt
local ASK_PASSWORD = true

-- ---------------------------------------------------------------
-- git log picker with colored refs
-- ---------------------------------------------------------------

local SEP = "\31" -- unit separator, safe inside commit messages
local LOG_PRETTY = "--pretty=%h" .. SEP .. "%d" .. SEP .. "%s" .. SEP .. "%cr" .. SEP .. "%an"

-- colors follow git's own convention: tags yellow, remotes red, local green
local function define_log_hl()
    local function fg(name)
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        return hl and hl.fg or nil
    end

    vim.api.nvim_set_hl(0, "GitLogHash", { fg = fg("Number") })
    vim.api.nvim_set_hl(0, "GitLogHead", { fg = fg("Constant"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogTag", { fg = fg("WarningMsg"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogRemote", { fg = fg("ErrorMsg"), bold = true })
    vim.api.nvim_set_hl(0, "GitLogBranch", { fg = fg("String"), bold = true })
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

-- builds the row text plus byte-range highlights telescope expects
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

    -- %d arrives as " (HEAD -> main, tag: v0.0.9)" or empty
    local deco = (parts[2] or ""):gsub("^%s*%(", ""):gsub("%)%s*$", "")

    local refs = {}
    if deco ~= "" then
        for _, ref in ipairs(vim.split(deco, ", ", { plain = true })) do
            table.insert(refs, vim.trim(ref))
        end
    end

    return {
        value   = parts[1], -- hash: telescope's actions depend on this
        hash    = parts[1],
        refs    = refs,
        msg     = parts[3] or "",
        when    = parts[4] or "",
        author  = parts[5] or "",
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

local function notify(msg, level)
    if not msg or msg == "" then
        return
    end
    vim.notify(vim.trim(msg), level or vim.log.levels.INFO, { title = "git" })
end

-- read-only git call, returns trimmed stdout + exit code
local function capture(args)
    local res = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
    return vim.trim(res.stdout or ""), res.code
end

-- writes the password to a private temp dir and hands back an
-- askpass script ssh will call instead of opening a TTY
local function make_askpass(password)
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p", "0700")

    local pw_file = dir .. "/pw"
    local script  = dir .. "/askpass.sh"

    vim.fn.writefile({ password }, pw_file)
    vim.fn.writefile({ "#!/bin/sh", "cat " .. vim.fn.shellescape(pw_file) }, script)

    vim.fn.setfperm(pw_file, "rw-------")
    vim.fn.setfperm(script, "rwx------")

    return script, function()
        vim.fn.delete(dir, "rf")
    end
end

-- async git, output goes to notifications
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
            notify(out ~= "" and out or "ok",
                res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
            if res.code == 0 then
                vim.cmd("checktime")
            end
        end)
    end)
end

-- anything touching the remote goes through here
local function run_auth(args)
    if not ASK_PASSWORD then
        run(args)
        return
    end

    -- pcall catches Ctrl-C; Esc comes back as ""
    local ok, pw = pcall(vim.fn.inputsecret, "SSH password (Esc to cancel): ")
    vim.cmd("redraw")

    if not ok or pw == "" then
        notify("cancelled", vim.log.levels.WARN)
        return
    end

    run(args, pw)
end

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

    -- on a branch already: just fast-forward to its tip
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

local function stash_picker()
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")
    local state   = require("telescope.actions.state")

    builtin.git_stash({
        initial_mode = "normal",

        attach_mappings = function(_, map)
            -- entry.value is the stash ref, e.g. "stash@{0}"
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

local function status_picker()
    if capture({ "status", "--porcelain" }) ~= "" then
        require("telescope.builtin").git_status({ initial_mode = "normal" })
        return
    end

    -- builtin errors out when clean, so show an empty picker instead
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf    = require("telescope.config").values

    pickers.new({
        initial_mode = "normal",
        prompt_title = "Git Status (clean)",
    }, {
        finder = finders.new_table({ results = {} }),
        sorter = conf.generic_sorter({}),
    }):find()
end

local function branch_picker()
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")
    local state   = require("telescope.actions.state")

    builtin.git_branches({
        initial_mode = "normal",
        show_remote_tracking_branches = true,

        attach_mappings = function(_, map)
            -- closes the picker, then hands the branch name to fn
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

            map({ "i", "n" }, "<C-y>", on(function(b)
                run({ "merge", b })
            end))

            map({ "i", "n" }, "<C-d>", on(function(b)
                run({ "branch", "-d", b })
            end))

            map({ "i", "n" }, "<C-x>", on(function(b)
                if confirm("Force delete local branch '" .. b .. "'?") then
                    run({ "branch", "-D", b })
                end
            end))

            map({ "i", "n" }, "<C-o>", on(function(b)
                if confirm("Delete '" .. b .. "' on origin?") then
                    run_auth({ "push", "origin", "--delete", b })
                end
            end))

            return true
        end,
    })
end

return {
    {
        'nvim-telescope/telescope.nvim',
        keys = {
            -- status / browse
            { "<leader>gs", status_picker, desc = "Git status" },
            { "<leader>gl", log_picker,    desc = "Git log" },
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
            { "<leader>gb", branch_picker, desc = "Git branches" },

            -- checkout
            { "<leader>gh", checkout_head, desc = "Checkout branch tip" },

            {
                "<leader>gn",
                function()
                    prompt("New branch: ", function(name)
                        run({ "checkout", "-b", name })
                    end)
                end,
                desc = "New branch",
            },

            -- commit
            {
                "<leader>gc",
                function()
                    prompt("Commit message: ", function(msg)
                        run({ "commit", "-am", msg })
                    end)
                end,
                desc = "Commit (tracked files)",
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

            -- tags
            {
                "<leader>gt",
                function()
                    prompt("New tag: ", function(tag)
                        run({ "tag", "-a", tag, "-m", tag })
                    end)
                end,
                desc = "New tag",
            },

            -- remote
            { "<leader>gp", function() run_auth({ "push" }) end,                         desc = "Push" },
            { "<leader>gP", function() run_auth({ "pull", "--ff-only" }) end,            desc = "Pull" },
            { "<leader>gu", function() run_auth({ "push", "--follow-tags" }) end,        desc = "Push + tags" },
            { "<leader>gU", function() run_auth({ "push", "-u", "origin", "HEAD" }) end, desc = "Push + set upstream" },
            { "<leader>gf", function() run_auth({ "fetch", "--prune", "--tags" }) end,   desc = "Fetch + prune" },
        },
    },
}
