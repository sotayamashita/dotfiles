#!/usr/bin/env bash
# Common utility functions for dotfiles setup

set -euo pipefail

# Constants (if not already defined)
: "${DOTFILES_HOME_DIR:="$HOME"}"
: "${DOTFILES_FINAL_DIR:="$HOME/Projects/dotfiles"}"
: "${DOTFILES_STATE_FILE:="$HOME/.dotfiles_setup_state"}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if we're running on macOS
is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# Get macOS version
get_macos_version() {
    if is_macos; then
        sw_vers -productVersion
    else
        echo "Not macOS"
    fi
}

# Check if directory exists, create if not
ensure_dir_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        info "Creating directory: $dir"
        mkdir -p "$dir"
        return 0
    fi
    return 1
}

# Backup file if it exists
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backing up file: $file -> $backup"
        mv "$file" "$backup"
        return 0
    fi
    return 1
}

# Backup directory if it exists
backup_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        local backup="${dir}.backup.$(date +%Y%m%d_%H%M%S)"
        info "Backing up directory: $dir -> $backup"
        mv "$dir" "$backup"
        return 0
    fi
    return 1
}

# Find and execute scripts in a specific module
run_script() {
    local script_name="$1"
    local module_name="$2"
    local script_path=""
    
    # Check in dotfiles final directory
    if [ -f "$DOTFILES_FINAL_DIR/scripts/modules/$module_name/$script_name" ]; then
        script_path="$DOTFILES_FINAL_DIR/scripts/modules/$module_name/$script_name"
    # Check in home directory
    elif [ -f "$DOTFILES_HOME_DIR/scripts/modules/$module_name/$script_name" ]; then
        script_path="$DOTFILES_HOME_DIR/scripts/modules/$module_name/$script_name"
    else
        warn "Script not found: $module_name/$script_name"
        return 1
    fi
    
    # Check if script is executable
    if [ ! -x "$script_path" ]; then
        info "Making script executable: $script_path"
        chmod +x "$script_path"
    fi
    
    info "Executing script: $script_path"
    bash "$script_path"
    return 0
}

# Find and source scripts in a specific module
source_script() {
    local script_name="$1"
    local module_name="$2"
    local script_path=""
    
    # Check in dotfiles final directory
    if [ -f "$DOTFILES_FINAL_DIR/scripts/modules/$module_name/$script_name" ]; then
        script_path="$DOTFILES_FINAL_DIR/scripts/modules/$module_name/$script_name"
    # Check in home directory
    elif [ -f "$DOTFILES_HOME_DIR/scripts/modules/$module_name/$script_name" ]; then
        script_path="$DOTFILES_HOME_DIR/scripts/modules/$module_name/$script_name"
    else
        warn "Script not found: $module_name/$script_name"
        return 1
    fi
    
    # Check if script is executable
    if [ ! -x "$script_path" ]; then
        info "Making script executable: $script_path"
        chmod +x "$script_path"
    fi
    
    info "Sourcing script: $script_path"
    source "$script_path"
    return 0
}

# Run installer script
run_installer() {
    local installer_name="$1"
    local installer_path=""
    
    # Check in dotfiles final directory
    if [ -f "$DOTFILES_FINAL_DIR/scripts/installers/$installer_name" ]; then
        installer_path="$DOTFILES_FINAL_DIR/scripts/installers/$installer_name"
    # Check in home directory
    elif [ -f "$DOTFILES_HOME_DIR/scripts/installers/$installer_name" ]; then
        installer_path="$DOTFILES_HOME_DIR/scripts/installers/$installer_name"
    else
        warn "Installer not found: $installer_name"
        return 1
    fi
    
    # Check if script is executable
    if [ ! -x "$installer_path" ]; then
        info "Making installer executable: $installer_path"
        chmod +x "$installer_path"
    fi
    
    info "Running installer: $installer_name"
    bash "$installer_path"
    return 0
} 