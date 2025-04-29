#!/bin/bash
#
# init_env.sh - Script to prepare minimal environment for cloning dotfiles repository via SSH
# - Automatically checks and sets up Xcode CLT, Homebrew, 1Password CLI, and SSH configuration
# - Follows Google Shell Style Guide

set -euo pipefail

# --- Constants ---
readonly DOTFILES_SSH_URL="git@github.com:sotayamashita/dotfiles.git"
readonly DOTFILES_FINAL_DIR="$HOME/Projects/dotfiles"
readonly REQUIRED_COMMANDS=("curl" "git" "sudo")

# --- Logging Helper Functions ---
log_prefix_val() {
    local color_start=""
    local color_end=""
    if [ -t 2 ]; then
        case "$1" in
            INFO)  color_start='\033[0;32m'; color_end='\033[0m';;
            WARN)  color_start='\033[0;33m'; color_end='\033[0m';;
            ERROR) color_start='\033[0;31m'; color_end='\033[0m';;
            STEP)  color_start='\033[0;34m'; color_end='\033[0m';;
        esac
    fi
    printf "%b[%s]%b" "${color_start}" "$1" "${color_end}"
}

info()   { echo "$(log_prefix_val INFO) $1" >&2; }
warn()   { echo "$(log_prefix_val WARN) $1" >&2; }
error()  { echo "$(log_prefix_val ERROR) $1" >&2; exit 1; }
step()   { echo -e "\n$(log_prefix_val STEP) --- $1 ---" >&2; }
prompt() { echo -e "\n$(log_prefix_val PROMPT) $1" >&2; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

# --- Check essential commands ---
check_essential_commands() {
    step "Checking essential commands"
    local missing_cmds=0
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            error "Required command '$cmd' is not installed. Please install it manually and retry."
            missing_cmds=1
        fi
    done
    [ "$missing_cmds" -eq 0 ] || exit 1
    info "✅ Essential commands found."
}

# --- Ensure Xcode Command Line Tools ---
ensure_xcode_clt() {
    step "Checking Xcode Command Line Tools"
    if ! is_macos; then
        info "Not macOS, skipping Xcode Command Line Tools check."
        return 0
    fi
    if ! xcode-select -p > /dev/null 2>&1; then
        info "Xcode Command Line Tools not found. Attempting installation..."
        info "Please follow the on-screen prompts to install."
        xcode-select --install
        info "Waiting for you to complete Xcode CLT installation..."
        local count=0
        local max_wait=30
        until xcode-select -p &>/dev/null || [ "$count" -ge "$max_wait" ]; do
            printf "." >&2
            sleep 10
            count=$((count + 1))
        done
        echo >&2
        if ! xcode-select -p &>/dev/null; then
            error "Xcode Command Line Tools installation timed out or was cancelled. Please install manually and retry."
        else
            info "Xcode Command Line Tools installation detected."
            info "Attempting to accept Xcode license..."
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
    return 0
}

# --- Ensure Homebrew ---
ensure_homebrew() {
    step "Checking Homebrew"
    if ! is_macos; then
        info "Not macOS, skipping Homebrew check."
        return 0
    fi
    local brew_prefix
    if [[ "$(uname -m)" == "arm64" ]]; then
        brew_prefix="/opt/homebrew"
    else
        brew_prefix="/usr/local"
    fi
    if ! command_exists "${brew_prefix}/bin/brew"; then
        info "Homebrew not found. Attempting installation..."
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            info "Homebrew installation script finished."
            if [ -x "${brew_prefix}/bin/brew" ]; then
                eval "$(${brew_prefix}/bin/brew shellenv)"
                info "Homebrew environment configured for this script session."
                if ! command_exists brew; then
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
        if [ -x "${brew_prefix}/bin/brew" ] && [[ ":$PATH:" != *":${brew_prefix}/bin:"* ]]; then
            info "Adding Homebrew to PATH for this script session..."
            eval "$(${brew_prefix}/bin/brew shellenv)"
            if ! command_exists brew; then
                warn "Attempted to configure Homebrew env, but 'brew' command still not found."
            fi
        fi
    fi
    if ! command_exists brew; then
        error "Cannot proceed: 'brew' command is not available."
    fi
    return 0
}

# --- Ensure 1Password CLI ---
ensure_1password_cli() {
    step "Checking 1Password CLI"
    if ! is_macos; then
        info "Not macOS, skipping 1Password CLI check."
        return 0
    fi
    if ! command_exists brew; then
        error "Homebrew ('brew') command not found. Cannot install 1Password CLI."
    fi
    if ! command_exists op; then
        info "1Password CLI ('op') not found. Attempting installation via Homebrew..."
        if brew install --cask 1password/tap/1password-cli; then
            info "1Password CLI installation finished."
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

# --- Prompt to enable 1Password SSH Agent ---
prompt_enable_1password_ssh_agent() {
    step "ACTION REQUIRED: Enable 1Password SSH Agent"
    if ! is_macos; then
        info "Not macOS, skipping 1Password SSH Agent prompt."
        return 0
    fi
    info "The next steps require the 1Password SSH Agent to be enabled within the 1Password app."
    info "Instructions:"
    info " 1. Open the 1Password application."
    info " 2. Go to Preferences/Settings (usually Cmd + ,)."
    info " 3. Navigate to the 'Developer' section."
    info " 4. Ensure 'Integrate with 1Password CLI' is enabled."
    info " 5. Ensure 'Use the SSH Agent' is enabled."
    info " See: https://developer.1password.com/docs/ssh/get-started#step-3-turn-on-the-1password-ssh-agent"
    echo ""
    local open_app_response
    local confirm_response
    prompt "Would you like this script to try opening the 1Password app for you? (y/N)"
    read -r open_app_response
    open_app_response=$(echo "$open_app_response" | tr '[:upper:]' '[:lower:]')
    if [[ "$open_app_response" =~ ^y(es)?$ ]]; then
        info "Attempting to open 1Password..."
        if ! open -a "1Password"; then
            warn "Could not open 1Password automatically. Please open it manually."
        fi
    else
        info "Okay, please open 1Password manually."
    fi
    prompt "Please follow the instructions above to enable the SSH Agent in 1Password."
    prompt "Once you have enabled the 'Use the SSH Agent' setting, press Enter to continue..."
    read -r confirm_response
    info "Thank you. Proceeding with SSH configuration..."
    return 0
}

# --- SSH configuration: 1Password Agent ---
ensure_ssh_config_for_1password() {
    step "Configuring SSH for 1Password Agent"
    if ! is_macos; then
        info "Not macOS, skipping SSH Agent configuration."
        return 0
    fi
    local ssh_dir="$HOME/.ssh"
    local ssh_config_file="$ssh_dir/config"
    local agent_config_line='IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'
    if [ ! -d "$ssh_dir" ]; then
        info "Creating directory: $ssh_dir"
        mkdir -m 700 "$ssh_dir" || error "Failed to create $ssh_dir"
        info "Directory $ssh_dir created with 700 permissions."
    else
        if [[ $(stat -f "%Lp" "$ssh_dir") != 700 ]]; then
            info "Correcting permissions for $ssh_dir to 700"
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
            if ! grep -qE "^\s*Host\s+\*\s*$" "$ssh_config_file"; then
                echo "" >> "$ssh_config_file"
                echo "Host *" >> "$ssh_config_file"
                info "Added 'Host *' block."
                echo "  $agent_config_line" >> "$ssh_config_file"
            else
                echo "" >> "$ssh_config_file"
                echo "# Added by init_env.sh for 1Password (if not already present under Host *)" >> "$ssh_config_file"
                echo "  $agent_config_line" >> "$ssh_config_file"
            fi
            info "✅ 1Password Agent setting added/ensured."
        fi
        if [[ $(stat -f "%Lp" "$ssh_config_file") != 600 ]]; then
            info "Correcting permissions for $ssh_config_file to 600"
            chmod 600 "$ssh_config_file" || warn "Failed to set permissions on $ssh_config_file"
        fi
    fi
    info "SSH configuration check complete."
    info "IMPORTANT: Ensure the 1Password desktop app is running and the SSH agent is enabled in its Developer settings."
    return 0
}

# --- Ensure dotfiles repository is cloned ---
ensure_dotfiles_repo_cloned() {
    step "Checking dotfiles repository status"
    local projects_dir
    projects_dir=$(dirname "$DOTFILES_FINAL_DIR")
    if ! [ -d "$projects_dir" ]; then
        info "Creating parent directory: $projects_dir"
        mkdir -p "$projects_dir" || error "Failed to create directory: $projects_dir"
    fi
    if [ -d "$DOTFILES_FINAL_DIR" ]; then
        if [ -d "$DOTFILES_FINAL_DIR/.git" ]; then
            info "Directory exists: $DOTFILES_FINAL_DIR"
            local current_remote_url
            current_remote_url=$( (cd "$DOTFILES_FINAL_DIR" && git config --get remote.origin.url) 2>/dev/null || echo "" )
            if [[ "$current_remote_url" == "$DOTFILES_SSH_URL" ]]; then
                info "✅ Repository already cloned with correct SSH remote URL."
                return 0
            elif [[ -n "$current_remote_url" ]]; then
                error "Directory '$DOTFILES_FINAL_DIR' is a git repository, but has the wrong remote origin URL ('$current_remote_url'). Expected '$DOTFILES_SSH_URL'."
                error "Please move/delete this directory, or fix the remote ('git remote set-url origin $DOTFILES_SSH_URL'), then re-run."
            else
                error "Directory '$DOTFILES_FINAL_DIR' exists but does not appear to be a valid git repository or remote 'origin' is not set."
                error "Please move or delete this directory, then re-run this script."
            fi
        else
            error "Directory '$DOTFILES_FINAL_DIR' exists but is not a git repository."
            error "Please move or delete this directory, then re-run this script."
        fi
    else
        info "Repository not found locally. Cloning via SSH from $DOTFILES_SSH_URL..."
        if ! command_exists git; then
            error "'git' command not found. Please ensure Git (via Xcode CLT or separate install) is available."
        fi
        if git clone --quiet "$DOTFILES_SSH_URL" "$DOTFILES_FINAL_DIR"; then
            info "✅ Repository cloned successfully to $DOTFILES_FINAL_DIR"
            return 0
        else
            error "Failed to clone repository using SSH."
            error "Troubleshooting tips:"
            error " - Run 'ssh -T git@github.com' to test SSH connectivity to GitHub."
            error " - Verify your SSH key is added to your GitHub account."
            error " - Confirm 1Password SSH Agent is enabled and 1Password app is running."
            error " - Check network connection and repository URL ('$DOTFILES_SSH_URL')."
        fi
    fi
}

# --- Main function ---
main() {
    info "===== Initializing Environment for Dotfiles Setup ====="
    check_essential_commands
    ensure_xcode_clt
    ensure_homebrew
    ensure_1password_cli
    prompt_enable_1password_ssh_agent
    ensure_ssh_config_for_1password
    ensure_dotfiles_repo_cloned
    echo
    info "Environment preparation complete!" >&2
    info "Dotfiles repository is available at: $DOTFILES_FINAL_DIR"
    info "Next step: Change into the repository directory and run the main setup script."
    info "Example:"
    info "  cd \"$DOTFILES_FINAL_DIR\""
    info "  sync.sh"
    info "============================================================================"
}

main "$@"
