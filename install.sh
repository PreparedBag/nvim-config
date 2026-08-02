#!/usr/bin/env bash

# Base Neovim config installer.
# Installs pinned Neovim, the essentials Telescope/Treesitter need, Node.js +
# tree-sitter-cli (required by nvim-treesitter's `main` branch, which the
# markdown preview depends on), a vim alias, and this config.
# LSP/debugger toolchains are NOT installed here - see install-extras.sh.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

NVIM_CONFIG_REPO="https://github.com/PreparedBag/nvim-config.git"
NODE_MAJOR="24"
TREE_SITTER_CLI_VERSION="0.26.11"
AUTO_YES=false
INSTALLED_NVIM=false
BACKUP_DIR=""

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()     { echo -e "${RED}[ERROR]${NC} $1"; }
step()    { echo -e "\n${GREEN}==>${NC} ${BLUE}$1${NC}"; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes) AUTO_YES=true; shift ;;
            -h|--help) echo "Usage: $0 [-y|--yes] [-h|--help]"; exit 0 ;;
            *) warn "Unknown option: $1"; shift ;;
        esac
    done
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

rollback() {
    step "Rolling back..."
    if [ "$INSTALLED_NVIM" = true ]; then
        sudo rm -rf /opt/nvim-linux-x86_64 /opt/nvim-linux-arm64 2>/dev/null
        sudo rm -f /usr/local/bin/nvim 2>/dev/null
        info "Removed Neovim install"
    fi
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        rm -rf "$HOME/.config/nvim"
        mv "$BACKUP_DIR" "$HOME/.config/nvim" && success "Restored previous config"
    fi
}

check_root() { [[ $EUID -eq 0 ]] && { err "Do not run as root."; exit 1; }; }

detect_system() {
    step "Detecting system..."
    case "$OSTYPE" in
        linux-gnu*)
            [ -f /etc/os-release ] && . /etc/os-release && OS=$ID || { err "Cannot detect distro"; exit 1; } ;;
        darwin*) OS="macos" ;;
        *) err "Unsupported OS: $OSTYPE"; exit 1 ;;
    esac
    case "$(uname -m)" in
        x86_64)         ARCH_TAG="x86_64" ;;
        aarch64|arm64)  ARCH_TAG="arm64" ;;
        *) err "Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac
    info "OS: $OS   Arch: $ARCH_TAG"
}

install_deps() {
    step "Installing basic dependencies..."
    case $OS in
        ubuntu|debian|pop|raspbian)
            sudo apt-get update
            sudo apt-get install -y git curl tar unzip ripgrep fd-find \
                build-essential xclip wl-clipboard || { err "apt install failed"; return 1; } ;;
        fedora)
            sudo dnf install -y git curl tar unzip ripgrep fd-find \
                gcc gcc-c++ make xclip wl-clipboard || return 1 ;;
        arch|manjaro)
            sudo pacman -S --noconfirm git curl tar unzip ripgrep fd \
                base-devel xclip wl-clipboard || return 1 ;;
        macos)
            command_exists brew || { err "Homebrew required: https://brew.sh"; return 1; }
            brew install git curl ripgrep fd || return 1 ;;
        *) warn "Install manually: git curl ripgrep fd, a C compiler, a clipboard tool" ;;
    esac
    success "Dependencies installed"
}

# Base dependency now: nvim-treesitter `main` needs tree-sitter-cli (via npm)
# to compile parsers, and markdown preview needs Node too.
install_node() {
    step "Installing Node.js (pinned to v${NODE_MAJOR}.x)..."
    if command_exists node && [ "$(node --version | grep -oE '^v[0-9]+' | tr -d v)" = "$NODE_MAJOR" ]; then
        info "Node $(node --version) already at pinned major version"
        return 0
    fi
    case $OS in
        ubuntu|debian|pop|raspbian)
            curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash - \
                && sudo apt-get install -y nodejs || { err "Node install failed"; return 1; } ;;
        fedora)
            curl -fsSL "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x" | sudo bash - \
                && sudo dnf install -y nodejs || return 1 ;;
        arch|manjaro)
            sudo pacman -S --noconfirm nodejs npm || return 1 ;;  # Arch tracks current, not per-major
        macos)
            brew install node@${NODE_MAJOR} || return 1 ;;
    esac
    success "Node ready: $(node --version)"
}

install_treesitter_cli() {
    step "Installing tree-sitter-cli ${TREE_SITTER_CLI_VERSION}..."
    local current
    current=$(command_exists tree-sitter && tree-sitter --version 2>/dev/null | grep -oE '[0-9.]+')
    if [ "$current" = "$TREE_SITTER_CLI_VERSION" ]; then
        info "tree-sitter-cli already at pinned version"
        return 0
    fi
    sudo npm install -g "tree-sitter-cli@${TREE_SITTER_CLI_VERSION}" || { err "tree-sitter-cli install failed"; return 1; }
    success "tree-sitter-cli ready: $(tree-sitter --version)"
}

install_neovim() {
    step "Installing Neovim (pinned)..."
    local dir; dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ "$AUTO_YES" = true ]; then "$dir/update-nvim.sh" -y || return 1
    else "$dir/update-nvim.sh" || return 1
    fi
    command_exists nvim && INSTALLED_NVIM=true
}

setup_alias() {
    step "Setting up vim alias..."
    local rc="$HOME/.bashrc"
    [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ] && rc="$HOME/.zshrc"
    if grep -q "alias vim=['\"]*nvim" "$rc" 2>/dev/null; then
        info "vim alias already present in $(basename "$rc")"
    else
        printf "\nalias vim='nvim'\n" >> "$rc"
        success "Added vim alias to $(basename "$rc")"
    fi
}

backup_config() {
    if [ -d "$HOME/.config/nvim" ]; then
        step "Backing up existing config..."
        BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.config/nvim" "$BACKUP_DIR"
        success "Backed up to $BACKUP_DIR"
    fi
}

clone_config() {
    step "Cloning Neovim config..."
    git clone "$NVIM_CONFIG_REPO" "$HOME/.config/nvim" || { err "Clone failed"; return 1; }
    success "Config cloned to ~/.config/nvim"
}

main() {
    parse_args "$@"
    check_root
    detect_system

    echo ""
    warn "Installs pinned Neovim ($NVIM_VERSION), basic tools, Node.js v${NODE_MAJOR}.x,"
    warn "tree-sitter-cli ${TREE_SITTER_CLI_VERSION}, a vim alias, and this config."
    info "LSP/debugger toolchains are NOT installed (see install-extras.sh)."

    if [ "$AUTO_YES" = false ]; then
        echo ""
        read -p "Continue? (y/N) " -n 1 -r; echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && { info "Cancelled"; exit 0; }
    fi

    install_deps           || { err "Dependency install failed"; rollback; exit 1; }
    install_neovim          || { err "Neovim install failed";    rollback; exit 1; }
    install_node             || { err "Node install failed";      rollback; exit 1; }
    install_treesitter_cli    || { err "tree-sitter-cli failed";  rollback; exit 1; }
    backup_config              || { err "Backup failed";          rollback; exit 1; }
    clone_config                || { err "Config clone failed";   rollback; exit 1; }
    setup_alias                   || warn "Alias setup had issues (non-critical)"

    step "Done!"
    echo "  1. Restart your shell"
    echo "  2. Run: nvim  - plugins install on first launch"
    echo "  3. Run :TSUpdate to build parsers, then :checkhealth"
    [ -n "$BACKUP_DIR" ] && info "Previous config backed up at: $BACKUP_DIR"
}

main "$@"
