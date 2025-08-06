#!/usr/bin/env bash
#
# install.sh - One-liner installation script for dotfiles
# This script sets up the environment and installs the dotfiles management system
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sotayamashita/dotfiles/main/install.sh | bash

set -euo pipefail

# --- Constants ---
readonly DOTFILES_REPO="https://github.com/sotayamashita/dotfiles.git"
readonly DOTFILES_SSH="git@github.com:sotayamashita/dotfiles.git"
readonly DOTFILES_DIR="${HOME}/Projects/dotfiles"
readonly DOT_BIN="${HOME}/.local/bin/dot"

# --- Colors ---
if [ -t 1 ]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly CYAN=''
    readonly BOLD=''
    readonly NC=''
fi

# --- Logging ---
info() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step() { echo -e "\n${CYAN}━━━${NC} ${BOLD}$1${NC} ${CYAN}━━━${NC}"; }

# --- Functions ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# Ensure Xcode Command Line Tools (macOS)
ensure_xcode_clt() {
    if ! is_macos; then
        return 0
    fi
    
    if ! xcode-select -p >/dev/null 2>&1; then
        step "Installing Xcode Command Line Tools"
        info "Please follow the on-screen prompts to install Xcode CLT..."
        xcode-select --install
        
        # Wait for installation
        while ! xcode-select -p >/dev/null 2>&1; do
            sleep 10
        done
        
        info "Xcode Command Line Tools installed successfully"
    fi
}

# Ensure Homebrew (macOS)
ensure_homebrew() {
    if ! is_macos; then
        return 0
    fi
    
    local brew_prefix
    if [[ "$(uname -m)" == "arm64" ]]; then
        brew_prefix="/opt/homebrew"
    else
        brew_prefix="/usr/local"
    fi
    
    if ! command_exists "${brew_prefix}/bin/brew"; then
        step "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add to PATH for this session
        eval "$(${brew_prefix}/bin/brew shellenv)"
        info "Homebrew installed successfully"
    else
        # Ensure brew is in PATH
        if ! command_exists brew; then
            eval "$(${brew_prefix}/bin/brew shellenv)"
        fi
    fi
}

# Check SSH access to GitHub
check_ssh_access() {
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        return 0
    else
        return 1
    fi
}

# Clone dotfiles repository
clone_dotfiles() {
    step "Cloning Dotfiles Repository"
    
    # Create parent directory
    mkdir -p "$(dirname "${DOTFILES_DIR}")"
    
    # Check if already exists
    if [[ -d "${DOTFILES_DIR}" ]]; then
        if [[ -d "${DOTFILES_DIR}/.git" ]]; then
            info "Dotfiles repository already exists at ${DOTFILES_DIR}"
            
            # Update to latest
            info "Updating repository..."
            git -C "${DOTFILES_DIR}" pull --ff-only || warn "Could not update repository"
            return 0
        else
            error "Directory ${DOTFILES_DIR} exists but is not a git repository"
        fi
    fi
    
    # Try SSH first, fallback to HTTPS
    if check_ssh_access; then
        info "Cloning via SSH..."
        git clone "${DOTFILES_SSH}" "${DOTFILES_DIR}"
    else
        info "SSH not available, cloning via HTTPS..."
        git clone "${DOTFILES_REPO}" "${DOTFILES_DIR}"
    fi
    
    info "Repository cloned successfully"
}

# Install dot command
install_dot_command() {
    step "Installing 'dot' Command"
    
    # Create .local/bin directory
    mkdir -p "${HOME}/.local/bin"
    
    # Create symlink to dot command
    if [[ -f "${DOTFILES_DIR}/dot" ]]; then
        ln -sf "${DOTFILES_DIR}/dot" "${DOT_BIN}"
        info "Installed 'dot' command to ${DOT_BIN}"
        
        # Check if .local/bin is in PATH
        if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
            warn "${HOME}/.local/bin is not in your PATH"
            info "Add this line to your shell configuration:"
            echo "  export PATH=\"\${HOME}/.local/bin:\${PATH}\""
        fi
    else
        error "dot command not found in repository"
    fi
}

# Setup 1Password SSH Agent (macOS)
setup_1password_ssh() {
    if ! is_macos; then
        return 0
    fi
    
    if ! command_exists op; then
        step "Installing 1Password CLI"
        if command_exists brew; then
            brew install --cask 1password/tap/1password-cli || warn "Failed to install 1Password CLI"
        fi
    fi
    
    # Configure SSH for 1Password
    local ssh_config="${HOME}/.ssh/config"
    local agent_line='IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'
    
    if [[ -f "${ssh_config}" ]]; then
        if ! grep -qF "${agent_line}" "${ssh_config}"; then
            step "Configuring SSH for 1Password"
            echo "" >> "${ssh_config}"
            echo "Host *" >> "${ssh_config}"
            echo "  ${agent_line}" >> "${ssh_config}"
            info "SSH configured for 1Password Agent"
        fi
    else
        mkdir -p "${HOME}/.ssh"
        chmod 700 "${HOME}/.ssh"
        cat > "${ssh_config}" <<EOF
Host *
  ${agent_line}
EOF
        chmod 600 "${ssh_config}"
        info "SSH configuration created for 1Password"
    fi
}

# Main installation flow
main() {
    echo
    echo -e "${BOLD}🚀 Dotfiles Installation${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    # Platform-specific setup
    if is_macos; then
        ensure_xcode_clt
        ensure_homebrew
        setup_1password_ssh
    fi
    
    # Clone repository
    clone_dotfiles
    
    # Install dot command
    install_dot_command
    
    # Final message
    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}✨ Installation Complete!${NC}"
    echo
    echo "Next steps:"
    echo "  1. Ensure ${HOME}/.local/bin is in your PATH"
    echo "  2. Run: dot install"
    echo "  3. Restart your terminal or run: source ~/.config/fish/config.fish"
    echo
    echo "For help, run: dot help"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Run main
main "$@"