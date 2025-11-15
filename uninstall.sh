#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${GREEN}==>${NC} ${BLUE}$1${NC}\n"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user."
        exit 1
    fi
}

# Remove Neovim configuration
remove_config() {
    print_step "Removing Neovim configuration..."
    
    if [ -d "$HOME/.config/nvim" ]; then
        backup_dir="$HOME/.config/nvim.removed.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.config/nvim" "$backup_dir"
        print_success "Configuration moved to: $backup_dir"
        print_info "You can safely delete this directory if you don't need it"
    else
        print_info "No Neovim configuration found at ~/.config/nvim"
    fi
}

# Remove Neovim data
remove_data() {
    print_step "Removing Neovim data..."
    
    if [ -d "$HOME/.local/share/nvim" ]; then
        print_info "Removing plugins and LSP data..."
        rm -rf "$HOME/.local/share/nvim"
        print_success "Removed ~/.local/share/nvim"
    fi
    
    if [ -d "$HOME/.local/state/nvim" ]; then
        print_info "Removing state data..."
        rm -rf "$HOME/.local/state/nvim"
        print_success "Removed ~/.local/state/nvim"
    fi
    
    if [ -d "$HOME/.cache/nvim" ]; then
        print_info "Removing cache..."
        rm -rf "$HOME/.cache/nvim"
        print_success "Removed ~/.cache/nvim"
    fi
}

# Remove shell aliases (optional)
remove_aliases() {
    print_step "Checking for vim aliases..."
    
    if [ -f "$HOME/.bash_aliases" ]; then
        if grep -q "alias vim=" "$HOME/.bash_aliases"; then
            print_warning "Found vim alias in ~/.bash_aliases"
            read -p "Remove vim -> nvim alias? (y/N) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sed -i '/alias vim=/d' "$HOME/.bash_aliases"
                print_success "Removed vim alias"
            fi
        fi
    fi
    
    if [ -f "$HOME/.bashrc" ]; then
        if grep -q "nvim" "$HOME/.bashrc"; then
            print_info "Found nvim references in ~/.bashrc"
            print_info "You may want to manually review ~/.bashrc"
        fi
    fi
}

# Optionally remove Neovim itself
remove_neovim() {
    print_step "Checking Neovim installation..."
    
    if command -v nvim >/dev/null 2>&1; then
        nvim_location=$(which nvim)
        print_info "Neovim is installed at: $nvim_location"
        
        read -p "Remove Neovim itself? (y/N) " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [[ "$nvim_location" == "/opt/nvim"* ]]; then
                print_info "Removing Neovim from /opt..."
                sudo rm -rf /opt/nvim*
                sudo rm -f /usr/local/bin/nvim
                print_success "Removed Neovim"
            elif [[ "$nvim_location" == "/usr/local/bin/nvim" ]]; then
                print_warning "Neovim appears to be built from source"
                print_info "To fully remove, you may need to:"
                print_info "  cd ~/neovim && sudo make uninstall"
                print_info "  rm -rf ~/neovim"
            else
                print_warning "Neovim was installed via package manager"
                print_info "To remove, use your package manager:"
                print_info "  Ubuntu/Debian: sudo apt remove neovim"
                print_info "  Fedora: sudo dnf remove neovim"
                print_info "  Arch: sudo pacman -R neovim"
                print_info "  macOS: brew uninstall neovim"
            fi
        fi
    else
        print_info "Neovim is not installed or not in PATH"
    fi
}

# Optional: Remove global npm packages
remove_npm_packages() {
    print_step "Checking for global npm packages..."
    
    if command -v npm >/dev/null 2>&1; then
        print_warning "The following global npm packages were installed:"
        print_info "  - neovim (npm package for Neovim)"
        print_info "  - yarn (package manager)"
        
        read -p "Remove these npm packages? (y/N) " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            npm uninstall -g neovim yarn 2>/dev/null || print_warning "Some packages may not have been installed"
            print_success "Removed npm packages"
        fi
    fi
}

# Show what was removed
show_summary() {
    print_step "Uninstall Summary"
    
    print_success "Uninstallation complete!"
    echo ""
    print_info "What was removed:"
    echo "  - Neovim configuration (~/.config/nvim)"
    echo "  - Plugin data (~/.local/share/nvim)"
    echo "  - State data (~/.local/state/nvim)"
    echo "  - Cache (~/.cache/nvim)"
    
    if [ -d "$HOME/.config/nvim.removed."* ]; then
        echo ""
        print_info "Your configuration was backed up. To find it:"
        echo "  ls -la ~/.config/nvim.removed.*"
    fi
    
    echo ""
    print_info "What was NOT removed (if you want to clean up manually):"
    echo "  - nvm and Node.js (~/.nvm)"
    echo "  - System packages (ripgrep, fd-find, etc.)"
    echo "  - Neovim itself (use your package manager if desired)"
    echo ""
    print_warning "You may need to restart your terminal for changes to take effect"
}

# Main uninstall flow
main() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        Neovim Configuration Uninstaller                ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    check_root
    
    print_warning "This script will remove:"
    echo "  - Your Neovim configuration (~/.config/nvim)"
    echo "  - All plugins and LSP data"
    echo "  - Cache and state files"
    echo ""
    print_info "Your configuration will be backed up before removal"
    echo ""
    read -p "Continue with uninstallation? (y/N) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstallation cancelled"
        exit 0
    fi
    
    echo ""
    
    # Run uninstall steps
    remove_config
    remove_data
    remove_aliases
    remove_neovim
    remove_npm_packages
    show_summary
}

# Run main function
main "$@"
