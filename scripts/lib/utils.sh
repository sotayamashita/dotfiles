#!/usr/bin/env bash
# Common utility functions for dotfiles setup (Improved Version)

set -euo pipefail

# --- Constants ---
# DOTFILES_FINAL_DIR is assumed to be the root of the repository where this script resides.
# Determine it reliably based on this script's location.
UTILS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly DOTFILES_FINAL_DIR="$( dirname "$UTILS_SCRIPT_DIR" | xargs dirname )" # Assumes scripts/lib/utils.sh structure
readonly DOTFILES_SCRIPTS_DIR="${DOTFILES_FINAL_DIR}/scripts"
# DOTFILES_HOME_DIR might still be useful for target paths (like symlinks)
: "${DOTFILES_HOME_DIR:="$HOME"}"
# DOTFILES_STATE_FILE is likely no longer needed

# --- Colors ---
# Check if stderr is a terminal before using colors
if [ -t 2 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

# --- Logging ---
# Use printf for better portability and format control, output to stderr
_log_prefix() { printf "%b[%s]%b" "${1}" "${2}" "${NC}"; } # $1=color, $2=level
info()  { printf "%s %s\n" "$(_log_prefix "$GREEN" "INFO")" "$1" >&2; }
warn()  { printf "%s %s\n" "$(_log_prefix "$YELLOW" "WARN")" "$1" >&2; }
error() { printf "%s %s\n" "$(_log_prefix "$RED" "ERROR")" "$1" >&2; exit 1; } # Exit on error
debug() { printf "%s %s\n" "$(_log_prefix "$BLUE" "DEBUG")" "$1" >&2; }
step()  { printf "\n\n\n\n%s --- %s ---\n" "$(_log_prefix "$CYAN" "STEP")" "$1" >&2; } # Added Step function

# --- Checks ---
command_exists() { command -v "$1" >/dev/null 2>&1; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

# --- macOS Specific ---
get_macos_version() {
    if is_macos; then sw_vers -productVersion || echo "Unknown macOS Version"; else echo "Not macOS"; fi
}
get_mac_architecture() {
    if is_macos; then uname -m; else echo "Not macOS"; fi # e.g., arm64 or x86_64
}

# --- Load Brew Path ---
if is_macos; then
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# --- Filesystem Operations ---
ensure_dir_exists() {
    local dir="$1"
    # Create only if it doesn't exist
    if [ ! -d "$dir" ]; then
        info "Creating directory: $dir"
        # Use -p to create parent dirs, check return status
        if mkdir -p "$dir"; then
            return 0 # Successfully created (or already existed due to race condition)
        else
            warn "Failed to create directory: $dir"
            return 1 # Indicate failure
        fi
    fi
    return 0 # Directory already exists
}

_backup_item() {
    local item="$1"
    # Check if item exists (file, dir, or symlink) before attempting backup
    if [ ! -e "$item" ] && [ ! -L "$item" ]; then
        # Doesn't exist, nothing to back up
        return 1 # Indicate "not backed up"
    fi

    local backup_suffix=".backup.$(date +%Y%m%d_%H%M%S)"
    local backup_path="${item}${backup_suffix}"
    local item_type="item"
    if [ -f "$item" ]; then item_type="file";
    elif [ -d "$item" ]; then item_type="directory";
    elif [ -L "$item" ]; then item_type="symlink"; fi

    info "Backing up existing ${item_type}: $item -> $backup_path"
    # Use -f to overwrite potentially existing backup? Or error out? Default mv fails.
    # Add error checking for mv
    if mv "$item" "$backup_path"; then
        return 0 # Success
    else
        warn "Failed to back up ${item_type}: $item"
        return 1 # Failure
    fi
}
backup_file() { _backup_item "$1"; }
backup_dir() { _backup_item "$1"; }

# --- Script Execution Helpers ---

# Finds a script within the dotfiles structure (modules or installers)
# $1: script name (e.g., "symlinks.sh" or "brew.sh")
# $2: type ("modules/core", "modules/macos", "installers")
_find_script_path() {
    local script_name="$1"
    local script_type_dir="$2" # e.g., "modules/core" or "installers"
    local script_path="${DOTFILES_SCRIPTS_DIR}/${script_type_dir}/${script_name}"

    if [ -f "$script_path" ]; then
        echo "$script_path"
        return 0
    else
        warn "Script not found: ${script_type_dir}/${script_name} (Looked in: $script_path)"
        return 1
    fi
}

# Makes a script executable if needed
_ensure_executable() {
    local script_path="$1"
    if [ ! -x "$script_path" ]; then
        debug "Making script executable: $script_path"
        if ! chmod +x "$script_path"; then
            warn "Failed to make script executable: $script_path"
            return 1
        fi
    fi
    return 0
}

# Finds and executes scripts in a specific module
# $1: script name (e.g., "symlinks.sh")
# $2: module name (e.g., "core", "macos")
run_script() {
    local script_name="$1"
    local module_name="$2"
    local script_path
    script_path=$(_find_script_path "$script_name" "modules/$module_name") || return 1
    _ensure_executable "$script_path" || return 1

    info "--> Executing script: $script_path"
    # Execute in a subshell (bash)
    if bash "$script_path"; then
        info "<-- Script finished: modules/$module_name/$script_name"
        return 0
    else
        local exit_code=$?
        warn "<-- Script failed (Exit code: $exit_code): modules/$module_name/$script_name"
        return "$exit_code" # Return the script's exit code
    fi
}

# Finds and sources scripts in a specific module
# $1: script name
# $2: module name
source_script() {
    local script_name="$1"
    local module_name="$2"
    local script_path
    script_path=$(_find_script_path "$script_name" "modules/$module_name") || return 1
    _ensure_executable "$script_path" || return 1

    info "Sourcing script: $script_path"
    # Source in the current shell
    # shellcheck source=/dev/null # Dynamic source path
    if source "$script_path"; then
        return 0
    else
        local exit_code=$?
        warn "Script sourcing failed (Exit code: $exit_code): modules/$module_name/$script_name"
        return "$exit_code"
    fi
}

# Run installer script
# $1: installer script name (e.g., "volta.sh")
run_installer() {
    local installer_name="$1"
    local installer_path
    installer_path=$(_find_script_path "$installer_name" "installers") || return 1
    _ensure_executable "$installer_path" || return 1

    info "--> Running installer: $installer_name"
    if bash "$installer_path"; then
        info "<-- Installer finished: $installer_name"
        return 0
    else
        local exit_code=$?
        warn "<-- Installer failed (Exit code: $exit_code): $installer_name"
        return "$exit_code"
    fi
}
