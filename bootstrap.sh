#!/usr/bin/env bash
# bootstrap.sh – idempotent, resumable dot‑files installer

set -euo pipefail

# # Constants
# DOTFILES_REPO="https://github.com/sotayamashita/dotfiles"
# DOTFILES_SSH_URL="git@github.com:sotayamashita/dotfiles.git"
# DOTFILES_HTTPS_URL="https://github.com/sotayamashita/dotfiles.git"
# DOTFILES_TARBALL_URL="https://github.com/sotayamashita/dotfiles/tarball/main"
# DOTFILES_HOME_DIR="$HOME"
# DOTFILES_FINAL_DIR="$HOME/Projects/dotfiles"
# DOTFILES_STATE_FILE="$HOME/.dotfiles_setup_state"

# # Minimal logging functions (will be replaced if utils are available)
# info()  { echo -e "\033[32m[INFO]\033[0m  $*" >&2; }
# warn()  { echo -e "\033[33m[WARN]\033[0m  $*" >&2; }
# error() { echo -e "\033[31m[ERROR]\033[0m $*" >&2; exit 1; }
# debug() { [[ "${DEBUG:-}" == "1" ]] && echo -e "\033[34m[DEBUG]\033[0m $*" >&2; }







# # Check if command exists (minimal version for initial bootstrap)
# command_exists() {
#     command -v "$1" >/dev/null 2>&1
# }

# # Check if we're running on macOS
# is_macos() {
#     [[ "$(uname -s)" == "Darwin" ]]
# }

# # Setup platform-specific configurations
# setup_platform_specific() {
#     if is_macos; then
#         setup_macos
#     else
#         warn "Unsupported platform: $(uname -s)"
#     fi
# }

# # Setup macOS
# setup_macos() {
#     info "Setting up macOS..."
    
#     # Run macOS modules
#     run_script "preferences.sh" "macos"
#     run_script "dock.sh" "macos"
    
#     info "✅ macOS setup completed"
# }

# # Install prerequisites
# install_prerequisites() {
#     info "Installing prerequisites..."
    
#     # Install Xcode Command Line Tools if on macOS
#     if is_macos; then
#         if ! command_exists xcode-select; then
#             info "Installing Xcode Command Line Tools..."
#             xcode-select --install
            
#             # Wait for xcode-select to be installed
#             until command_exists xcode-select; do
#                 info "Waiting for Xcode Command Line Tools installation..."
#                 sleep 5
#             done
#         fi
        
#         # Accept Xcode license
#         sudo xcodebuild -license accept
#     fi
    
#     # Install Homebrew if not installed
#     if ! command_exists brew; then
#         info "Installing Homebrew..."
#         /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
#         # Add Homebrew to PATH
#         if is_macos; then
#             if [[ $(uname -m) == "arm64" ]]; then
#                 eval "$(/opt/homebrew/bin/brew shellenv)"
#             else
#                 eval "$(/usr/local/bin/brew shellenv)"
#             fi
#         fi
#     fi
    
#     info "✅ Prerequisites installed"
# }

# # Setup SSH
# setup_ssh() {
#     info "Setting up SSH..."
    
#     # Install 1Password CLI if not installed
#     if ! command_exists op; then
#         info "Installing 1Password CLI..."
#         brew install --cask 1password/tap/1password-cli
#     fi
    
#     # Configure SSH to use 1Password
#     info "Configuring SSH to use 1Password..."
#     mkdir -p ~/.ssh
    
#     # Check .ssh permission
#     if [ ! -w ~/.ssh ]; then
#         sudo chown -R $(whoami) ~/.ssh
#         sudo chmod 700 ~/.ssh
#     fi
    
#     # Create or update SSH config
#     # See: https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client
#     if [ ! -f ~/.ssh/config ] || ! grep -q "Host \*" ~/.ssh/config; then
#         cat > ~/.ssh/config << EOL
# Host *
#   IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
# EOL
#         info "SSH config created"
#     else
#         info "SSH config already exists, skipping"
#     fi
    
#     info "✅ SSH setup completed"
# }

# # Setup repository
# setup_repository() {
#     info "Setting up repository..."
    
#     # Create Projects directory if it doesn't exist
#     mkdir -p "$(dirname "$DOTFILES_FINAL_DIR")"

#     # Create Tools directory if it doesn't exist
#     mkdir -p "$DOTFILES_FINAL_DIR/Tools"
    
#     # Check if repository already exists
#     if [ -d "$DOTFILES_FINAL_DIR/.git" ]; then
#         info "Repository already exists, updating..."
#         cd "$DOTFILES_FINAL_DIR"
#         git pull
#     else
#         # Clone repository
#         info "Cloning repository..."
#         git clone "$DOTFILES_SSH_URL" "$DOTFILES_FINAL_DIR"
#     fi
    
#     info "✅ Repository setup completed"
# }

# # Setup core functionality
# setup_core() {
#     info "Setting up core functionality..."
    
#     # Run core modules
#     run_script "symlinks.sh" "core"
#     run_script "brew.sh" "core"
    
#     # Run installers
#     SCRIPTS_DIR=$(find_scripts_dir)
#     INSTALLERS_DIR="$SCRIPTS_DIR/installers"
    
#     if [ -d "$INSTALLERS_DIR" ]; then
#         info "Running installers..."
#         for installer in "$INSTALLERS_DIR"/*.sh; do
#             if [ -f "$installer" ]; then
#                 bash "$installer"
#             fi
#         done
#     fi
    
#     info "✅ Core setup completed"
# }

# # Cleanup temporary files
# cleanup_temp_files() {
#     info "Cleaning up temporary files..."
    
#     # Remove temporary files from home directory if they exist
#     if [ -d "$DOTFILES_HOME_DIR/scripts" ] && [ "$DOTFILES_HOME_DIR" != "$DOTFILES_FINAL_DIR" ]; then
#         rm -rf "$DOTFILES_HOME_DIR/scripts"
#     fi
    
#     info "✅ Cleanup completed"
# }

# # Run script from modules directory
# run_script() {
#     local script_name="$1"
#     local module_name="$2"
#     local script_path=""
    
#     SCRIPTS_DIR=$(find_scripts_dir)
    
#     # Check if script exists
#     if [ -f "$SCRIPTS_DIR/modules/$module_name/$script_name" ]; then
#         script_path="$SCRIPTS_DIR/modules/$module_name/$script_name"
        
#         # Check if script is executable
#         if [ ! -x "$script_path" ]; then
#             info "Making script executable: $script_path"
#             chmod +x "$script_path"
#         fi
        
#         info "Running script: $module_name/$script_name"
#         bash "$script_path"
#         return 0
#     else
#         warn "Script not found: $module_name/$script_name"
#         return 1
#     fi
# }

# # Load current setup state
# load_state() {
#     if [ -f "$DOTFILES_STATE_FILE" ]; then
#         cat "$DOTFILES_STATE_FILE"
#     else
#         echo "initial"
#     fi
# }

# # Save current setup state
# save_state() {
#     local state="$1"
#     echo "$state" > "$DOTFILES_STATE_FILE"
#     info "Setup state saved: $state"
# }


# # Determine scripts directory location
# find_scripts_dir() {
#     # Check if we're running from the cloned repo
#     if [ -d "$DOTFILES_FINAL_DIR/scripts" ]; then
#         echo "$DOTFILES_FINAL_DIR/scripts"
#         return
#     fi
    
#     # Check if we're running from the home directory setup
#     if [ -d "$DOTFILES_HOME_DIR/scripts" ]; then
#         echo "$DOTFILES_HOME_DIR/scripts"
#         return
#     fi
    
#     # If not found, we need to download the repository
#     info "Scripts directory not found, downloading dotfiles..."
#     cd "$DOTFILES_HOME_DIR"
#     curl -#L "$DOTFILES_TARBALL_URL" | tar -xzv --strip-components 1 --exclude={README.md}
    
#     if [ -d "$DOTFILES_HOME_DIR/scripts" ]; then
#         echo "$DOTFILES_HOME_DIR/scripts"
#     else
#         error "Failed to find or create scripts directory"
#     fi
# }

readonly DOTFILES_FINAL_DIR="$HOME/Projects/dotfiles"



_SCRIPTS_DIR=""
find_scripts_dir() {
    if [ -n "$_SCRIPTS_DIR" ]; then
        echo "$_SCRIPTS_DIR"
        return
    fi

    if [ -d "$DOTFILES_FINAL_DIR/scripts" ]; then
        _SCRIPTS_DIR="$DOTFILES_FINAL_DIR/scripts"
    elif [ -d "$HOME/scripts" ]; then
        _SCRIPTS_DIR="$HOME/scripts"
    else
        info "Scripts directory not found, downloading dotfiles..."
        local temp_dir

        temp_dir=$(mktemp -d) || error "Failed to create temporary directory"
        info "Downloading tarball to $temp_dir..."
        if ! curl -#L "$DOTFILES_TARBALL_URL" | tar -xz -C "$temp_dir" --strip-components 1 --exclude='README.md'; then
            rm -rf "$temp_dir" # Clean up temp dir on failure
            error "Failed to download or extract dotfiles tarball."
        fi

        if [ -d "$temp_dir/scripts" ]; then
            # Move scripts to home dir for initial setup
            mv "$temp_dir/scripts" "$HOME/scripts" || error "Failed to move scripts directory."
            _SCRIPTS_DIR="$HOME/scripts"
            
    fi
}

# Main function to orchestrate the setup process
main() {    
    # Load common utilities if available
    SCRIPTS_DIR=$(find_scripts_dir)
    if [ -f "$SCRIPTS_DIR/lib/utils.sh" ]; then
        source "$SCRIPTS_DIR/lib/utils.sh"
    fi
    
    if [ -f "$SCRIPTS_DIR/lib/state.sh" ]; then
        source "$SCRIPTS_DIR/lib/state.sh"
    fi
}

# Run the main function
main 
