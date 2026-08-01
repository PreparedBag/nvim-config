#!/usr/bin/env bash

# Install or update Neovim to the latest official release tarball.
# Standalone:      ./update-nvim.sh          (prompts if already current)
#                  ./update-nvim.sh -y       (no prompts)
#                  ./update-nvim.sh --force  (reinstall even if up to date)
# From install.sh: ./update-nvim.sh -y       (or: source it, call update_nvim)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()     { echo -e "${RED}[ERROR]${NC} $1"; }

# Map uname -m to the neovim release asset arch. Echoes x86_64 | arm64, or fails.
_nvim_arch() {
    case "$(uname -m)" in
        x86_64)        echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) return 1 ;;
    esac
}

# Latest release tag (e.g. v0.12.4) from the GitHub API, or empty on failure.
_nvim_latest_tag() {
    curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null \
        | grep -oE '"tag_name":\s*"[^"]+"' | head -1 | grep -oE 'v[0-9.]+'
}

# Installed version as a tag (e.g. v0.12.4), or empty if nvim isn't present.
_nvim_installed_tag() {
    command -v nvim >/dev/null 2>&1 || return 0
    nvim --version | head -1 | grep -oE 'v[0-9.]+'
}

# Main entry point. Args: pass "-y" to skip prompts, "--force" to always install.
update_nvim() {
    local auto_yes=false force=false
    for a in "$@"; do
        case $a in
            -y|--yes) auto_yes=true ;;
            --force)  force=true ;;
        esac
    done

    # macOS: defer to Homebrew rather than the linux tarball.
    if [[ "$OSTYPE" == darwin* ]]; then
        command -v brew >/dev/null 2>&1 || { err "Homebrew required on macOS"; return 1; }
        info "Updating Neovim via Homebrew..."
        brew upgrade neovim || brew install neovim
        return $?
    fi

    local arch
    arch=$(_nvim_arch) || { err "Unsupported architecture: $(uname -m) (need x86_64 or arm64)"; return 1; }

    local installed latest
    installed=$(_nvim_installed_tag)
    latest=$(_nvim_latest_tag)

    [ -n "$installed" ] && info "Installed: $installed" || info "Neovim not currently installed"
    [ -n "$latest" ] && info "Latest:    $latest" || warn "Could not determine latest version (will install anyway)"

    # Skip if already current, unless forced.
    if [ "$force" = false ] && [ -n "$installed" ] && [ -n "$latest" ] && [ "$installed" = "$latest" ]; then
        success "Neovim is already up to date ($installed)"
        return 0
    fi

    # Confirm when run interactively with an existing install.
    if [ "$auto_yes" = false ] && [ -n "$installed" ]; then
        read -p "Update Neovim ${installed:-} -> ${latest:-latest}? (y/N) " -n 1 -r; echo ""
        [[ ! $REPLY =~ ^[Yy]$ ]] && { info "Skipped"; return 0; }
    fi

    local asset="nvim-linux-${arch}"
    local url="https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz"
    local tmp; tmp=$(mktemp -d)

    info "Downloading ${asset}..."
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

    if command -v nvim >/dev/null 2>&1; then
        success "Neovim updated to $(_nvim_installed_tag)"
    else
        err "nvim not found after install"; return 1
    fi
}

# Run update_nvim only when executed directly, not when sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update_nvim "$@"
fi
