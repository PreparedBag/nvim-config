#!/usr/bin/env bash

# Dev-mode installer: LSP/DAP/preview prerequisites on top of the basic install.
# Mason installs servers/formatters/adapters in-editor, so this only provides the
# runtimes + native toolchains Mason builds on:
#   - Node.js + npm + yarn   (ts_ls/cssls/html/bash-ls; yarn for markdown-preview)
#   - clang + clangd + arm-none-eabi-gcc   (C / embedded)
#   - neovim node provider package
# Run the basic installer first.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
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

install_node() {
    step "Installing Node.js + npm..."
    if command_exists node && command_exists npm; then
        info "Node $(node --version) already present"
    else
        case $OS in
            ubuntu|debian|pop|raspbian)
                curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - \
                    && sudo apt-get install -y nodejs || { err "Node install failed"; return 1; } ;;
            fedora)  sudo dnf install -y nodejs npm || return 1 ;;
            arch|manjaro) sudo pacman -S --noconfirm nodejs npm || return 1 ;;
            macos)   brew install node || return 1 ;;
        esac
    fi
    info "Installing neovim node provider package..."
    sudo npm install -g neovim || warn "Could not install neovim npm package"
    success "Node ready"
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
    success "C / embedded toolchain ready"
}

install_preview() {
    step "Setting up markdown preview deps (yarn)..."
    if command_exists yarn; then
        info "yarn already present ($(yarn --version))"
    else
        info "Installing yarn globally via npm..."
        if ! sudo npm install -g yarn; then
            err "Failed to install yarn — markdown-preview build will fail"
            return 1
        fi
    fi
    success "Preview deps ready (Neovim runs the yarn build on first load)"
}

main() {
    parse_args "$@"
    check_root
    detect_system

    command_exists nvim || warn "Neovim not found — run the basic installer first."

    echo ""
    warn "Dev mode installs: Node.js+npm+yarn, clang/clangd, arm-none-eabi-gcc,"
    warn "and the neovim node provider. Mason handles servers/adapters in-editor."
    if [ "$AUTO_YES" = false ]; then
        read -p "Continue? (y/N) " -n 1 -r; echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && { info "Cancelled"; exit 0; }
    fi

    install_node        || { err "Node setup failed"; exit 1; }
    install_c_embedded  || { err "C/embedded setup failed"; exit 1; }
    install_preview     || { err "Preview setup failed"; exit 1; }

    step "Done!"
    echo "  1. Launch nvim in dev mode (DEV_ENABLED)"
    echo "  2. lazy will build markdown-preview (yarn) on first load"
    echo "  3. :Mason installs servers/formatters/adapters"
    echo "  4. Verify: :checkhealth mason  and  :checkhealth vim.provider"
    info "clangd cross-driver expects arm-none-eabi-* in PATH for embedded."
}

main "$@"
