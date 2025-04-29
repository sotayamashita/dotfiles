#!/usr/bin/env bash
# init_env.sh - Prepares the minimal environment for cloning the dotfiles repository via SSH.
# Ensures prerequisites (Xcode CLT, Homebrew, 1Password CLI) are met and SSH is configured.

set -euo pipefail

# --- Configuration ---
readonly DOTFILES_SSH_URL="git@github.com:sotayamashita/dotfiles.git" # Your SSH repo URL
readonly DOTFILES_FINAL_DIR="$HOME/Projects/dotfiles" # Your desired local repo path
readonly REQUIRED_COMMANDS=("curl" "git" "sudo")
readonly REQUIRED_MACOS_APPS=("Xcode Command Line Tools" "Homebrew" "1Password CLI")

# --- Minimal Logging & Helpers ---
_log_prefix() {
    local color_start=""
    local color_end=""
    if [ -t 1 ]; then # Check if stdout is a terminal
        case "$1" in
            INFO) color_start='\033[0;32m'; color_end='\033[0m';; # Green
            WARN) color_start='\033[0;33m'; color_end='\033[0m';; # Yellow
            ERROR) color_start='\033[0;31m'; color_end='\033[0m';; # Red
            STEP) color_start='\033[0;34m'; color_end='\033[0m';; # Blue
        esac
    fi
    echo -e "${color_start}[$1]${color_end}" >&2
}
info() { echo "$(_log_prefix INFO) $1" >&2; }
warn() { echo "$(_log_prefix WARN) $1" >&2; }
error() { echo "$(_log_prefix ERROR) $1" >&2; exit 1; }
step() { echo -e "\n$(_log_prefix STEP) --- $1 ---" >&2; }
command_exists() { command -v "$1" >/dev/null 2>&1; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

main() {
    echo "===== Initializing Environment for Dotfiles Setup ====="

    # Check for essential commands
    step "Checking essential commands"
    local missingCmds=0
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            error "Required command '$cmd' is not installed. Please install it manually and retry."
            missingCmds=1
        fi
    done
    [ "$missingCmds" -eq 0 ] || exit 1
    info "✅ Essential commands found."

    # Check for Xcode CLT
    step "Checking Xcode Command Line Tools"
    if ! is_macos; then
        info "Not macOS, skipping Xcode Command Line Tools check."
        return 0
    fi

    if ! xcode-select -p > /dev/null 2>&1; then
        info "Xcode Command Line Tools not found. Attempting installation..."
        info "Please follow the on-screen prompts to install."
        xcode-select --install

        # Simple wait loop - user interaction is required anyway
        info "Waiting for you to complete Xcode CLT installation..."
        local count=0
        local max_wait=30 # Wait up to 5 minutes (30 * 10 seconds)
        until xcode-select -p &>/dev/null || [ "$count" -ge "$max_wait" ]; do
            printf "." >&2
            sleep 10
            count=$((count + 1))
        done
        echo >&2 # Newline after dots

        if ! xcode-select -p &>/dev/null; then
            error "Xcode Command Line Tools installation timed out or was cancelled. Please install manually and retry."
        else
            info "Xcode Command Line Tools installation detected."
            # Try accepting license automatically, warn if it fails
            info "Attempting to accept Xcode license..."
            if ! sudo xcodebuild -license accept >/dev/null 2>&1; then
                warn "Could not automatically accept Xcode license. You might need to run 'sudo xcodebuild -license' manually."
            else
                info "Xcode license accepted."
            fi
        fi
    else
        info "✅ Xcode Command Line Tools already installed."
    fi

    # Check for Homebrew
    step "Checking Homebrew"
    if ! is_macos; then
        info "Not macOS, skipping Homebrew check."
        return 0
    fi

    if ! command_exists brew; then
        info "Homebrew not found. Attempting installation..."
        # Non-interactive install might be riskier, prefer standard interactive method
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            info "Homebrew installation script finished."
            # Add Homebrew to PATH for the current script execution session
            local brew_prefix
            if [[ "$(uname -m)" == "arm64" ]]; then
                brew_prefix="/opt/homebrew"
            else
                brew_prefix="/usr/local"
            fi
            if [ -x "${brew_prefix}/bin/brew" ]; then
            eval "$(${brew_prefix}/bin/brew shellenv)"
                info "Homebrew environment configured for this session."
                # Verify command again after adding to PATH
                if ! command_exists brew; then
                    error "Homebrew installed, but 'brew' command is still not available in PATH."
                fi
            else
                warn "Could not find brew executable at expected location: ${brew_prefix}/bin/brew"
                error "Homebrew installation seems incomplete."
            fi
        else
            error "Homebrew installation script failed. Please install manually and retry."
        fi
    else
        info "✅ Homebrew already installed."
        # Ensure brew environment is set for current session if script is re-run
        local brew_prefix
        if [[ "$(uname -m)" == "arm64" ]]; then
            brew_prefix="/opt/homebrew"
        else
            brew_prefix="/usr/local"
        fi
         if [ -x "${brew_prefix}/bin/brew" ] && [[ ":$PATH:" != *":${brew_prefix}/bin:"* ]]; then
            eval "$(${brew_prefix}/bin/brew shellenv)"
            info "Homebrew environment configured for this session (re-run)."
        fi
    fi

    step "Checking 1Password CLI"
    if ! is_macos; then
        info "Not macOS, skipping 1Password CLI check."
        return 0
    fi
    if ! command_exists brew; then
        error "Homebrew is required to install 1Password CLI, but 'brew' command is not available."
    fi

    if ! command_exists op; then
        info "1Password CLI ('op') not found. Attempting installation via Homebrew..."
        if brew install --cask 1password/tap/1password-cli; then
            info "1Password CLI installation finished."
            # Verify command exists now
            if ! command_exists op; then
                error "Installed 1Password CLI, but 'op' command is still not available."
            fi
        else
            error "Failed to install 1Password CLI using Homebrew. Please install manually and retry."
        fi
    else
        info "✅ 1Password CLI already installed."
    fi

    echo # Newline for clarity

    echo "🎉🎉🎉 Environment preparation complete! 🎉🎉🎉"
    info "Dotfiles repository is available at: $DOTFILES_FINAL_DIR"
    info "Next step: Run the main setup script inside the repository."
    info "Example:"
    info "  cd $DOTFILES_FINAL_DIR"
    info "  ./setup.sh"
    info "====================================================="
}

main "$@"
