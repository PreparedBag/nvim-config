-- Insert current date in YYYY-MM-DD format
local function insert_current_date()
    local current_date = os.date("%Y-%m-%d")
    vim.api.nvim_put({ current_date }, 'c', true, true)
end

-- Insert font imports
local function insert_header()
    local header_html = [[
<style>
@import url('https://fonts.googleapis.com/css2?family=Ubuntu:ital,wght@0,300..900;1,300..900&display=swap');
</style>
    ]]
    vim.api.nvim_put(vim.split(header_html, '\n'), 'c', true, true)
end

-- Insert page break
local function insert_page_break()
    local logo_html = [[<div style="page-break-before: always;"></div>]]
    vim.api.nvim_put({ logo_html }, 'c', true, true)
end

-- Insert flowchart template
local function insert_flowchart_template()
    local template = [[
```mermaid
    %%{init: {'theme':'base'}}%%
    graph LR

    classDef default stroke:#222,stroke-width:2px;
    classDef red fill:#D29898;
    classDef green fill:#8DB58D;
    classDef blue fill:#7887AB;
    classDef yellow fill:#FFE3AA;
    classDef purple fill:#8F76A2;
    classDef white fill:#ffffff;

    A([Task A]) ---> B{Task B}
    A -..->|LABEL| C(Task C)
    B --> D((Task D))
    B -..-> C
    C -..-> D
    D -..-> E(COMPLETE)

    subgraph SUBTASK
        B & C
    end

    class B,C yellow
    class D white
```]]
    local row = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_lines(0, row, row, false, vim.split(template, "\n"))
end

-- Insert Gantt chart template
local function insert_gantt_template()
    local template = [[
```mermaid
gantt
    %%{init: {'theme':'base'}}%%
    tickInterval 4week
    todayMarker on
    excludes weekends

    section DESIGN
        TASK 1 : active, a, 2024-08-06, 60d
        TASK 2 : done, b, 2024-08-06, 8d
        TASK 3 : active, c, after b, 7d
    section BUILD
        Prototype Case :d, after c, 9d
    section DELIVER
        Deliver (2024-09-15) : milestone, m1, 2024-09-15, 0d
    section TESTING
        TEST 1 : crit, e, after m1, 8d
        TEST 2 : f, after e, 9d

```]]
    local row = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_lines(0, row, row, false, vim.split(template, "\n"))
end

-- Open Telescope to select an image file
local function select_image(callback, prompt_title)
    local buf_path = vim.api.nvim_buf_get_name(0)
    local buf_dir = buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":p:h") or vim.fn.getcwd()
    local image_dir = vim.fn.fnamemodify(buf_dir .. "/assets", ":p")

    if vim.fn.isdirectory(image_dir) == 0 then
        vim.fn.mkdir(image_dir, "p")
    end

    require('telescope.builtin').find_files({
        prompt_title = prompt_title or "Select Image",
        cwd = image_dir,
        previewer = false,
        file_ignore_patterns = {},
        find_command = { "rg", "--files", "--iglob", "*.png", "--iglob", "*.jpg", "--iglob", "*.jpeg", "--iglob", "*.gif", "--iglob", "*.bmp", "--iglob", "*.tiff" },
        attach_mappings = function(_, map)
            local function select_and_insert(prompt_bufnr)
                local selection = require('telescope.actions.state').get_selected_entry()
                require('telescope.actions').close(prompt_bufnr)
                local rel = vim.fn.fnamemodify(selection.path, ":." .. buf_dir)
                callback(rel)
            end

            map('i', '<CR>', select_and_insert)
            map('n', '<CR>', select_and_insert)
            return true
        end
    })
end

-- Insert multi-line HTML into buffer
local function insert_multiline_html(row, col, html)
    local lines = {}
    for line in html:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
end

-- Insert single image
local function insert_image_link()
    select_image(function(image_path)
        local html = string.format([[
<div class="center-image">
    <img src="%s" alt="Alt Text" style="max-height: 300px;">
    <p></p>
</div>]], image_path)

        vim.schedule(function()
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            insert_multiline_html(row - 1, col, html)
        end)
    end)
end

-- Insert two images side by side
local function insert_two_image_links()
    select_image(function(image1)
        select_image(function(image2)
            local html = string.format([[
<div class="side-by-side">
    <div class="center-image">
        <img src="%s" alt="Alt Text" style="max-height: 300px;">
        <p></p>
    </div>
    <div class="center-image">
        <img src="%s" alt="Alt Text" style="max-height: 300px;">
        <p></p>
    </div>
</div>]], image1, image2)

            vim.schedule(function()
                local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                insert_multiline_html(row - 1, col, html)
            end)
        end, "Select Image 2")
    end, "Select Image 1")
end

-- Insert table template
local function insert_table()
    local lines = {
        "| Column1 | Column2 | Column3 |",
        "|---------|---------|---------|",
        "| ValueA  | ValueB  | ValueC  |"
    }
    vim.api.nvim_put(lines, "l", true, true)
end

-- Register all markdown helpers (commands + keymaps) buffer-locally
function Register_Markdown_Helpers(buf)
    local function bufcmd(name, fn)
        vim.api.nvim_buf_create_user_command(buf, name, fn, {})
    end
    local function bufmap(lhs, fn, desc)
        vim.keymap.set('n', lhs, fn, { buffer = buf, noremap = true, silent = true, desc = desc })
    end

    bufcmd('InsertCurrentDate', insert_current_date)
    bufcmd('InsertHeader', insert_header)
    bufcmd('InsertPageBreak', insert_page_break)

    bufmap('<leader>mp', function()
        if _G.DEV_ENABLED then
            vim.cmd("MarkdownPreviewToggle")
        else
            vim.g.livepreview_on = not vim.g.livepreview_on
            vim.cmd("LivePreview " .. (vim.g.livepreview_on and "start" or "close"))
        end
    end, "Toggle Markdown Preview")
    bufmap('<leader>if', insert_flowchart_template, "Insert Flowchart Template")
    bufmap('<leader>ig', insert_gantt_template, "Insert Gantt Chart Template")
    bufmap('<leader>it', insert_table, "Insert Table Template")
    bufmap('<leader>ii1', insert_image_link, "Insert Image")
    bufmap('<leader>ii2', insert_two_image_links, "Insert 2 Images")
end

-- Register helpers only in markdown buffers
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown" },
    callback = function(ev)
        Register_Markdown_Helpers(ev.buf)
    end,
})
