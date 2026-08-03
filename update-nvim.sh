#!/usr/bin/env bash

# Install or update Neovim to a pinned, tested release.
# Bump NVIM_VERSION deliberately after testing - this never chases "latest"
# automatically, so every machine gets the same build until you move the pin.

# NVIM_VERSION="v0.12.4"
NVIM_VERSION="v0.11.7"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()     { echo -e "${RED}[ERROR]${NC} $1"; }

_nvim_arch() {
    case "$(uname -m)" in
        x86_64)        echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) return 1 ;;
    esac
}

_nvim_installed_tag() {
    command -v nvim >/dev/null 2>&1 || return 0
    nvim --version | head -1 | grep -oE 'v[0-9.]+'
}

update_nvim() {
    local auto_yes=false force=false
    for a in "$@"; do
        case $a in
            -y|--yes) auto_yes=true ;;
            --force)  force=true ;;
        esac
    done

    if [[ "$OSTYPE" == darwin* ]]; then
        warn "macOS uses Homebrew, not the pinned tarball; this script doesn't manage that pin."
        command -v brew >/dev/null 2>&1 || { err "Homebrew required on macOS"; return 1; }
        brew upgrade neovim || brew install neovim
        return $?
    fi

    local arch
    arch=$(_nvim_arch) || { err "Unsupported architecture: $(uname -m)"; return 1; }

    local installed
    installed=$(_nvim_installed_tag)
    info "Pinned:    $NVIM_VERSION"
    [ -n "$installed" ] && info "Installed: $installed" || info "Neovim not currently installed"

    if [ "$force" = false ] && [ "$installed" = "$NVIM_VERSION" ]; then
        success "Neovim already at pinned version ($NVIM_VERSION)"
        return 0
    fi

    if [ "$auto_yes" = false ] && [ -n "$installed" ]; then
        read -p "Install pinned Neovim ${NVIM_VERSION} (currently ${installed})? (y/N) " -n 1 -r; echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && { info "Skipped"; return 0; }
    fi

    local asset="nvim-linux-${arch}"
    local url="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${asset}.tar.gz"
    local tmp; tmp=$(mktemp -d)

    info "Downloading ${asset} ${NVIM_VERSION}..."
    curl -fL --progress-bar "$url" -o "$tmp/nvim.tar.gz" || { err "Download failed: $url"; rm -rf "$tmp"; return 1; }

    info "Installing to /opt/${asset}..."
    sudo rm -rf "/opt/${asset}"
    sudo tar -C /opt -xzf "$tmp/nvim.tar.gz" || { err "Extract failed"; rm -rf "$tmp"; return 1; }
    sudo ln -sf "/opt/${asset}/bin/nvim" /usr/local/bin/nvim
    rm -rf "$tmp"

    if [ "$(_nvim_installed_tag)" = "$NVIM_VERSION" ]; then
        success "Neovim installed: $NVIM_VERSION"
    else
        err "Post-install version check failed"; return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update_nvim "$@"
fi
