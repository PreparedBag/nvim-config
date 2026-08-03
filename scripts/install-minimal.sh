#!/usr/bin/env bash

# Base Neovim config installer.
# Installs pinned Neovim, the essentials Telescope/Treesitter need, a vim
# alias, and this config (only if not already present — never touches an
# existing ~/.config/nvim). LSP/debugger/preview toolchains are NOT installed
# here - see install-dev.sh.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

NVIM_CONFIG_REPO="https://github.com/PreparedBag/nvim-config.git"
AUTO_YES=false
INSTALLED_NVIM=false

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

clone_config() {
    if [ -d "$HOME/.config/nvim" ]; then
        step "Config already present"
        info "~/.config/nvim exists — leaving it untouched. Not cloning, not backing up."
        return 0
    fi
    step "Cloning Neovim config..."
    git clone "$NVIM_CONFIG_REPO" "$HOME/.config/nvim" || { err "Clone failed"; return 1; }
    success "Config cloned to ~/.config/nvim"
}

main() {
    parse_args "$@"
    check_root
    detect_system

    echo ""
    warn "Installs pinned Neovim, basic tools (ripgrep, fd, a C compiler,"
    warn "clipboard support), a vim alias, and this config (only if not already present)."
    info "LSP/debugger/preview toolchains are NOT installed (see install-dev.sh)."

    if [ "$AUTO_YES" = false ]; then
        echo ""
        read -p "Continue? (y/N) " -n 1 -r; echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && { info "Cancelled"; exit 0; }
    fi

    install_deps   || { err "Dependency install failed"; rollback; exit 1; }
    install_neovim  || { err "Neovim install failed";    rollback; exit 1; }
    clone_config     || { err "Config clone failed";     rollback; exit 1; }
    setup_alias        || warn "Alias setup had issues (non-critical)"

    step "Done!"
    echo "  1. Restart your shell"
    echo "  2. Run: nvim  - plugins install on first launch"
    echo "  3. Run :TSUpdate to build parsers, then :checkhealth"
}

main "$@"
