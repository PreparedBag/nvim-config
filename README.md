# nvim-config

A minimal, fast Neovim setup for C / embedded and general editing, managed by
[lazy.nvim](https://github.com/folke/lazy.nvim). Heavier tooling (LSP, debugger,
markdown preview) lives behind an optional **dev mode**, so the base install
stays light. This README covers the base (non-dev) setup.

## Requirements

The installer handles everything: the latest Neovim, `git`, `curl`, `ripgrep`,
`fd`, a C compiler (for Treesitter parsers), and clipboard support. Works on
`x86_64` and `arm64`, including 64-bit Raspberry Pi OS.

## Install


```bash
cd scripts/
./install-minimal.sh
```

The script backs up any existing `~/.config/nvim`, installs the latest Neovim
for your architecture, adds a `vim -> nvim` alias, installs the essentials, and
clones this config. It rolls back on failure.

Flags: `-y` skip prompts (pipe-friendly: `... | bash -s -- -y`), `-h` help.

First launch installs plugins automatically; run `:checkhealth` afterward to
verify.

## Dev mode (optional)

```bash
cd scripts/
./install-dev.sh
```

Adds the prerequisites for LSP, debugging, and markdown preview - Node.js,
`clang` + `arm-none-eabi-gcc`, and `yarn`. The language servers, formatters, and
debug adapters themselves are installed in-editor by Mason. Dev-only plugins
activate when `DEV_ENABLED` is set; toggle it with `<leader>M` (restart to
apply). Not covered further here.

## Plugins

- **blink.cmp** - completion (LSP, snippets, path, buffer), enabled only in real code buffers with an LSP attached.
- **LuaSnip** + **friendly-snippets** - snippet engine plus a prebuilt collection; custom snippets live in `snippets/`.
- **telescope** (+ fzf, ui-select) - fuzzy finder for files, grep, buffers, and pickers.
- **treesitter** - syntax highlighting, indentation, and folds.
- **oil** - edit the filesystem like a normal buffer.
- **harpoon** - pin and jump between a handful of key files.
- **gitsigns** - inline git hunks: navigate, stage, preview, blame.
- **git** (custom) - a full Git command menu (status, commit, push/pull, branches, stash, tags).
- **comment** - line/block comments, doc comments, and TODO/annotation search.
- **persistence** - auto-saved sessions, restorable per project.
- **undotree** - visualize and browse the undo history.
- **lualine** - statusline.
- **which-key** - popup of available keybindings as you type.
- **noice** - modern cmdline and message UI.
- **number** (custom) - inline hex/dec/bin conversions for C work.

## Keymaps

Leader is `<Space>`. Grouped by prefix. Dev-mode maps (LSP, debugger, markdown/html live servers)
are omitted.

### Files & search - `<leader>f`

| Key | Action |
| --- | --- |
| `<leader>ff` | Find files (fuzzy) |
| `<leader>fa` | Find all files (include ignored) |
| `<leader>fw` | Find word under cursor (ripgrep) |
| `<leader>fp` | Find phrase (live grep) |
| `<leader>fs` | Find string (include all) |
| `<leader>fH` | Help tags |
| `<leader>fc` | Open Nvim config folder |
| `<leader>fd` | Set Telescope cwd here |
| `<leader>fo` | Reset Telescope cwd to original |
| `<leader>fq` | View quickfix list |
| `<leader>fh` | View quickfix history |
| `<leader>ft` | Pending tasks (TODOs) |
| `<leader>fT` | All annotations |
| `<leader>fe` | File explorer (Oil) |

### Buffers & files - `<leader>b`, misc

| Key | Action |
| --- | --- |
| `<leader>bb` | Show all buffers |
| `<leader>bd` | Delete current buffer |
| `<leader>bt` | Toggle binary preview |
| `<leader>q` | Quit without saving |
| `<leader>x` | Make file executable (`chmod +x`) |

### Windows & splits - `<leader>w`, `<leader>s`

| Key | Action |
| --- | --- |
| `<leader>sv` | Vertical split |
| `<leader>sh` | Horizontal split |
| `<leader>wh` / `wj` / `wk` / `wl` | Focus left / down / up / right |
| `<leader>ww` | Toggle window focus |
| `<leader>we` | Equalize all windows |

### Harpoon - `<leader>h`

| Key | Action |
| --- | --- |
| `<leader>ha` | Add file to Harpoon |
| `<leader>hA` | Add buffers to Harpoon |
| `<leader>hc` | Clear Harpoon list |
| `<leader>he` | Harpoon edit (native menu) |
| `<leader>hm` | Harpoon menu (Telescope) |
| `<leader>1`-`<leader>8` | Jump to Harpoon slot 1-8 |

### Git menu - `<leader>g` (custom `git`)

| Key | Action |
| --- | --- |
| `<leader>gs` | Git status |
| `<leader>gl` | Git log |
| `<leader>gc` | Commit staged |
| `<leader>gA` | Add all + commit |
| `<leader>gx` | Discard changes to file |
| `<leader>gp` / `gP` | Push / Pull |
| `<leader>gu` | Push + tags |
| `<leader>gU` | Push + set upstream |
| `<leader>gf` | Fetch + prune |
| `<leader>gt` | New tag |
| `<leader>gb...` | Branches: select, merge, delete, checkout, new |
| `<leader>gz...` | Stash: apply, pop, drop, branch, save |

### Git hunks - `<leader>g` (gitsigns)

| Key | Action |
| --- | --- |
| `<leader>gj` / `gk` | Next / previous hunk |
| `<leader>gq` | Send all hunks to quickfix |
| `<leader>ghs` | Stage hunk (or selection) |
| `<leader>ghr` | Discard hunk (or selection) |
| `<leader>ghu` | Undo stage hunk |
| `<leader>ghS` | Stage buffer |
| `<leader>ghR` | Reset buffer |
| `<leader>ghp` | Preview hunk |
| `<leader>ghb` | Blame line |

### Comments - `<leader>c`

| Key | Action |
| --- | --- |
| `<leader>cc` | Comment line (or selection) |
| `<leader>cb` | Block comment line (or selection) |
| `<leader>cd` | Generate doc comment |

### Sessions - `<leader>p` (persistence)

| Key | Action |
| --- | --- |
| `<leader>pl` | Restore session (cwd) |
| `<leader>pr` | Restore last session |
| `<leader>ps` | Save session |
| `<leader>pd` | Stop saving session |
| `<leader>pq` | Save session and quit |
| `<leader>pp` | Pick a session (Telescope) |

### Numbers - `<leader>n` (custom `number base conversion`)

| Key | Action |
| --- | --- |
| `<leader>np` | Toggle inline base preview |
| `<leader>nt` | Cycle number under cursor in place (hex -> dec -> bin) |
| `<leader>nh` / `nd` / `nb` / `no` | Show + copy as hex / dec / bin / oct |

### Editor & clipboard

| Key | Action |
| --- | --- |
| `<leader>y` | Yank selection to system clipboard |
| `<leader>Y` | Yank line to system clipboard |
| `<leader>p` | Paste without yanking (visual) |
| `<leader>j` / `<leader>k` | Next / previous quickfix item |
| `<leader>u` | Toggle Undotree |
| `<leader>M` | Toggle dev mode (restart to apply) |

## Layout

```
lua/
  config/    core options, keymaps, lazy bootstrap, number tooling
  plugins/   one spec per plugin
  after/     autocommands
snippets/    custom LuaSnip snippets
```
