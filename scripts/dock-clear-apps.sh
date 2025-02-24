#!/usr/bin/env bash
#
# Remove all applications from the macOS Dock.
# This script cleans up the Dock by removing all application icons.
#
# Usage:
#   ./rm-app-from-dock.sh
#
# This script is useful for:
# - Removing all application icons from the Dock

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utility.sh using the script directory as base
source "${SCRIPT_DIR}/utility.sh"

#######################################
# Remove all application icons from the Dock
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Progress messages to stdout
#######################################
main() {
  info "--- Removing apps from Dock ---"

  # Remove apps from Dock
  defaults write com.apple.dock persistent-apps -array && killall Dock

  info "✨ Apps removed from Dock"
}

main "$@"
