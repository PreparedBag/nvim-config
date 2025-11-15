#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
VERBOSE=true
AUTO_YES=false

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                AUTO_YES=true
                shift
                ;;
            -q|--quiet)
                VERBOSE=false
                shift
                ;;
            -h|--help)
                echo "Neovim Configuration Uninstaller"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -y, --yes     Skip confirmation prompts"
                echo "  -q, --quiet   Disable verbose output"
                echo "  -h, --help    Show this help message"
                echo ""
                exit 0
                ;;
            *)
                print_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
}

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

print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[VERBOSE]${NC} $1"
    fi
}

print_command() {
    echo -e "${CYAN}$ ${NC}$1"
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
        print_verbose "Moving config to: $backup_dir"
        
        if ! mv "$HOME/.config/nvim" "$backup_dir"; then
            print_error "Failed to move configuration"
            return 1
        fi
        
        print_success "Configuration moved to: $backup_dir"
        print_info "You can safely delete this directory if you don't need it:"
        print_command "rm -rf $backup_dir"
    else
        print_info "No Neovim configuration found at ~/.config/nvim"
    fi
    
    return 0
}

# Remove Neovim data
remove_data() {
    print_step "Removing Neovim data..."
    
    local data_removed=false
    
    if [ -d "$HOME/.local/share/nvim" ]; then
        print_info "Removing plugins and LSP data..."
        print_verbose "Path: $HOME/.local/share/nvim"
        print_command "rm -rf ~/.local/share/nvim"
        
        if rm -rf "$HOME/.local/share/nvim"; then
            print_success "Removed ~/.local/share/nvim"
            data_removed=true
        else
            print_warning "Failed to remove ~/.local/share/nvim"
        fi
    fi
    
    if [ -d "$HOME/.local/state/nvim" ]; then
        print_info "Removing state data..."
        print_verbose "Path: $HOME/.local/state/nvim"
        print_command "rm -rf ~/.local/state/nvim"
        
        if rm -rf "$HOME/.local/state/nvim"; then
            print_success "Removed ~/.local/state/nvim"
            data_removed=true
        else
            print_warning "Failed to remove ~/.local/state/nvim"
        fi
    fi
    
    if [ -d "$HOME/.cache/nvim" ]; then
        print_info "Removing cache..."
        print_verbose "Path: $HOME/.cache/nvim"
        print_command "rm -rf ~/.cache/nvim"
        
        if rm -rf "$HOME/.cache/nvim"; then
            print_success "Removed ~/.cache/nvim"
            data_removed=true
        else
            print_warning "Failed to remove ~/.cache/nvim"
        fi
    fi
    
    if [ "$data_removed" = false ]; then
        print_info "No Neovim data directories found"
    fi
    
    return 0
}

# Remove shell aliases (optional)
remove_aliases() {
    print_step "Checking for vim aliases..."
    
    local aliases_found=false
    
    if [ -f "$HOME/.bash_aliases" ]; then
        if grep -q "alias vim=" "$HOME/.bash_aliases"; then
            aliases_found=true
            print_warning "Found vim alias in ~/.bash_aliases:"
            grep "alias vim=" "$HOME/.bash_aliases"
            echo ""
            
            read -p "Remove vim -> nvim alias? (y/N)" -n 1 -r
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_verbose "Removing vim alias from .bash_aliases"
                print_command "sed -i '/alias vim=/d' ~/.bash_aliases"
                
                if sed -i.bak '/alias vim=/d' "$HOME/.bash_aliases"; then
                    print_success "Removed vim alias"
                    print_verbose "Backup created: ~/.bash_aliases.bak"
                else
                    print_warning "Failed to remove vim alias"
                fi
            else
                print_info "Keeping vim alias"
            fi
        fi
    fi
    
    if [ -f "$HOME/.bashrc" ]; then
        if grep -q "nvim" "$HOME/.bashrc"; then
            print_info "Found nvim references in ~/.bashrc"
            print_verbose "Showing matches:"
            grep --color=never -n "nvim" "$HOME/.bashrc" || true
            print_warning "You may want to manually review ~/.bashrc"
        fi
    fi
    
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "nvim" "$HOME/.zshrc"; then
            print_info "Found nvim references in ~/.zshrc"
            print_warning "You may want to manually review ~/.zshrc"
        fi
    fi
    
    if [ "$aliases_found" = false ]; then
        print_info "No vim aliases found"
    fi
    
    return 0
}

# Optionally remove Neovim itself
remove_neovim() {
    print_step "Checking Neovim installation..."
    
    if command -v nvim >/dev/null 2>&1; then
        nvim_location=$(which nvim)
        nvim_version=$(nvim --version | head -n1 2>/dev/null || echo "unknown")
        
        print_info "Neovim is installed:"
        print_verbose "Location: $nvim_location"
        print_verbose "Version: $nvim_version"
        echo ""
        
        read -p "Remove Neovim itself? (y/N)" -n 1 -r
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [[ "$nvim_location" == "/opt/nvim"* ]] || [[ "$nvim_location" == "/usr/local/bin/nvim" ]]; then
                # Check if it's the /opt installation
                if [ -d "/opt/nvim-linux64" ]; then
                    print_info "Removing Neovim from /opt..."
                    print_command "sudo rm -rf /opt/nvim-linux64"
                    if sudo rm -rf /opt/nvim-linux64; then
                        print_success "Removed /opt/nvim-linux64"
                    else
                        print_warning "Failed to remove /opt/nvim-linux64"
                    fi
                fi
                
                if [ -L "/usr/local/bin/nvim" ]; then
                    print_info "Removing symlink..."
                    print_command "sudo rm -f /usr/local/bin/nvim"
                    if sudo rm -f /usr/local/bin/nvim; then
                        print_success "Removed /usr/local/bin/nvim symlink"
                    else
                        print_warning "Failed to remove symlink"
                    fi
                fi
                
                print_success "Neovim removed"
                
            elif [ -f "/usr/local/bin/nvim" ] && [ ! -L "/usr/local/bin/nvim" ]; then
                print_warning "Neovim appears to be built from source"
                print_info "To fully remove, you may need to:"
                echo "  1. Find the build directory (usually ~/neovim or /tmp/neovim)"
                echo "  2. Run: cd ~/neovim && sudo make uninstall"
                echo "  3. Remove the directory: rm -rf ~/neovim"
                echo ""
                print_info "Or remove the binary directly:"
                print_command "sudo rm -f /usr/local/bin/nvim"
                
                read -p "Remove nvim binary directly? (y/N) " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if sudo rm -f /usr/local/bin/nvim; then
                        print_success "Removed nvim binary"
                    else
                        print_warning "Failed to remove nvim binary"
                    fi
                fi
                
            else
                print_warning "Neovim was installed via package manager"
                print_info "To remove, use your package manager:"
                echo ""
                echo "  Ubuntu/Debian: sudo apt remove neovim"
                echo "  Fedora:        sudo dnf remove neovim"
                echo "  Arch:          sudo pacman -R neovim"
                echo "  macOS:         brew uninstall neovim"
                echo ""
                
                # Detect OS and offer to remove
                if [ -f /etc/os-release ]; then
                    . /etc/os-release
                    case $ID in
                        ubuntu|debian|pop)
                            read -p "Run 'sudo apt remove neovim' now? (y/N) " -n 1 -r
                            echo ""
                            if [[ $REPLY =~ ^[Yy]$ ]]; then
                                sudo apt remove neovim
                            fi
                            ;;
                        fedora)
                            read -p "Run 'sudo dnf remove neovim' now? (y/N) " -n 1 -r
                            echo ""
                            if [[ $REPLY =~ ^[Yy]$ ]]; then
                                sudo dnf remove neovim
                            fi
                            ;;
                        arch|manjaro)
                            read -p "Run 'sudo pacman -R neovim' now? (y/N) " -n 1 -r
                            echo ""
                            if [[ $REPLY =~ ^[Yy]$ ]]; then
                                sudo pacman -R neovim
                            fi
                            ;;
                    esac
                elif [[ "$OSTYPE" == "darwin"* ]]; then
                    read -p "Run 'brew uninstall neovim' now? (y/N) " -n 1 -r
                    echo ""
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        brew uninstall neovim
                    fi
                fi
            fi
        else
            print_info "Keeping Neovim installed"
        fi
    else
        print_info "Neovim is not installed or not in PATH"
    fi
    
    return 0
}

# Optional: Remove global npm packages
remove_npm_packages() {
    print_step "Checking for global npm packages..."
    
    if command -v npm >/dev/null 2>&1; then
        print_info "The following global npm packages were likely installed:"
        echo "  - neovim (npm package for Neovim)"
        echo "  - yarn (package manager)"
        echo ""
        
        # Check if packages are actually installed
        local neovim_installed=false
        local yarn_installed=false
        
        if npm list -g neovim >/dev/null 2>&1; then
            neovim_installed=true
            print_verbose "neovim package is installed"
        fi
        
        if npm list -g yarn >/dev/null 2>&1; then
            yarn_installed=true
            print_verbose "yarn package is installed"
        fi
        
        if [ "$neovim_installed" = true ] || [ "$yarn_installed" = true ]; then
            read -p "Remove these npm packages? (y/N)" -n 1 -r
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if [ "$neovim_installed" = true ]; then
                    print_info "Removing neovim npm package..."
                    if npm uninstall -g neovim; then
                        print_success "Removed neovim npm package"
                    else
                        print_warning "Failed to remove neovim npm package"
                    fi
                fi
                
                if [ "$yarn_installed" = true ]; then
                    print_info "Removing yarn..."
                    if npm uninstall -g yarn; then
                        print_success "Removed yarn"
                    else
                        print_warning "Failed to remove yarn"
                    fi
                fi
            else
                print_info "Keeping npm packages"
            fi
        else
            print_info "No relevant npm packages found"
        fi
    else
        print_verbose "npm not found"
    fi
    
    return 0
}

# Show what was removed
show_summary() {
    print_step "Uninstall Summary"
    
    print_success "Uninstallation complete!"
    echo ""
    print_info "What was removed:"
    echo "  ✓ Neovim configuration (~/.config/nvim)"
    echo "  ✓ Plugin data (~/.local/share/nvim)"
    echo "  ✓ State data (~/.local/state/nvim)"
    echo "  ✓ Cache (~/.cache/nvim)"
    
    # Find backup directories
    local backup_found=false
    if ls -d "$HOME/.config/nvim.removed."* 2>/dev/null; then
        backup_found=true
    fi
    
    if [ "$backup_found" = true ]; then
        echo ""
        print_info "Your configuration was backed up:"
        ls -lhd "$HOME/.config/nvim.removed."* 2>/dev/null | while read -r line; do
            echo "  $line"
        done
        echo ""
        print_info "To delete backups:"
        print_command "rm -rf ~/.config/nvim.removed.*"
    fi
    
    echo ""
    print_info "What was NOT automatically removed:"
    echo "  - nvm and Node.js (~/.nvm)"
    echo "  - System packages (ripgrep, fd-find, etc.)"
    echo "  - Python packages (pynvim)"
    echo "  - Build dependencies (if installed)"
    echo ""
    
    if command -v nvim >/dev/null 2>&1; then
        print_warning "Neovim is still installed"
        print_info "Location: $(which nvim)"
    else
        print_info "Neovim has been removed"
    fi
    
    echo ""
    print_warning "You may need to restart your terminal for changes to take effect"
    
    # Check if shell config still sources aliases
    if [ -f "$HOME/.bash_aliases" ]; then
        if [ -s "$HOME/.bash_aliases" ]; then
            print_verbose ".bash_aliases still has content"
        else
            print_info "Note: .bash_aliases is now empty (consider removing it)"
        fi
    fi
}

# Main uninstall flow
main() {
    # Parse command line arguments
    parse_args "$@"
    
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        Neovim Configuration Uninstaller v2.1           ║"
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
    print_info "Verbose mode: $VERBOSE"
    
    if [ "$AUTO_YES" = true ]; then
        print_info "Auto-yes mode: enabled (skipping confirmation)"
    else
        echo ""
        read -p "Continue with uninstallation? (y/N) " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Uninstallation cancelled"
            exit 0
        fi
    fi
    
    echo ""
    
    # Run uninstall steps with error handling
    remove_config || print_warning "Config removal had issues"
    remove_data || print_warning "Data removal had issues"
    remove_aliases || print_warning "Alias removal had issues"
    remove_neovim || print_warning "Neovim removal had issues"
    remove_npm_packages || print_warning "npm package removal had issues"
    show_summary
}

# Run main function
main "$@"
