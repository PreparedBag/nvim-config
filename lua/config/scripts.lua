-- Store the original working directory when Neovim starts
_G.original_working_directory = vim.fn.getcwd()

-- Function to insert the current date in the format YYYY-MM-DD
local function insert_current_date()
    local current_date = os.date("%Y-%m-%d")            -- Get current date in YYYY-MM-DD format
    vim.api.nvim_put({ current_date }, 'c', true, true) -- Insert the date at the cursor position
end

-- Command to run the function
vim.api.nvim_create_user_command('InsertCurrentDate', insert_current_date, {})

local function insert_header()
    -- Insert the font import at the top of the document
    local header_html = [[
<style>
@import url('https://fonts.googleapis.com/css2?family=Rubik:ital,wght@0,300..900;1,300..900&display=swap');
@import url('https://fonts.googleapis.com/css2?family=Roboto+Slab:wght@100..900&display=swap');
</style>
    ]]
    -- Split the content into lines and insert at the top
    vim.api.nvim_put(vim.split(header_html, '\n'), 'c', true, true)
end

-- Create a command to run the function easily
vim.api.nvim_create_user_command('InsertHeader', insert_header, {})

-- Function to insert a page break
local function insert_page_break()
    local logo_html = [[<div style="page-break-before: always;"></div>]]
    vim.api.nvim_put({ logo_html }, 'c', true, true)
end

-- Create a command to run the function easily
vim.api.nvim_create_user_command('InsertPageBreak', insert_page_break, {})

-- Function to insert Mermaid template
function insert_flowchart_template()
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
    -- Insert the template at the current cursor position
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_lines(0, row, row, false, vim.split(template, "\n"))
end

-- Create keymap
vim.api.nvim_set_keymap('n', '<leader>if', ':lua insert_flowchart_template()<CR>', { noremap = true, silent = true })

-- Function to insert Mermaid template
function insert_gantt_template()
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
    -- Insert the template at the current cursor position
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_lines(0, row, row, false, vim.split(template, "\n"))
end

-- Create keymap
vim.api.nvim_set_keymap('n', '<leader>ig', ':lua insert_gantt_template()<CR>', { noremap = true, silent = true })

-- Common function to open Telescope and get an image file using ripgrep
function select_image(callback, prompt_title)
    local image_dir = vim.fn.expand("~/Pictures/") -- Ensure correct path resolution

    -- Check if the directory exists, if not, create it
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
            map('i', '<CR>', function(prompt_bufnr)
                local selection = require('telescope.actions.state').get_selected_entry()
                require('telescope.actions').close(prompt_bufnr)

                -- Call the callback with the selected file path
                callback(selection.path)
            end)
            return true
        end
    })
end

-- Helper function to insert multi-line HTML into the buffer
local function insert_multiline_html(row, col, html)
    local lines = {}
    for line in html:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
end

-- Single image insertion
function insert_image_link()
    select_image(function(image_path)
        -- Generate HTML for the single image
        local html = string.format([[
<div class="center-image">
    <img src="%s" alt="Alt Text" style="max-height: 300px;">
    <p></p>
</div>]], image_path)

        -- Insert the HTML at the cursor position
        vim.schedule(function()
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            insert_multiline_html(row - 1, col, html)
        end)
    end)
end

-- Two images side by side insertion
function insert_two_image_links()
    select_image(function(image1)
        -- After selecting the first image, open Telescope again for the second image
        select_image(function(image2)
            -- Generate HTML for two images side by side
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

            -- Insert the HTML at the cursor position
            vim.schedule(function()
                local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                insert_multiline_html(row - 1, col, html)
            end)
        end, "Select Image 2")
    end, "Select Image 1")
end

-- Function to insert a warning blockquote
function insert_warning()
    local blockquote = [[
<blockquote class="warning">⚠️ ***WARNING***: 

</blockquote>
    ]]
    vim.api.nvim_put(vim.split(blockquote, '\n'), 'c', true, true)
end

-- Function to insert an error blockquote
function insert_error()
    local blockquote = [[
<blockquote class="error">❌ ***Error:***

</blockquote>
    ]]
    vim.api.nvim_put(vim.split(blockquote, '\n'), 'c', true, true)
end

function insert_table()
  local lines = {
    "| Column1 | Column2 | Column3 |",
    "|---------|---------|---------|",
    "| ValueA  | ValueB  | ValueC  |"
  }
  vim.api.nvim_put(lines, "l", true, true)
end

-- Single image key mapping
vim.api.nvim_set_keymap('n', '<leader>it', ':lua insert_table()<CR>', { noremap = true, silent = true })

-- Single image key mapping
vim.api.nvim_set_keymap('n', '<leader>ii1', ':lua insert_image_link()<CR>', { noremap = true, silent = true })

-- Two images side by side key mapping
vim.api.nvim_set_keymap('n', '<leader>ii2', ':lua insert_two_image_links()<CR>', { noremap = true, silent = true })
