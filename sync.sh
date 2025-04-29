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
