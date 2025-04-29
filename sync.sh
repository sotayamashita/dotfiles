#!/usr/bin/env bash
# sync.sh - Performs the main dotfiles synchronization and setup tasks.
# Run this script from within the dotfiles repository directory (~/Projects/dotfiles).

set -euo pipefail

# --- Determine script's directory to reliably source libraries ---
# This ensures that the script can find the 'scripts/' directory
# regardless of where it's called from (as long as it's within the repo).
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" || exit 1 # Change into the script's directory (dotfiles root)

# --- Source Utilities ---
# shellcheck source=scripts/lib/utils.sh
source "${SCRIPT_DIR}/scripts/lib/utils.sh" || { echo "[ERROR] Failed to source utils.sh" >&2; exit 1; }

# --- Function to set Fish as default shell ---
set_fish_as_default_shell() {
    step "Setting Fish as default shell"

    # 1. Check if fish is installed (command should exist after brew bundle)
    if ! command_exists fish; then
        warn "Fish shell ('fish') command not found. Skipping default shell change."
        warn "Ensure 'fish' is included in your Brewfile."
        return 1 # Indicate failure or skipped step
    fi

    # 2. Get the full path to the fish executable
    local fish_path
    fish_path=$(command -v fish)
    if [ -z "$fish_path" ]; then
        # This shouldn't happen if command_exists passed, but check anyway
        warn "Could not determine the path for fish shell. Skipping default shell change."
        return 1
    fi
    info "Fish shell found at: $fish_path"

    # 3. Check if the fish path is already in /etc/shells
    if ! grep -qFx "$fish_path" /etc/shells; then
        info "Adding $fish_path to /etc/shells (requires sudo)"
        # Check if we can get sudo access non-interactively first
        if sudo -n true > /dev/null 2>&1; then
            # Append using sudo tee -a
            if echo "$fish_path" | sudo tee -a /etc/shells > /dev/null; then
                info "✅ Successfully added $fish_path to /etc/shells"
            else
                error "Failed to add $fish_path to /etc/shells even with sudo."
                # return 1 # error function exits
            fi
        else
            warn "sudo access required to modify /etc/shells."
            warn "Please run 'echo \"$fish_path\" | sudo tee -a /etc/shells' manually,"
            warn "or run sync.sh with sudo privileges (not generally recommended)."
            warn "Skipping default shell change for now."
            return 1 # Skip changing shell if /etc/shells wasn't updated
        fi
    else
        info "✅ Fish path '$fish_path' already exists in /etc/shells."
    fi

    # 4. Check if the current default shell is already fish
    local current_shell
    current_shell=$(dscl . -read "$HOME" UserShell | awk '{print $2}')
    # Alternative using $SHELL (might not reflect default, but current running shell)
    # current_shell=$SHELL

    if [ "$current_shell" == "$fish_path" ]; then
        info "✅ Default shell is already set to $fish_path."
        return 0 # Success, nothing to do
    fi

    # 5. Change the default shell using chsh
    info "Changing default shell to $fish_path..."
    # chsh might require password depending on system settings
    # Using sudo with chsh might change root's shell, which is usually undesired.
    # Run chsh as the user. It might prompt for password.
    if chsh -s "$fish_path"; then
        info "✅ Default shell changed successfully."
        info "Changes will take effect on the next login."
    else
        warn "Failed to change default shell using 'chsh -s $fish_path'."
        warn "You might need to run this command manually."
        return 1
    fi

    return 0
}


# --- Main Setup Logic ---
main() {
    info "===== Starting Dotfiles Synchronization and Setup ====="

    step "Updating dotfiles repository"
    if git pull --ff-only; then
        info "✅ Repository updated successfully."
    else
        warn "Could not fast-forward pull repository. Manual check needed if updates exist."
    fi

    # --- Core Setup ---
    step "Running Core Setup modules"
    # Run symlinks setup using the utility function (which finds the script)
    run_script "symlinks.sh" "core" || error "Symlink setup failed."

    # Run brew bundle using the utility function
    run_script "brew.sh" "core" || error "Homebrew bundle setup failed."

    # --- Set Fish Shell (Call the new function) ---
    set_fish_as_default_shell || warn "Could not set Fish as default shell automatically."

    # --- Installers ---
    step "Running Installers"
    local installers_dir="${SCRIPT_DIR}/scripts/installers"
    local ran_installer=false
    local failed_installers=0

    if [ -d "$installers_dir" ]; then
        for installer in "$installers_dir"/*.sh; do
            if [ -f "$installer" ]; then
                ran_installer=true
                local installer_name
                installer_name=$(basename "$installer")
                # Use run_installer utility function
                run_installer "$installer_name" || failed_installers=$((failed_installers + 1))
            fi
        done
        if ! $ran_installer; then
            info "No installers found in $installers_dir."
        elif [ "$failed_installers" -gt 0 ]; then
            warn "$failed_installers installer(s) failed. Continuing setup..."
            # Decide if failure here should be fatal:
            # error "$failed_installers installer(s) failed. Aborting."
        fi
    else
        warn "Installers directory not found: $installers_dir"
    fi

    # --- Platform Specific Setup (macOS) ---
    if is_macos; then
        step "Running macOS Setup modules"
        run_script "preferences.sh" "macos" || warn "macOS preferences setup failed." # Warn instead of error?
        run_script "dock.sh" "macos" || warn "macOS Dock setup failed." # Warn instead of error?

        # Optional: Add reminder about logout/restart for some settings
        info "Note: Some macOS preference changes might require a logout/login or restart."
    else
        info "Skipping macOS specific setup (not running on macOS)."
    fi

    # --- Finalizing ---
    echo # Add newline for clarity
    if [ "$failed_installers" -eq 0 ]; then
        info "🎉🎉🎉 Dotfiles synchronization and setup completed successfully! 🎉🎉🎉"
    else
        warn "⚠️⚠️⚠️ Dotfiles synchronization completed, but $failed_installers installer(s) failed. Please review the logs. ⚠️⚠️⚠️"
    fi
    info "================================================================"

}

# --- Execute Main Function ---
main "$@"
