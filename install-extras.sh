#!/usr/bin/env bash

# Dev-mode installer: LSP/DAP/preview prerequisites on top of the base install.
# Mason installs servers/formatters/adapters in-editor; this only adds:
#   - yarn   (markdown-preview.nvim's build step; Node itself comes from install.sh)
#   - clang + clangd + arm-none-eabi-gcc   (C / embedded)
# Run install.sh first.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

NODE_MAJOR="24"          # fallback only, kept in sync with install.sh's pin
YARN_VERSION="1.22.22"
AUTO_YES=false

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()     { echo -e "${RED}[ERROR]${NC} $1"; }
step()    { echo -e "\n${GREEN}==>${NC} ${BLUE}$1${NC}"; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes) AUTO_YES=true; shift ;;
            -h|--help) echo "Usage: $0 [-y|--yes]"; exit 0 ;;
            *) warn "Unknown option: $1"; shift ;;
        esac
    done
}

command_exists() { command -v "$1" >/dev/null 2>&1; }
check_root() { [[ $EUID -eq 0 ]] && { err "Do not run as root."; exit 1; }; }

detect_system() {
    step "Detecting system..."
    case "$OSTYPE" in
        linux-gnu*)
            [ -f /etc/os-release ] && . /etc/os-release && OS=$ID || { err "Cannot detect distro"; exit 1; } ;;
        darwin*) OS="macos" ;;
        *) err "Unsupported OS: $OSTYPE"; exit 1 ;;
    esac
    info "OS: $OS"
}

# Fallback only - install.sh already installs Node as a base dependency.
ensure_node() {
    step "Checking Node.js..."
    if command_exists node && command_exists npm; then
        info "Node $(node --version) present"
        return 0
    fi
    warn "Node not found - installing (should have come from install.sh)"
    case $OS in
        ubuntu|debian|pop|raspbian)
            curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash - \
                && sudo apt-get install -y nodejs || return 1 ;;
        fedora)  sudo dnf install -y nodejs npm || return 1 ;;
        arch|manjaro) sudo pacman -S --noconfirm nodejs npm || return 1 ;;
        macos)   brew install node || return 1 ;;
    esac
}

install_yarn() {
    step "Installing yarn ${YARN_VERSION} (markdown-preview build dependency)..."
    local current
    current=$(command_exists yarn && yarn --version 2>/dev/null)
    if [ "$current" = "$YARN_VERSION" ]; then
        info "yarn already at pinned version"
        return 0
    fi
    sudo npm install -g "yarn@${YARN_VERSION}" || { err "yarn install failed"; return 1; }
    success "yarn ready: $(yarn --version)"
}

install_c_embedded() {
    step "Installing C / embedded toolchain..."
    case $OS in
        ubuntu|debian|pop|raspbian)
            sudo apt-get install -y clang clangd gcc-arm-none-eabi || { err "C toolchain install failed"; return 1; } ;;
        fedora)
            sudo dnf install -y clang clang-tools-extra arm-none-eabi-gcc-cs || return 1 ;;
        arch|manjaro)
            sudo pacman -S --noconfirm clang arm-none-eabi-gcc || return 1 ;;
        macos)
            brew install llvm && brew install --cask gcc-arm-embedded || return 1 ;;
    esac
    # Note: distro packages aren't individually version-pinned - apt/dnf/pacman
    # give whatever's current in that release's repos. Accepted gap for now.
    success "C / embedded toolchain ready"
}

main() {
    parse_args "$@"
    check_root
    detect_system

    command_exists nvim || warn "Neovim not found - run install.sh first."

    echo ""
    warn "Dev mode installs: yarn ${YARN_VERSION}, clang/clangd, arm-none-eabi-gcc."
    warn "(Node.js and tree-sitter-cli come from install.sh, not here.)"
    if [ "$AUTO_YES" = false ]; then
        read -p "Continue? (y/N) " -n 1 -r; echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && { info "Cancelled"; exit 0; }
    fi

    ensure_node        || { err "Node check failed"; exit 1; }
    install_yarn       || { err "yarn setup failed"; exit 1; }
    install_c_embedded || { err "C/embedded setup failed"; exit 1; }

    step "Done!"
    echo "  1. Launch nvim in dev mode (<leader>M)"
    echo "  2. lazy builds markdown-preview (yarn) on first load"
    echo "  3. :Mason installs servers/formatters/adapters"
}

main "$@"
