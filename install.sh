#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
NVIM_CONFIG_REPO="https://github.com/PreparedBag/nvim-config.git"
REQUIRED_NVIM_VERSION="0.10.0"

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
}

# Detect architecture
detect_arch() {
    print_step "Detecting system architecture..."
    
    ARCH=$(uname -m)
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

# Backup existing config
backup_config() {
    if [ -d "$HOME/.config/nvim" ]; then
        print_step "Backing up existing Neovim configuration..."
        backup_dir="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.config/nvim" "$backup_dir"
        print_success "Backed up to: $backup_dir"
    fi
}

# Install package based on OS
install_package() {
    local package=$1
    
    case $OS in
        ubuntu|debian|pop)
            sudo apt-get install -y "$package"
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
            ;;
    esac
}

# Install Neovim
install_neovim() {
    print_step "Installing Neovim..."
    
    # Check if Neovim is already installed with correct version
    if command_exists nvim; then
        current_version=$(nvim --version | head -n1 | grep -oP 'v\K[0-9.]+')
        if version_ge "$current_version" "$REQUIRED_NVIM_VERSION"; then
            print_success "Neovim $current_version is already installed"
            return 0
        else
            print_warning "Neovim $current_version is installed but version $REQUIRED_NVIM_VERSION+ is required"
        fi
    fi
    
    case $OS in
        ubuntu|debian|pop)
            if [[ "$ARCH_TYPE" == "x86_64" ]]; then
                print_info "Installing Neovim from official release (x86_64)..."
                cd /tmp
                curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
                sudo rm -rf /opt/nvim
                sudo tar -C /opt -xzf nvim-linux64.tar.gz
                sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
                rm nvim-linux64.tar.gz
            else
                print_info "Building Neovim from source (ARM)..."
                sudo apt-get update
                sudo apt-get install -y ninja-build gettext cmake unzip curl build-essential
                cd /tmp
                if [ -d "neovim" ]; then
                    rm -rf neovim
                fi
                git clone https://github.com/neovim/neovim
                cd neovim
                git checkout stable
                make CMAKE_BUILD_TYPE=Release
                sudo make install
                cd /tmp
                rm -rf neovim
            fi
            ;;
        fedora)
            print_info "Installing Neovim via dnf..."
            sudo dnf install -y neovim python3-neovim
            ;;
        arch|manjaro)
            print_info "Installing Neovim via pacman..."
            sudo pacman -S --noconfirm neovim python-pynvim
            ;;
        macos)
            print_info "Installing Neovim via Homebrew..."
            if ! command_exists brew; then
                print_error "Homebrew is not installed. Please install it from https://brew.sh"
                exit 1
            fi
            brew install neovim
            ;;
        *)
            print_error "Automatic Neovim installation not supported for $OS"
            print_info "Please install Neovim $REQUIRED_NVIM_VERSION+ manually"
            exit 1
            ;;
    esac
    
    # Verify installation
    if command_exists nvim; then
        installed_version=$(nvim --version | head -n1 | grep -oP 'v\K[0-9.]+')
        print_success "Neovim $installed_version installed successfully"
    else
        print_error "Neovim installation failed"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    print_step "Installing dependencies..."
    
    case $OS in
        ubuntu|debian|pop)
            print_info "Updating package list..."
            sudo apt-get update
            
            print_info "Installing packages..."
            sudo apt-get install -y \
                git curl wget \
                ripgrep fd-find \
                python3 python3-pip python3-venv \
                nodejs npm \
                luarocks \
                build-essential
            
            # Install additional tools via npm
            sudo npm install -g neovim yarn
            
            # Install Python neovim package
            python3 -m pip install --user pynvim
            ;;
        fedora)
            print_info "Installing packages..."
            sudo dnf install -y \
                git curl wget \
                ripgrep fd-find \
                python3 python3-pip \
                nodejs npm \
                luarocks \
                gcc-c++ make
            
            sudo npm install -g neovim yarn
            python3 -m pip install --user pynvim
            ;;
        arch|manjaro)
            print_info "Installing packages..."
            sudo pacman -S --noconfirm \
                git curl wget \
                ripgrep fd \
                python python-pip \
                nodejs npm \
                luarocks \
                base-devel
            
            sudo npm install -g neovim yarn
            python -m pip install --user pynvim
            ;;
        macos)
            print_info "Installing packages via Homebrew..."
            brew install \
                git curl wget \
                ripgrep fd \
                python3 \
                node \
                luarocks
            
            npm install -g neovim yarn
            pip3 install --user pynvim
            ;;
        *)
            print_warning "Please install dependencies manually for your OS"
            print_info "Required: git, curl, ripgrep, fd, nodejs, npm, python3, luarocks"
            ;;
    esac
    
    print_success "Dependencies installed"
}

# Install Node.js via nvm
install_node_nvm() {
    print_step "Setting up Node.js with nvm..."
    
    if [ -d "$HOME/.nvm" ]; then
        print_info "nvm is already installed"
    else
        print_info "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command_exists nvm; then
        print_info "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        
        # Install global packages
        npm install -g neovim yarn
        
        node_version=$(node --version)
        print_success "Node.js $node_version installed"
    else
        print_warning "nvm installation may require terminal restart"
    fi
}

# Setup shell configuration
setup_shell_config() {
    print_step "Configuring shell..."
    
    # Detect shell
    SHELL_RC="$HOME/.bashrc"
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi
    
    # Create .bash_aliases if it doesn't exist
    if [ ! -f "$HOME/.bash_aliases" ]; then
        touch "$HOME/.bash_aliases"
    fi
    
    # Add nvim alias
    if [[ "$ARCH_TYPE" == "x86_64" ]] && [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # For x86_64 Ubuntu/Debian using /opt install
        if ! grep -q "alias vim=" "$HOME/.bash_aliases" 2>/dev/null; then
            echo "alias vim='nvim'" >> "$HOME/.bash_aliases"
            print_info "Added vim alias to .bash_aliases"
        fi
    else
        # For other systems
        if ! grep -q "alias vim=" "$HOME/.bash_aliases" 2>/dev/null; then
            echo "alias vim='nvim'" >> "$HOME/.bash_aliases"
            print_info "Added vim alias to .bash_aliases"
        fi
    fi
    
    # Source aliases in shell rc if not already done
    if ! grep -q ".bash_aliases" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Source aliases" >> "$SHELL_RC"
        echo "[ -f ~/.bash_aliases ] && . ~/.bash_aliases" >> "$SHELL_RC"
    fi
    
    print_success "Shell configuration updated"
}

# Clone Neovim configuration
clone_config() {
    print_step "Cloning Neovim configuration..."
    
    if [ -d "$HOME/.config/nvim" ]; then
        print_warning "Config directory exists, this should have been backed up"
    fi
    
    git clone "$NVIM_CONFIG_REPO" "$HOME/.config/nvim"
    print_success "Configuration cloned to ~/.config/nvim"
}

# Install language servers
install_language_servers() {
    print_step "Installing common language servers..."
    
    # Go (optional, only if golang is needed)
    if command_exists go; then
        print_info "Installing gopls..."
        go install golang.org/x/tools/gopls@latest 2>/dev/null || print_warning "gopls install failed"
    fi
    
    print_info "Other language servers will be installed by Mason on first launch"
}

# Final setup and instructions
final_setup() {
    print_step "Finalizing installation..."
    
    # Create necessary directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.local/state"
    
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
    print_info "For help, see: ~/.config/nvim/README.md"
}

# Main installation flow
main() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        Neovim Configuration Installer                  ║"
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
    read -p "Continue with installation? (y/N) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    
    # Run installation steps
    backup_config
    install_neovim
    install_dependencies
    install_node_nvm
    setup_shell_config
    clone_config
    install_language_servers
    final_setup
}

# Run main function
main "$@"
