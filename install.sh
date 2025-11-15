#!/usr/bin/env bash

# We handle errors explicitly with return codes
# Don't use set -e as it exits immediately without calling our error handler

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
NVIM_CONFIG_REPO="https://github.com/PreparedBag/nvim-config.git"
REQUIRED_NVIM_VERSION="0.10.0"
VERBOSE=true
AUTO_YES=false

# Track what was installed for rollback
INSTALLED_ITEMS=()
BACKUP_DIR=""

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
                echo "Neovim Configuration Installer"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -y, --yes     Skip confirmation prompts (for piped install)"
                echo "  -q, --quiet   Disable verbose output"
                echo "  -h, --help    Show this help message"
                echo ""
                echo "Example:"
                echo "  curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash -s -- -y"
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

# Read from actual terminal, even when script is piped
read_from_terminal() {
    local prompt="$1"
    local default="$2"
    
    # If auto-yes mode, return yes
    if [ "$AUTO_YES" = true ]; then
        echo "y"
        return 0
    fi
    
    # Try to read from /dev/tty (actual terminal)
    if [ -t 0 ]; then
        # stdin is a terminal, read normally
        read -p "$prompt" -n 1 -r
        echo ""
        echo "$REPLY"
    elif [ -c /dev/tty ]; then
        # stdin is not a terminal (piped), but /dev/tty is available
        read -p "$prompt" -n 1 -r < /dev/tty
        echo ""
        echo "$REPLY"
    else
        # No terminal available, use default
        print_warning "No terminal available for input, using default: $default"
        echo "$default"
    fi
}

# Error handler with rollback
handle_error() {
    local line_num=${1:-"unknown"}
    local error_code=${2:-1}
    
    echo ""
    print_error "Installation failed at line $line_num with exit code $error_code"
    echo ""
    
    local reply=$(read_from_terminal "Do you want to rollback changes? (Y/n) " "Y")
    
    if [[ ! $reply =~ ^[Nn]$ ]]; then
        rollback_installation
    fi
    
    exit $error_code
}

# Note: We don't use trap 'handle_error ${LINENO} $?' ERR
# because we handle errors explicitly with return codes in main()

# Rollback function
rollback_installation() {
    print_step "Rolling back installation..."
    
    local rollback_success=true
    
    # Restore backup if it exists
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        print_info "Restoring backup configuration..."
        print_verbose "Backup location: $BACKUP_DIR"
        print_verbose "Target location: $HOME/.config/nvim"
        
        # Remove the new/broken config if it exists
        if [ -d "$HOME/.config/nvim" ]; then
            print_verbose "Removing failed config installation"
            if ! rm -rf "$HOME/.config/nvim"; then
                print_warning "Could not remove failed config"
                rollback_success=false
            fi
        fi
        
        # Restore the backup
        print_verbose "Restoring backup from: $BACKUP_DIR"
        if mv "$BACKUP_DIR" "$HOME/.config/nvim"; then
            print_success "Restored previous configuration"
        else
            print_error "Failed to restore backup from $BACKUP_DIR"
            print_info "Your backup is still safe at: $BACKUP_DIR"
            print_info "You can manually restore it with:"
            print_command "mv $BACKUP_DIR $HOME/.config/nvim"
            rollback_success=false
        fi
    else
        print_verbose "No backup to restore"
    fi
    
    # Remove installed nvim if we installed it to /opt
    if [[ " ${INSTALLED_ITEMS[*]} " =~ " nvim-opt " ]]; then
        print_info "Removing Neovim from /opt..."
        print_verbose "Removing /opt/nvim-linux-x86_64"
        if sudo rm -rf /opt/nvim-linux-x86_64 2>/dev/null; then
            print_verbose "Removed /opt/nvim-linux-x86_64"
        fi
        print_verbose "Removing /usr/local/bin/nvim symlink"
        if sudo rm -f /usr/local/bin/nvim 2>/dev/null; then
            print_verbose "Removed symlink"
        fi
        print_success "Removed Neovim installation"
    fi
    
    if [[ " ${INSTALLED_ITEMS[*]} " =~ " nvim-source " ]]; then
        print_info "Neovim was built from source"
        print_warning "Source-built Neovim may need manual cleanup"
        print_info "If installed to /usr/local, you may need to remove it manually"
    fi
    
    if [ "$rollback_success" = true ]; then
        print_success "Rollback complete - your system has been restored"
    else
        print_warning "Rollback had some issues - please check the messages above"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user."
        exit 1
    fi
}

# Detect OS
detect_os() {
    print_step "Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
        else
            print_error "Cannot detect Linux distribution"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    print_info "Detected OS: $OS $OS_VERSION"
    print_verbose "OSTYPE: $OSTYPE"
}

# Detect architecture
detect_arch() {
    print_step "Detecting system architecture..."
    
    ARCH=$(uname -m)
    print_verbose "Raw architecture: $ARCH"
    
    case $ARCH in
        x86_64)
            ARCH_TYPE="x86_64"
            ;;
        aarch64|arm64)
            ARCH_TYPE="arm64"
            ;;
        armv7l)
            ARCH_TYPE="armv7"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    print_info "Detected architecture: $ARCH_TYPE"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Compare version numbers
version_ge() {
    printf '%s\n%s' "$2" "$1" | sort -V -C
}

# Download file with validation
download_file() {
    local url=$1
    local output=$2
    local expected_type=$3  # e.g., "gzip", "tar"
    
    print_verbose "Downloading: $url"
    print_verbose "Output file: $output"
    
    # Download with progress and follow redirects
    if ! curl -L --progress-bar --fail --show-error "$url" -o "$output" 2>&1; then
        print_error "Failed to download from: $url"
        return 1
    fi
    
    # Verify the file exists and has content
    if [ ! -f "$output" ]; then
        print_error "Downloaded file not found: $output"
        return 1
    fi
    
    local file_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null)
    print_verbose "Downloaded file size: $file_size bytes"
    
    if [ "$file_size" -lt 1000 ]; then
        print_error "Downloaded file is suspiciously small ($file_size bytes)"
        print_info "File might be an error page. Contents:"
        head -n 20 "$output"
        return 1
    fi
    
    # Check file type if specified
    if [ -n "$expected_type" ]; then
        local file_type=$(file -b "$output" 2>/dev/null || echo "unknown")
        print_verbose "File type: $file_type"
        
        case $expected_type in
            "gzip")
                if ! echo "$file_type" | grep -qi "gzip"; then
                    print_error "Expected gzip file but got: $file_type"
                    return 1
                fi
                ;;
            "tar")
                if ! echo "$file_type" | grep -qi "tar"; then
                    print_error "Expected tar file but got: $file_type"
                    return 1
                fi
                ;;
        esac
    fi
    
    print_verbose "Download validation successful"
    return 0
}

# Backup existing config
backup_config() {
    if [ -d "$HOME/.config/nvim" ]; then
        print_step "Backing up existing Neovim configuration..."
        BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
        print_verbose "Creating backup at: $BACKUP_DIR"
        mv "$HOME/.config/nvim" "$BACKUP_DIR"
        print_success "Backed up to: $BACKUP_DIR"
    fi
}

# Install package based on OS
install_package() {
    local package=$1
    
    print_verbose "Installing package: $package"
    
    case $OS in
        ubuntu|debian|pop)
            sudo apt-get install -y "$package" 2>&1 | grep -v "^Reading" || true
            ;;
        fedora)
            sudo dnf install -y "$package"
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm "$package"
            ;;
        macos)
            brew install "$package"
            ;;
        *)
            print_warning "Please install $package manually for your OS"
            return 1
            ;;
    esac
    
    return 0
}

# Install Neovim
install_neovim() {
    print_step "Installing Neovim..."
    
    # Check if Neovim is already installed with correct version
    if command_exists nvim; then
        current_version=$(nvim --version | head -n1 | grep -oP 'v\K[0-9.]+' || echo "0.0.0")
        print_verbose "Current Neovim version: $current_version"
        
        if version_ge "$current_version" "$REQUIRED_NVIM_VERSION"; then
            print_success "Neovim $current_version is already installed"
            return 0
        else
            print_warning "Neovim $current_version is installed but version $REQUIRED_NVIM_VERSION+ is required"
            print_info "Will upgrade Neovim..."
        fi
    fi
    
    case $OS in
        ubuntu|debian|pop)
            if [[ "$ARCH_TYPE" == "x86_64" ]]; then
                print_info "Installing Neovim from official release (x86_64)..."
                
                # Save current directory
                local original_dir="$PWD"
                print_verbose "Original directory: $original_dir"
                
                # Create temp directory
                local temp_dir=$(mktemp -d)
                print_verbose "Working in temp directory: $temp_dir"
                cd "$temp_dir" || {
                    print_error "Failed to cd to temp directory"
                    return 1
                }
                
                # Get the actual download URL
                print_verbose "Fetching latest release URL..."
                local download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
                
                print_info "Downloading Neovim tarball..."
                if ! download_file "$download_url" "nvim-linux-x86_64.tar.gz" "gzip"; then
                    print_error "Failed to download Neovim"
                    cd "$original_dir" || cd "$HOME"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                print_info "Extracting Neovim..."
                print_command "tar -xzf nvim-linux-x86_64.tar.gz"
                if ! tar -xzf nvim-linux-x86_64.tar.gz 2>&1; then
                    print_error "Failed to extract Neovim tarball"
                    cd "$original_dir" || cd "$HOME"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                print_info "Installing to /opt..."
                print_command "sudo rm -rf /opt/nvim-linux-x86_64"
                sudo rm -rf /opt/nvim-linux-x86_64 2>/dev/null || true
                
                print_command "sudo mv nvim-linux-x86_64 /opt/"
                if ! sudo mv nvim-linux-x86_64 /opt/; then
                    print_error "Failed to move Neovim to /opt"
                    cd "$original_dir" || cd "$HOME"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                print_info "Creating symlink..."
                print_command "sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim"
                if ! sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim; then
                    print_error "Failed to create symlink"
                    cd "$original_dir" || cd "$HOME"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                # Cleanup - return to original directory
                cd "$original_dir" || cd "$HOME"
                rm -rf "$temp_dir"
                
                INSTALLED_ITEMS+=("nvim-opt")
                
            else
                print_info "Building Neovim from source (ARM)..."
                print_warning "This will take several minutes..."
                
                # Save current directory
                local original_dir="$PWD"
                print_verbose "Original directory: $original_dir"
                
                # Install build dependencies
                print_info "Installing build dependencies..."
                sudo apt-get update
                if ! sudo apt-get install -y ninja-build gettext cmake unzip curl build-essential; then
                    print_error "Failed to install build dependencies"
                    return 1
                fi
                
                # Create temp directory
                local temp_dir=$(mktemp -d)
                print_verbose "Working in temp directory: $temp_dir"
                cd "$temp_dir" || {
                    print_error "Failed to cd to temp directory"
                    return 1
                }
                
                # Clone and build
                print_info "Cloning Neovim repository..."
                if ! git clone --depth 1 --branch stable https://github.com/neovim/neovim.git; then
                    print_error "Failed to clone Neovim repository"
                    cd "$original_dir" || cd "$HOME"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                cd neovim || {
                    print_error "Failed to cd to neovim directory"
                    cd "$original_dir" || cd "$HOME"
                    rm -rf "$temp_dir"
                    return 1
                }
                
                print_info "Building Neovim (this takes a while)..."
                if ! make CMAKE_BUILD_TYPE=Release 2>&1 | tail -n 20; then
                    print_error "Failed to build Neovim"
                    cd "$original_dir" || cd "$HOME"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                print_info "Installing Neovim..."
                if ! sudo make install; then
                    print_error "Failed to install Neovim"
                    cd "$original_dir" || cd "$HOME"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                # Cleanup - return to original directory
                cd "$original_dir" || cd "$HOME"
                rm -rf "$temp_dir"
                
                INSTALLED_ITEMS+=("nvim-source")
            fi
            ;;
            
        fedora)
            print_info "Installing Neovim via dnf..."
            if ! sudo dnf install -y neovim python3-neovim; then
                print_error "Failed to install Neovim via dnf"
                return 1
            fi
            ;;
            
        arch|manjaro)
            print_info "Installing Neovim via pacman..."
            if ! sudo pacman -S --noconfirm neovim python-pynvim; then
                print_error "Failed to install Neovim via pacman"
                return 1
            fi
            ;;
            
        macos)
            print_info "Installing Neovim via Homebrew..."
            if ! command_exists brew; then
                print_error "Homebrew is not installed. Please install it from https://brew.sh"
                return 1
            fi
            if ! brew install neovim; then
                print_error "Failed to install Neovim via Homebrew"
                return 1
            fi
            ;;
            
        *)
            print_error "Automatic Neovim installation not supported for $OS"
            print_info "Please install Neovim $REQUIRED_NVIM_VERSION+ manually"
            return 1
            ;;
    esac
    
    # Verify installation
    if command_exists nvim; then
        installed_version=$(nvim --version | head -n1 | grep -oP 'v\K[0-9.]+' || echo "unknown")
        print_success "Neovim $installed_version installed successfully"
        
        # Verify version meets requirements
        if version_ge "$installed_version" "$REQUIRED_NVIM_VERSION"; then
            print_verbose "Version check passed"
        else
            print_error "Installed version $installed_version is still below required $REQUIRED_NVIM_VERSION"
            return 1
        fi
    else
        print_error "Neovim installation failed - nvim command not found"
        return 1
    fi
    
    return 0
}

# Install dependencies
install_dependencies() {
    print_step "Installing dependencies..."
    
    case $OS in
        ubuntu|debian|pop)
            print_info "Updating package list..."
            if ! sudo apt-get update; then
                print_error "Failed to update package list"
                return 1
            fi
            
            print_info "Installing packages..."
            local packages=(
                git curl wget
                ripgrep fd-find
                python3 python3-pip python3-venv
                nodejs npm
                luarocks
                build-essential
            )
            
            for pkg in "${packages[@]}"; do
                print_verbose "Installing: $pkg"
                if ! sudo apt-get install -y "$pkg" 2>&1 | grep -v "^Reading" || true; then
                    print_warning "Failed to install $pkg (may not be critical)"
                fi
            done
            
            # Install additional tools via npm
            print_info "Installing npm packages..."
            if ! sudo npm install -g neovim yarn 2>&1 | tail -n 10; then
                print_warning "Failed to install npm packages (will retry with nvm)"
            fi
            
            # Install Python neovim package
            print_info "Installing Python neovim package..."
            if ! python3 -m pip install --user pynvim 2>&1 | tail -n 5; then
                print_warning "Failed to install pynvim"
            fi
            ;;
            
        fedora)
            print_info "Installing packages..."
            if ! sudo dnf install -y \
                git curl wget \
                ripgrep fd-find \
                python3 python3-pip \
                nodejs npm \
                luarocks \
                gcc-c++ make; then
                print_error "Failed to install dependencies"
                return 1
            fi
            
            sudo npm install -g neovim yarn
            python3 -m pip install --user pynvim
            ;;
            
        arch|manjaro)
            print_info "Installing packages..."
            if ! sudo pacman -S --noconfirm \
                git curl wget \
                ripgrep fd \
                python python-pip \
                nodejs npm \
                luarocks \
                base-devel; then
                print_error "Failed to install dependencies"
                return 1
            fi
            
            sudo npm install -g neovim yarn
            python -m pip install --user pynvim
            ;;
            
        macos)
            print_info "Installing packages via Homebrew..."
            if ! brew install \
                git curl wget \
                ripgrep fd \
                python3 \
                node \
                luarocks; then
                print_error "Failed to install dependencies"
                return 1
            fi
            
            npm install -g neovim yarn
            pip3 install --user pynvim
            ;;
            
        *)
            print_warning "Please install dependencies manually for your OS"
            print_info "Required: git, curl, ripgrep, fd, nodejs, npm, python3, luarocks"
            ;;
    esac
    
    print_success "Dependencies installed"
    return 0
}

# Install Node.js via nvm
install_node_nvm() {
    print_step "Setting up Node.js with nvm..."
    
    if [ -d "$HOME/.nvm" ]; then
        print_info "nvm is already installed"
    else
        print_info "Installing nvm..."
        local nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
        
        if ! curl -o- "$nvm_install_url" | bash; then
            print_warning "nvm installation failed (not critical)"
            return 0
        fi
    fi
    
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command_exists nvm; then
        print_info "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        
        # Install global packages
        print_info "Installing global npm packages..."
        npm install -g neovim yarn
        
        node_version=$(node --version 2>/dev/null || echo "unknown")
        print_success "Node.js $node_version installed"
    else
        print_warning "nvm installation may require terminal restart"
    fi
    
    return 0
}

# Setup shell configuration
setup_shell_config() {
    print_step "Configuring shell..."
    
    # Detect shell
    SHELL_RC="$HOME/.bashrc"
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi
    print_verbose "Using shell config: $SHELL_RC"
    
    # Create .bash_aliases if it doesn't exist
    if [ ! -f "$HOME/.bash_aliases" ]; then
        touch "$HOME/.bash_aliases"
        print_verbose "Created .bash_aliases"
    fi
    
    # Add nvim alias
    if ! grep -q "alias vim=" "$HOME/.bash_aliases" 2>/dev/null; then
        echo "alias vim='nvim'" >> "$HOME/.bash_aliases"
        print_info "Added vim alias to .bash_aliases"
    else
        print_verbose "vim alias already exists"
    fi
    
    # Source aliases in shell rc if not already done
    if ! grep -q ".bash_aliases" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Source aliases" >> "$SHELL_RC"
        echo "[ -f ~/.bash_aliases ] && . ~/.bash_aliases" >> "$SHELL_RC"
        print_verbose "Added alias sourcing to $SHELL_RC"
    fi
    
    print_success "Shell configuration updated"
    return 0
}

# Clone Neovim configuration
clone_config() {
    print_step "Cloning Neovim configuration..."
    
    if [ -d "$HOME/.config/nvim" ]; then
        print_warning "Config directory exists (this shouldn't happen)"
        return 1
    fi
    
    print_verbose "Cloning from: $NVIM_CONFIG_REPO"
    print_command "git clone $NVIM_CONFIG_REPO ~/.config/nvim"
    
    if ! git clone "$NVIM_CONFIG_REPO" "$HOME/.config/nvim" 2>&1 | tail -n 10; then
        print_error "Failed to clone configuration repository"
        return 1
    fi
    
    print_success "Configuration cloned to ~/.config/nvim"
    return 0
}

# Install language servers
install_language_servers() {
    print_step "Installing common language servers..."
    
    # Go (optional, only if golang is needed)
    if command_exists go; then
        print_info "Installing gopls..."
        go install golang.org/x/tools/gopls@latest 2>/dev/null || print_warning "gopls install failed"
    else
        print_verbose "Go not installed, skipping gopls"
    fi
    
    print_info "Other language servers will be installed by Mason on first launch"
    return 0
}

# Final setup and instructions
final_setup() {
    print_step "Finalizing installation..."
    
    # Create necessary directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.local/state"
    
    print_verbose "Created required directories"
    
    print_success "Installation complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.bashrc"
    echo "  2. Launch Neovim with: nvim"
    echo "  3. Wait for plugins to install automatically (first launch takes a few minutes)"
    echo "  4. After plugins install, restart Neovim"
    echo "  5. Run :checkhealth to verify everything is working"
    echo ""
    print_info "Quick start:"
    echo "  - Press SPACE to see all keybindings (which-key)"
    echo "  - Open file explorer: SPACE + fe"
    echo "  - Find files: SPACE + ff"
    echo "  - Toggle terminal: SPACE + ,"
    echo ""
    print_info "Configuration location: ~/.config/nvim"
    print_info "Backup location: $BACKUP_DIR"
    print_info "For help, see: ~/.config/nvim/README.md"
}

# Main installation flow
main() {
    # Parse command line arguments
    parse_args "$@"
    
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        Neovim Configuration Installer v2.1             ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    check_root
    detect_os
    detect_arch
    
    echo ""
    print_warning "This script will:"
    echo "  - Install Neovim $REQUIRED_NVIM_VERSION+"
    echo "  - Install required dependencies"
    echo "  - Install Node.js via nvm"
    echo "  - Clone Neovim configuration to ~/.config/nvim"
    echo "  - Backup existing config if present"
    echo ""
    print_info "Verbose mode: $VERBOSE"
    print_info "Rollback available on errors"
    
    if [ "$AUTO_YES" = true ]; then
        print_info "Auto-yes mode: enabled (skipping confirmation)"
    else
        echo ""
        local reply=$(read_from_terminal "Continue with installation? (y/N) " "N")
        
        if [[ ! $reply =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi
    
    echo ""
    
    # Run installation steps with explicit error checking
    if ! backup_config; then
        print_error "Backup failed"
        exit 1
    fi
    
    if ! install_neovim; then
        print_error "Neovim installation failed"
        handle_error ${LINENO} 1
    fi
    
    if ! install_dependencies; then
        print_error "Dependencies installation failed"
        handle_error ${LINENO} 1
    fi
    
    if ! install_node_nvm; then
        print_warning "Node/nvm installation had issues (not critical)"
    fi
    
    if ! setup_shell_config; then
        print_warning "Shell config had issues (not critical)"
    fi
    
    if ! clone_config; then
        print_error "Config clone failed"
        handle_error ${LINENO} 1
    fi
    
    if ! install_language_servers; then
        print_warning "Language server installation had issues (not critical)"
    fi
    
    final_setup
}

# Run main function
main "$@"
