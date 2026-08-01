#!/usr/bin/env bash

# Neovim config installer (basics only).
# Installs latest Neovim + the handful of tools Telescope and Treesitter need.
# LSP/DAP toolchains are handled inside Neovim (Mason), gated behind dev mode,
# so this script deliberately does NOT install them.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

NVIM_CONFIG_REPO="https://github.com/PreparedBag/nvim-config.git"
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
            -h|--help)
                echo "Neovim config installer"
                echo "Usage: $0 [-y|--yes] [-h|--help]"
                echo "  -y  skip the confirmation prompt (for piped installs)"
                exit 0 ;;
            *) warn "Unknown option: $1"; shift ;;
        esac
    done
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

# true if $1 >= $2 (semver-ish)
version_ge() { printf '%s\n%s' "$2" "$1" | sort -V -C; }

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

check_root() {
    if [[ $EUID -eq 0 ]]; then
        err "Do not run as root. Run as a regular user (sudo is used where needed)."
        exit 1
    fi
}

# Sets OS and ARCH_TAG (the neovim release asset arch: x86_64 or arm64)
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
        *) err "Unsupported architecture: $(uname -m) (need x86_64 or arm64)"; exit 1 ;;
    esac
    info "OS: $OS   Arch: $ARCH_TAG"
}

# Install the tools Telescope + Treesitter need, plus clipboard support.
install_deps() {
    step "Installing basic dependencies..."
    case $OS in
        ubuntu|debian|pop|raspbian)
            sudo apt-get update
            # ripgrep/fd -> telescope; build-essential -> treesitter parser compile;
            # xclip + wl-clipboard -> system clipboard (X11 and Wayland)
            sudo apt-get install -y \
                git curl tar unzip \
                ripgrep fd-find \
                build-essential \
                xclip wl-clipboard || { err "apt install failed"; return 1; } ;;
        fedora)
            sudo dnf install -y git curl tar unzip ripgrep fd-find \
                gcc gcc-c++ make xclip wl-clipboard || return 1 ;;
        arch|manjaro)
            sudo pacman -S --noconfirm git curl tar unzip ripgrep fd \
                base-devel xclip wl-clipboard || return 1 ;;
        macos)
            command_exists brew || { err "Homebrew required: https://brew.sh"; return 1; }
            brew install git curl ripgrep fd || return 1 ;;  # pbcopy is built in
        *)
            warn "Install manually: git curl ripgrep fd, a C compiler, a clipboard tool" ;;
    esac
    success "Dependencies installed"
}

# Download + install the latest Neovim release tarball for this arch.
install_neovim_linux() {
    local asset="nvim-linux-${ARCH_TAG}"
    local url="https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz"
    local tmp; tmp=$(mktemp -d)

    info "Downloading latest Neovim ($asset)..."
    if ! curl -fL --progress-bar "$url" -o "$tmp/nvim.tar.gz"; then
        err "Download failed: $url"; rm -rf "$tmp"; return 1
    fi

    info "Installing to /opt/${asset}..."
    sudo rm -rf "/opt/${asset}"
    if ! sudo tar -C /opt -xzf "$tmp/nvim.tar.gz"; then
        err "Extract failed"; rm -rf "$tmp"; return 1
    fi
    sudo ln -sf "/opt/${asset}/bin/nvim" /usr/local/bin/nvim
    rm -rf "$tmp"
    INSTALLED_NVIM=true
}

install_neovim() {
    step "Installing Neovim..."

    if command_exists nvim; then
        local cur; cur=$(nvim --version | head -n1 | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
        info "Found Neovim $cur"
        if [ "$AUTO_YES" = false ]; then
            read -p "Update to the latest Neovim? (y/N) " -n 1 -r; echo ""
            [[ ! $REPLY =~ ^[Yy]$ ]] && { info "Keeping existing Neovim"; return 0; }
        fi
    fi

    case $OS in
        ubuntu|debian|pop|raspbian|fedora|arch|manjaro)
            install_neovim_linux || return 1 ;;
        macos)
            brew install neovim || brew upgrade neovim || return 1 ;;
    esac

    if command_exists nvim; then
        success "Neovim $(nvim --version | head -n1 | grep -oP 'v\K[0-9.]+') ready"
    else
        err "nvim not found after install"; return 1
    fi
}

# Add a `vim` -> `nvim` alias in the right shell rc.
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
    if ! git clone "$NVIM_CONFIG_REPO" "$HOME/.config/nvim"; then
        err "Clone failed"; return 1
    fi
    success "Config cloned to ~/.config/nvim"
}

main() {
    parse_args "$@"
    check_root
    detect_system

    echo ""
    warn "This will install the latest Neovim, basic tools (ripgrep, fd, a C"
    warn "compiler, clipboard support), add a vim alias, and clone your config."
    info "LSP/debugger toolchains are NOT installed (handled in-editor via dev mode)."

    if [ "$AUTO_YES" = false ]; then
        echo ""
        read -p "Continue? (y/N) " -n 1 -r; echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && { info "Cancelled"; exit 0; }
    fi

    install_deps      || { err "Dependency install failed"; rollback; exit 1; }
    install_neovim    || { err "Neovim install failed";    rollback; exit 1; }
    backup_config     || { err "Backup failed";            rollback; exit 1; }
    clone_config      || { err "Config clone failed";      rollback; exit 1; }
    setup_alias       || warn "Alias setup had issues (non-critical)"

    step "Done!"
    echo "  1. Restart your shell (or: source your rc file)"
    echo "  2. Run: nvim  — plugins install on first launch"
    echo "  3. Run :checkhealth to verify"
    [ -n "$BACKUP_DIR" ] && info "Previous config backed up at: $BACKUP_DIR"
}

main "$@"
