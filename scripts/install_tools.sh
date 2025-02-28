#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utility.sh using the script directory as base
source "${SCRIPT_DIR}/utility.sh"

# Execute installation script for each tool
function run_installer() {
  local installer_path="$1"
  if [ -f "$installer_path" ] && [ -x "$installer_path" ]; then
    info "Running installer: $(basename "$installer_path")"
    "$installer_path"
  else
    error "Installer not found or not executable: $installer_path"
  fi
}

# Run all installers in the installers directory
INSTALLERS_DIR="${SCRIPT_DIR}/../installers"
if [ -d "$INSTALLERS_DIR" ]; then
  info "--- Running custom installers ---"
  
  # Execute each installer
  for installer in "$INSTALLERS_DIR"/*.sh; do
    if [ -f "$installer" ]; then
      run_installer "$installer"
    fi
  done
  
  info "✨ All custom installers completed"
else
  info "No custom installers directory found at $INSTALLERS_DIR"
fi