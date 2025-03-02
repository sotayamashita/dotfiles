#!/usr/bin/env bash
# Tips:
# Get the list of extension
# `cursor --list-extensions path/to/dotfiles/.vscode/extension.txt`

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utils.sh using the script directory as base
source "${SCRIPT_DIR}/../lib/utils.sh"

# Path to the extensions.txt file
EXTENSIONS_FILE="${DOTFILES_FINAL_DIR}/.vscode/extension.txt"

# Check if the extensions file exists
if [ ! -f "$EXTENSIONS_FILE" ]; then
    error "Extensions file not found at $EXTENSIONS_FILE"
    exit 1
fi

info "--- Installing VSCode Extensions ---"

# Check if cursor command is available
if ! command -v cursor &>/dev/null; then
    error "Cursor command not found. Please install Cursor first."
    exit 1
fi

# Read the extensions file and install each extension
while IFS= read -r extension || [ -n "$extension" ]; do
    # Skip empty lines or comments
    [[ -z "$extension" || "$extension" =~ ^# ]] && continue
    
    info "Installing extension: $extension"
    cursor --install-extension "$extension"
done < "$EXTENSIONS_FILE"

info "✨ VSCode extensions installed successfully!" 
