# NVIM-CONFIG

A modern, optimized Neovim configuration with LSP support, fuzzy finding, file management, and more.

## FEATURES

- **LSP Integration**: Full language server support with code actions, diagnostics, formatting, and refactoring
- **Smart File Navigation**: Oil.nvim for directory browsing, Telescope for fuzzy finding, Harpoon for quick file switching
- **Auto-completion**: Powered by nvim-cmp with LSP integration
- **Syntax Highlighting**: Treesitter-based highlighting and code understanding
- **Git Integration**: Built-in git support through various plugins
- **Markdown Support**: Live preview with custom styling and Mermaid diagram support
- **Terminal Integration**: Floating terminal with toggleterm
- **Optimized Loading**: Lazy-loaded plugins for fast startup times

## INSTALLATION

### Quick Install (Recommended)

For automatic installation with OS and architecture detection:

```bash
curl -fsSL https://raw.githubusercontent.com/PreparedBag/nvim-config/main/install.sh | bash -s -- -y
```

Or download and inspect the script first:

```bash
curl -fsSL https://raw.githubusercontent.com/PreparedBag/nvim-config/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

**What the installer does:**
- Detects your OS (Ubuntu, Debian, Fedora, Arch, macOS) and architecture (x86_64, ARM64)
- Installs Neovim 0.10.0+ automatically
- Installs all required dependencies
- Sets up Node.js via nvm
- Clones the configuration
- Backs up any existing config
- Configures your shell

**Supported Operating Systems:**
- Ubuntu / Debian / Pop!_OS
- Fedora
- Arch Linux / Manjaro
- macOS (with Homebrew)

**Supported Architectures:**
- x86_64 (Intel/AMD 64-bit)
- ARM64 / aarch64 (Raspberry Pi 4, Apple Silicon, etc.)

**Uninstall:**
To remove the configuration and optionally Neovim itself:
```bash
curl -fsSL https://raw.githubusercontent.com/PreparedBag/nvim-config/main/uninstall.sh | bash
```

**Troubleshooting the installer:**
If the automated installation fails:
1. Check the error messages - they indicate what went wrong
2. Try the manual installation method below
3. Make sure you have sudo privileges
4. On macOS, ensure Homebrew is installed first: https://brew.sh
5. Check that your OS is supported (see list above)

---

### Manual Installation

If you prefer to install manually, follow these steps:

Follow these steps in order:

1. **Update Neovim** - Install Neovim 0.10.0 or higher
2. **Install Prerequisites** - Install required dependencies and tools
3. **Clone Configuration** - Download this config to `~/.config/nvim`
4. **First Launch** - Let plugins auto-install on first run
5. **Verify Setup** - Run `:checkhealth` to confirm everything works

### Step 1: Update Neovim

Make sure you are using the latest Neovim (0.10.0+). The ones in the apt sources are usually too old for these plugins:

https://github.com/neovim/neovim/blob/master/INSTALL.md

#### x86_64

```bash
# Download and install Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm nvim-linux-x86_64.tar.gz

# Add to PATH
grep -qxF 'export PATH="$PATH:/opt/nvim-linux-x86_64/bin"' ~/.bashrc || echo 'export PATH="$PATH:/opt/nvim-linux-x86_64/bin"' >> ~/.bashrc

# Create alias (Optional)
touch ~/.bash_aliases
grep -qxF "alias vim='/opt/nvim-linux-x86_64/bin/nvim'" ~/.bash_aliases || echo "alias vim='/opt/nvim-linux-x86_64/bin/nvim'" >> ~/.bash_aliases

# Reload shell configuration
source ~/.bashrc
```

#### ARM_64

```bash
# Install build dependencies
sudo apt install ninja-build gettext cmake unzip curl build-essential

# Build from source
cd ~
git clone https://github.com/neovim/neovim
cd neovim
make CMAKE_BUILD_TYPE=Release
sudo make install

# Create alias (Optional)
touch ~/.bash_aliases
grep -qxF "alias vim='nvim'" ~/.bash_aliases || echo "alias vim='nvim'" >> ~/.bash_aliases

# Reload shell configuration
source ~/.bashrc
```

**Note for ARM_64**: `sudo make install` installs Neovim to `/usr/local/bin/nvim`, which is already in your PATH. No additional PATH configuration needed.

#### Verify Installation

After installing Neovim, verify it's working:

```bash
nvim --version
```

You should see Neovim v0.10.0 or higher. If you get "command not found", restart your terminal and try again.

### Step 2: Install Prerequisites

For full functionality, install the following dependencies:

```bash
sudo apt install luarocks ripgrep nodejs npm golang cargo default-jdk-headless default-jre-headless fd-find python3-neovim
sudo npm install -g neovim yarn
```

### Update Node.js with nvm

Install and use the latest LTS version of Node.js:

```bash
# Install nvm
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load nvm into current shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install and use LTS version
nvm install --lts
nvm use --lts

# Verify installation
node --version
npm --version
```

**Note**: After installing nvm, you may need to restart your terminal or run `source ~/.bashrc` for it to take effect in future sessions.

### Step 3: Clone Configuration

***IMPORTANT:*** Backup any existing nvim configurations before proceeding!

```bash
# Backup existing config (if any)
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)

# Clone this configuration
git clone https://github.com/PreparedBag/nvim-config.git ~/.config/nvim
```

### Step 4: First Launch

Launch Neovim for the first time:

```bash
nvim
```

On first launch, Neovim will automatically:
1. Install lazy.nvim plugin manager
2. Download and install all plugins
3. Set up LSP servers via Mason

This may take a few minutes. Once complete, restart Neovim.

### Step 5: Verify Setup

Check the health of plugins by running inside nvim:

```vim
:checkhealth
```

You can add additional dependencies if needed based on the health check results.

## KEY FEATURES & KEYBINDINGS

### File Navigation
- `<leader>fe` - Open Oil file explorer (supports `nvim .`)
- `<leader>h` - Toggle hidden files (in Oil)
- `<leader>ff` - Fuzzy find files
- `<leader>fp` - Live grep search
- `<leader>fb` - Find buffers

### LSP Features
- `gd` - Go to definition
- `gD` - Go to declaration
- `gi` - Go to implementation
- `K` - Hover documentation
- `<leader>la` - Code actions
- `<leader>ln` - Rename symbol
- `<leader>lf` - Format document
- `<leader>lr` - Show references
- `<leader>ld` - Show diagnostics
- `<leader>j` / `<leader>k` - Navigate diagnostics

### Harpoon Quick Switching
- `<leader>a` - Add file to Harpoon
- `<leader>e` - Toggle Harpoon menu
- `<leader>1-8` - Jump to Harpoon file 1-8

### Terminal
- `<leader>,` - Toggle floating terminal

### Other Useful Keybindings
- `<leader>u` - Toggle undo tree
- `<leader>bt` - Toggle binary view (xxd preview)
- `gcc` - Comment line (normal mode)
- `gc` - Comment selection (visual mode)

Press `<Space>` (leader key) to see all available keybindings via which-key.

## OPTIONAL CONFIGURATIONS

### INSTALL CATPPUCCIN TERMINAL THEME

Navigate to a directory where you want to clone the repo and run:

```bash
git clone https://github.com/catppuccin/gnome-terminal.git
cd gnome-terminal
./install.py
```

### MARKDOWN-PREVIEW

The markdown preview plugin should install automatically on first use. If you encounter issues:

```bash
cd ~/.local/share/nvim/lazy/markdown-preview.nvim/app
yarn install
```

**Note:** This config uses `yarn` for markdown-preview. Make sure yarn is installed:

```bash
npm install -g yarn
```

### UPDATING MERMAID.JS

To update mermaid.js for markdown diagrams, download the desired version and copy it to:

```bash
~/.local/share/nvim/lazy/markdown-preview.nvim/app/_static/
```

Example with version 11.6.0:

```bash
# Download mermaid.min.js to your config directory first
cp ~/.config/nvim/mermaid-11.6.0.min.js ~/.local/share/nvim/lazy/markdown-preview.nvim/app/_static/
```

## LSP CONFIGURATION

### Supported Languages

The following language servers are automatically installed:
- **C/C++**: clangd
- **Python**: pyright
- **Lua**: lua_ls
- **JavaScript/TypeScript**: ts_ls
- **HTML**: html
- **CSS**: cssls

### Generating compile_commands.json (C/C++)

For proper C/C++ LSP functionality, you may need to generate a `compile_commands.json` file:

- `<leader>lgc` - Generate via CMake
- `<leader>lgw` - Generate via West (Zephyr)
- `<leader>lgz` - Generate Zephyr-specific compile_commands.json
- `<leader>lgg` - Generate generic compile_commands.json

## TROUBLESHOOTING

### LSP Not Working

1. Check if the language server is installed: `:Mason`
2. Check LSP status: `:LspInfo`
3. Check health: `:checkhealth`
4. For C/C++, ensure `compile_commands.json` exists in your project root

### Slow Startup

This config is optimized for fast startup using lazy loading. If you experience slowness:

1. Check your plugin count: `:Lazy`
2. Profile startup time: `nvim --startuptime startup.log`
3. Ensure you're using Neovim 0.10.0+

### Plugins Not Loading

1. Update plugins: `:Lazy sync`
2. Check for errors: `:Lazy log`
3. Clean and reinstall: `:Lazy clean` then `:Lazy sync`

### Telescope Not Finding Files

Make sure `ripgrep` and `fd-find` are installed:

```bash
sudo apt install ripgrep fd-find
```

### Oil File Explorer Issues

Oil loads immediately when you run `nvim .`. If it's not working:

1. Check if Oil is installed: `:Lazy`
2. Try manually opening: `:Oil`
3. Check for conflicts with other file explorers

## PERFORMANCE OPTIMIZATIONS

This configuration includes several performance optimizations:

- **Lazy Loading**: Plugins only load when needed
- **Event-based Loading**: LSP and Treesitter load on `BufReadPost` instead of `BufReadPre`
- **Deferred Keymaps**: Non-essential keymaps load after startup
- **Optimized CMP**: Limited to 50 entries for faster completion
- **Minimal Startup**: Only colorscheme and Oil load immediately

## CUSTOMIZATION

### Changing Colorscheme

Edit `lua/config/lazy.lua` and change:

```lua
vim.cmd.colorscheme "catppuccin-frappe"
```

To one of:
- `catppuccin-latte` / `catppuccin-frappe` / `catppuccin-macchiato` / `catppuccin-mocha`
- `tokyonight`
- Any colorscheme from lunarvim/colorschemes

### Adding Custom Keybindings

Add your keybindings to `lua/config/keymaps.lua` or within specific plugin configs.

### Adding New LSP Servers

1. Open Mason: `:Mason`
2. Search for your language server
3. Press `i` to install
4. Add configuration in `lua/plugins/lsp-config.lua`

## STRUCTURE

```
~/.config/nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/
│   │   ├── setup.lua          # Neovim options
│   │   ├── keymaps.lua        # Global keymaps
│   │   ├── scripts.lua        # Custom functions
│   │   ├── lazy.lua           # Plugin manager setup
│   │   └── autocmds.lua       # Auto commands
│   └── plugins/               # Plugin configurations
│       ├── colorschemes.lua
│       ├── lsp-config.lua
│       ├── telescope.lua
│       ├── oil.lua
│       ├── harpoon.lua
│       └── ...
└── markdown/
    └── markdown.css           # Markdown preview styling
```

## SUPPORT

For issues or questions:
1. Check `:checkhealth` first
2. Review plugin documentation: `:help <plugin-name>`
3. Check the issues on GitHub

## LICENSE

This configuration is provided as-is. Feel free to modify and distribute as needed.
