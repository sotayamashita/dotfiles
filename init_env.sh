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
_log_prefix_val() {
    local color_start=""
    local color_end=""
    # Check if STDERR is a terminal for color decision
    if [ -t 2 ]; then
        case "$1" in
            INFO)  color_start='\033[0;32m'; color_end='\033[0m';; # Green
            WARN)  color_start='\033[0;33m'; color_end='\033[0m';; # Yellow
            ERROR) color_start='\033[0;31m'; color_end='\033[0m';; # Red
            STEP)  color_start='\033[0;34m'; color_end='\033[0m';; # Blue
        esac
    fi
    # Use printf to handle colors and return the value (no automatic newline)
    printf "%b[%s]%b" "${color_start}" "$1" "${color_end}"
}

# Logging functions now capture the prefix and print the full line to stderr
info()  { echo "$(_log_prefix_val INFO) $1" >&2; }
warn()  { echo "$(_log_prefix_val WARN) $1" >&2; }
error() { echo "$(_log_prefix_val ERROR) $1" >&2; exit 1; }
# step now correctly incorporates the newline BEFORE the prefix returned by _log_prefix_val
step()  { echo -e "\n$(_log_prefix_val STEP) --- $1 ---" >&2; }

# Other helpers remain the same
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
command_exists() { command -v "$1" >/dev/null 2>&1; }


main() {
    info "===== Initializing Environment for Dotfiles Setup ====="

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
        if brew install --quiet --cask 1password/tap/1password-cli; then
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

    # Configure SSH for 1Password Agent
    step "Configuring SSH for 1Password Agent"
    local ssh_dir="$HOME/.ssh"
    local ssh_config_file="$ssh_dir/config"
    local agent_config_line='IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'

    if [ ! -d "$ssh_dir" ]; then
        info "Creating directory: $ssh_dir"
        mkdir "$ssh_dir" || error "Failed to create $ssh_dir"
        chmod 700 "$ssh_dir" || warn "Failed to set permissions on $ssh_dir"
    else
        if [[ $(stat -f "%Lp" "$ssh_dir") != 700 ]]; then
            info "Correcting permissions for $ssh_dir"
            chmod 700 "$ssh_dir" || warn "Failed to set permissions on $ssh_dir"
        fi
    fi

    if [ ! -f "$ssh_config_file" ]; then
        info "Creating SSH config file: $ssh_config_file"
        (
            echo "Host *"
            echo "  $agent_config_line"
        ) > "$ssh_config_file"
        chmod 600 "$ssh_config_file" || warn "Failed to set permissions on $ssh_config_file"
        info "✅ SSH config created for 1Password Agent."
    else
        if grep -qF "$agent_config_line" "$ssh_config_file"; then
            info "✅ SSH config already contains 1Password Agent setting."
        else
            info "Adding 1Password Agent setting to $ssh_config_file"
            if ! grep -qE "^\s*Host\s+\*" "$ssh_config_file"; then
                echo "" >> "$ssh_config_file"
                echo "Host *" >> "$ssh_config_file"
            fi
            echo "" >> "$ssh_config_file"
            echo "# Added by init_env.sh for 1Password" >> "$ssh_config_file"
            echo "  $agent_config_line" >> "$ssh_config_file"
            info "✅ 1Password Agent setting added."
        fi
        if [[ $(stat -f "%Lp" "$ssh_config_file") != 600 ]]; then
            info "Correcting permissions for $ssh_config_file"
            chmod 600 "$ssh_config_file" || warn "Failed to set permissions on $ssh_config_file"
        fi
    fi
    info "SSH configuration check complete."
    info "IMPORTANT: Ensure the 1Password desktop app is running and the SSH agent is enabled in its Developer settings."

    # Check for dotfiles repository
    step "Checking dotfiles repository"
    local projects_dir
    projects_dir=$(dirname "$DOTFILES_FINAL_DIR")

    if [ ! -d "$projects_dir" ]; then
        info "Creating parent directory: $projects_dir"
        mkdir -p "$projects_dir" || error "Failed to create directory: $projects_dir"
    fi

    if [ -d "$DOTFILES_FINAL_DIR" ]; then
        if [ -d "$DOTFILES_FINAL_DIR/.git" ]; then
            info "Directory exists: $DOTFILES_FINAL_DIR"
            local current_remote_url
            current_remote_url=$( (cd "$DOTFILES_FINAL_DIR" && git config --get remote.origin.url) 2>/dev/null || echo "Not a git repo or no remote origin" )

            if [[ "$current_remote_url" == "$DOTFILES_SSH_URL" ]]; then
                info "✅ Repository already cloned with correct SSH remote URL."
                return 0
            else
                error "Directory '$DOTFILES_FINAL_DIR' exists but is either not a git repository or has the wrong remote origin URL ('$current_remote_url')."
                return 1
            fi
        else
            error "Directory '$DOTFILES_FINAL_DIR' exists but is not a git repository."
            return 1
        fi
    else
        info "Repository not found locally. Cloning via SSH from $DOTFILES_SSH_URL..."
        if git clone "$DOTFILES_SSH_URL" "$DOTFILES_FINAL_DIR"; then
            info "✅ Repository cloned successfully to $DOTFILES_FINAL_DIR"
            return 0
        else
            error "Failed to clone repository using SSH."
            return 1
        fi
    fi

    echo # Newline for clarity

    info "🎉🎉🎉 Environment preparation complete! 🎉🎉🎉"
    info "Dotfiles repository is available at: $DOTFILES_FINAL_DIR"
    info "Next step: Run the main setup script inside the repository."
    info "Example:"
    info "  cd $DOTFILES_FINAL_DIR"
    info "  ./setup.sh"
    info "====================================================="
}

main "$@"
