#!/usr/bin/env bash
# init_env.sh - Prepares the minimal environment for cloning the dotfiles repository via SSH.
# Ensures prerequisites (Xcode CLT, Homebrew, 1Password CLI) are met and SSH is configured.

set -euo pipefail

# --- Configuration ---
readonly DOTFILES_SSH_URL="git@github.com:sotayamashita/dotfiles.git" # Your SSH repo URL
readonly DOTFILES_FINAL_DIR="$HOME/Projects/dotfiles" # Your desired local repo path
readonly REQUIRED_COMMANDS=("curl" "git" "sudo")

# --- Corrected Minimal Logging & Helpers ---

# Returns the formatted prefix string (doesn't print directly)
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
    # %b interprets backslash escapes (like \033), %s prints string argument
    printf "%b[%s]%b" "${color_start}" "$1" "${color_end}"
}

# Logging functions now capture the prefix and print the full line to stderr
info()  { echo "$(_log_prefix_val INFO) $1" >&2; }
warn()  { echo "$(_log_prefix_val WARN) $1" >&2; }
error() { echo "$(_log_prefix_val ERROR) $1" >&2; exit 1; }
# step now correctly incorporates the newline BEFORE the prefix returned by _log_prefix_val
step()  { echo -e "\n$(_log_prefix_val STEP) --- $1 ---" >&2; }

# Other helpers
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
command_exists() { command -v "$1" >/dev/null 2>&1; }


# --- Prerequisite and Setup Functions ---

check_essential_commands() {
    step "Checking essential commands"
    local missingCmds=0
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            error "Required command '$cmd' is not installed. Please install it manually and retry."
            # error function exits, so missingCmds tracking isn't strictly needed here
            # but kept for structural clarity if error handling changes
            missingCmds=1
        fi
    done
    [ "$missingCmds" -eq 0 ] || exit 1 # Exit if any command was missing (redundant due to error exit)
    info "✅ Essential commands found."
}

ensure_xcode_clt() {
    step "Checking Xcode Command Line Tools"
    if ! is_macos; then
        info "Not macOS, skipping Xcode Command Line Tools check."
        return 0 # Use return 0 to indicate success/not applicable for this step
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
            # Error will exit the script
            error "Xcode Command Line Tools installation timed out or was cancelled. Please install manually and retry."
        else
            info "Xcode Command Line Tools installation detected."
            # Try accepting license automatically, warn if it fails
            info "Attempting to accept Xcode license..."
            # Use sudo -v to ensure sudo session is active before potentially lengthy command
            sudo -v
            if ! sudo xcodebuild -license accept >/dev/null 2>&1; then
                warn "Could not automatically accept Xcode license. You might need to run 'sudo xcodebuild -license' manually."
            else
                info "Xcode license accepted."
            fi
        fi
    else
        info "✅ Xcode Command Line Tools already installed."
    fi
    return 0 # Indicate success for this step
}

ensure_homebrew() {
    step "Checking Homebrew"
    if ! is_macos; then
        info "Not macOS, skipping Homebrew check."
        return 0
    fi

    # Check if brew command is available in PATH *before* attempting install
    if ! command_exists brew; then
        info "Homebrew not found. Attempting installation..."
        # Use standard interactive install script
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            info "Homebrew installation script finished."
            # Determine brew prefix based on architecture
            local brew_prefix
            if [[ "$(uname -m)" == "arm64" ]]; then
                brew_prefix="/opt/homebrew"
            else
                brew_prefix="/usr/local"
            fi
            # Check if brew executable exists at expected path
            if [ -x "${brew_prefix}/bin/brew" ]; then
                # Add Homebrew to PATH for the *current script execution*
                eval "$(${brew_prefix}/bin/brew shellenv)"
                info "Homebrew environment configured for this script session."
                # Verify command exists *after* eval
                if ! command_exists brew; then
                    # This case should be rare after successful install + eval
                    error "Homebrew installed and eval ran, but 'brew' command is still not available in PATH."
                fi
            else
                warn "Could not find brew executable after install at: ${brew_prefix}/bin/brew"
                error "Homebrew installation seems incomplete."
            fi
        else
            error "Homebrew installation script failed. Please install manually and retry."
        fi
    else
        info "✅ Homebrew already installed."
        # Even if installed, ensure PATH is set for the current script session
        # This helps if the permanent PATH config (.zprofile etc.) hasn't taken effect yet
        local brew_prefix
        if [[ "$(uname -m)" == "arm64" ]]; then
            brew_prefix="/opt/homebrew"
        else
            brew_prefix="/usr/local"
        fi
        # Check if brew binary path is actually in the current PATH
        if [ -x "${brew_prefix}/bin/brew" ] && [[ ":$PATH:" != *":${brew_prefix}/bin:"* ]]; then
            info "Adding Homebrew to PATH for this script session..."
            eval "$(${brew_prefix}/bin/brew shellenv)"
            # Re-verify after eval
            if ! command_exists brew; then
                warn "Attempted to configure Homebrew env, but 'brew' command still not found."
            fi
        fi
    fi
    # Final check if brew command is usable before proceeding
    if ! command_exists brew; then
        error "Cannot proceed: 'brew' command is not available."
    fi
    return 0
}

ensure_1password_cli() {
    step "Checking 1Password CLI"
    if ! is_macos; then
        info "Not macOS, skipping 1Password CLI check."
        return 0
    fi
    # Check brew command first (should be available after ensure_homebrew)
    if ! command_exists brew; then
        error "Homebrew ('brew') command not found. Cannot install 1Password CLI."
    fi

    if ! command_exists op; then
        info "1Password CLI ('op') not found. Attempting installation via Homebrew..."
        # Use brew install -q for less verbose output? Or keep default.
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
    return 0
}

ensure_ssh_config_for_1password() {
    step "Configuring SSH for 1Password Agent"
    if ! is_macos; then
        info "Not macOS, skipping SSH Agent configuration."
        return 0
    fi

    local ssh_dir="$HOME/.ssh"
    local ssh_config_file="$ssh_dir/config"
    local agent_config_line='IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'

    # 1. Ensure ~/.ssh directory exists with correct permissions
    if [ ! -d "$ssh_dir" ]; then
        info "Creating directory: $ssh_dir"
        # Create directory and set permissions in one go if possible
        mkdir -m 700 "$ssh_dir" || error "Failed to create $ssh_dir"
        info "Directory $ssh_dir created with 700 permissions."
    else
        # Correct permissions if needed
        if [[ $(stat -f "%Lp" "$ssh_dir") != 700 ]]; then
            info "Correcting permissions for $ssh_dir to 700"
            chmod 700 "$ssh_dir" || warn "Failed to set permissions on $ssh_dir"
        fi
    fi

    # 2. Ensure the IdentityAgent line is present in the config file
    if [ ! -f "$ssh_config_file" ]; then
        # Config file doesn't exist, create it
        info "Creating SSH config file: $ssh_config_file"
        (
            echo "Host *" # Add Host * block for the agent setting
            echo "  $agent_config_line"
        ) > "$ssh_config_file"
        # Set permissions after creating
        chmod 600 "$ssh_config_file" || warn "Failed to set permissions on $ssh_config_file"
        info "✅ SSH config created for 1Password Agent."
    else
        # Config file exists, check content
        if grep -qF "$agent_config_line" "$ssh_config_file"; then
            info "✅ SSH config already contains 1Password Agent setting."
        else
            # Line is missing, append it. Add 'Host *' if needed.
            info "Adding 1Password Agent setting to $ssh_config_file"
            # Check if 'Host *' line exists (allowing leading/trailing whitespace)
            if ! grep -qE "^\s*Host\s+\*\s*$" "$ssh_config_file"; then
                echo "" >> "$ssh_config_file" # Ensure newline before adding Host *
                echo "Host *" >> "$ssh_config_file"
                info "Added 'Host *' block."
                # Append the agent line directly under the new Host *
                echo "  $agent_config_line" >> "$ssh_config_file"
            else
                # Host * exists, append the agent line at the end (simplest approach)
                # Add a comment for clarity
                echo "" >> "$ssh_config_file" # Ensure newline
                echo "# Added by init_env.sh for 1Password (if not already present under Host *)" >> "$ssh_config_file"
                echo "  $agent_config_line" >> "$ssh_config_file"
            fi
            info "✅ 1Password Agent setting added/ensured."
        fi
        # Ensure correct permissions on existing file
        if [[ $(stat -f "%Lp" "$ssh_config_file") != 600 ]]; then
            info "Correcting permissions for $ssh_config_file to 600"
            chmod 600 "$ssh_config_file" || warn "Failed to set permissions on $ssh_config_file"
        fi
    fi
    info "SSH configuration check complete."
    info "IMPORTANT: Ensure the 1Password desktop app is running and the SSH agent is enabled in its Developer settings."
    return 0
}

ensure_dotfiles_repo_cloned() {
    step "Checking dotfiles repository status"
    local projects_dir
    projects_dir=$(dirname "$DOTFILES_FINAL_DIR")

    # Ensure parent directory exists (e.g., ~/Projects)
    if ! [ -d "$projects_dir" ]; then
        info "Creating parent directory: $projects_dir"
        mkdir -p "$projects_dir" || error "Failed to create directory: $projects_dir"
    fi

    # Check if the target directory exists
    if [ -d "$DOTFILES_FINAL_DIR" ]; then
        # Directory exists, check if it's a valid git repo with the correct remote
        if [ -d "$DOTFILES_FINAL_DIR/.git" ]; then
            info "Directory exists: $DOTFILES_FINAL_DIR"
            local current_remote_url
            # Use 'cd' in a subshell and capture stderr to hide git errors if not a repo
            current_remote_url=$( (cd "$DOTFILES_FINAL_DIR" && git config --get remote.origin.url) 2>/dev/null || echo "" )

            if [[ "$current_remote_url" == "$DOTFILES_SSH_URL" ]]; then
                info "✅ Repository already cloned with correct SSH remote URL."
                # Optional: Check connection without modifying files
                # info "Verifying connection to remote..."
                # if (cd "$DOTFILES_FINAL_DIR" && git fetch --dry-run origin >/dev/null 2>&1); then
                #     info "Connection verified."
                # else
                #     warn "Could not verify connection to remote origin ($DOTFILES_SSH_URL)."
                # fi
                return 0 # Already correctly cloned
            elif [[ -n "$current_remote_url" ]]; then
                # It's a git repo, but wrong remote
                error "Directory '$DOTFILES_FINAL_DIR' is a git repository, but has the wrong remote origin URL ('$current_remote_url'). Expected '$DOTFILES_SSH_URL'."
                error "Please move/delete this directory, or fix the remote ('git remote set-url origin $DOTFILES_SSH_URL'), then re-run."
                # Do not return 1 here, error function exits
            else
                # Directory exists, but doesn't seem to be a git repo (or remote failed)
                error "Directory '$DOTFILES_FINAL_DIR' exists but does not appear to be a valid git repository or remote 'origin' is not set."
                error "Please move or delete this directory, then re-run this script."
                # Do not return 1 here, error function exits
            fi
        else
            # Directory exists but is not a git repository
            error "Directory '$DOTFILES_FINAL_DIR' exists but is not a git repository."
            error "Please move or delete this directory, then re-run this script."
            # Do not return 1 here, error function exits
        fi
    else
        # Directory does not exist, proceed to clone
        info "Repository not found locally. Cloning via SSH from $DOTFILES_SSH_URL..."
        # Check git command exists before cloning
        if ! command_exists git; then
            error "'git' command not found. Please ensure Git (via Xcode CLT or separate install) is available."
        fi
        # Check SSH connection to GitHub first? Optional but helpful for debugging.
        # ssh -T git@github.com

        if git clone --quiet "$DOTFILES_SSH_URL" "$DOTFILES_FINAL_DIR"; then
            info "✅ Repository cloned successfully to $DOTFILES_FINAL_DIR"
            return 0
        else
            error "Failed to clone repository using SSH."
            # Add more specific troubleshooting tips if possible
            error "Troubleshooting tips:"
            error " - Run 'ssh -T git@github.com' to test SSH connectivity to GitHub."
            error " - Verify your SSH key is added to your GitHub account."
            error " - Confirm 1Password SSH Agent is enabled and 1Password app is running."
            error " - Check network connection and repository URL ('$DOTFILES_SSH_URL')."
            # Do not return 1 here, error function exits
        fi
    fi
}


# --- Main Execution ---
main() {
    # Use a trap to ensure cleanup or final messages on exit? Optional.
    # trap 'echo "Script exited."' EXIT

    info "===== Initializing Environment for Dotfiles Setup ====="

    # Run checks and setups sequentially. Error function will halt on failure.
    check_essential_commands
    ensure_xcode_clt
    ensure_homebrew
    ensure_1password_cli
    ensure_ssh_config_for_1password
    ensure_dotfiles_repo_cloned

    echo # Newline for clarity

    # Final success messages (using corrected info function)
    # Use echo directly to stderr for the emoji line for robustness if info fails somehow
    echo "🎉🎉🎉 Environment preparation complete! 🎉🎉🎉" >&2
    info "Dotfiles repository is available at: $DOTFILES_FINAL_DIR"
    info "Next step: Change into the repository directory and run the main setup script."
    info "Example:"
    info "  cd \"$DOTFILES_FINAL_DIR\"" # Quote path for safety
    info "  ./setup.sh  # <-- Replace 'setup.sh' with the actual script name in your repo"
    info "============================================================================"
}

# --- Execute Main Function ---
# Pass all script arguments to the main function (though main doesn't currently use them)
main "$@"
