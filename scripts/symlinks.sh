#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utility.sh using the script directory as base
source "${SCRIPT_DIR}/utility.sh"

# Helper function: Create symbolic links
create_symlink() {
    local source="$1"
    local target="$2"
    
    # Convert to absolute paths
    source="$(realpath "$source")"
    
    # Handle target path without -m option
    if [[ "$target" = /* ]]; then
        # Target is already absolute
        target="$target"
    else
        # Convert relative to absolute
        target="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)/$(basename "$target")"
    fi
    
    # Check if source exists
    if [ ! -e "$source" ]; then
        error "Source file does not exist, $source"
        return 1
    fi
    
    # Check if we have write permission to target directory
    local target_dir="$(dirname "$target")"
    if [ ! -w "$target_dir" ]; then
        error "No write permission to target directory, $target_dir"
        return 1
    fi
    
    # Check if target exists (with more detailed checks)
    debug "Checking target, $target"
    if [ -e "$target" ] || [ -L "$target" ]; then  # Check both existence and if it's a symlink
        debug "File type for $target:"
        # ls -la "$target"
        
        if [ -L "$target" ]; then
            info "Updating existing symlink: $target"
            rm "$target" || {
                error "Failed to remove existing symlink, $target (errno=$?)" >&2
                ls -la "$target" >&2
                return 1
            }
        else
            local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
            info "Creating backup: $backup"
            mv -v "$target" "$backup" || {
                error "Failed to create backup (errno=$?)" >&2
                ls -la "$target" >&2
                return 1
            }
        fi
    else
        debug "Target does not exist or is broken symlink"
    fi
    
    # Create symlink
    info "Creating new symlink: $source -> $target"
    ln -s "$source" "$target" || {
        error "Failed to create symlink (errno=$?)" >&2
        return 1
    }
    info "Successfully created symlink: $source -> $target"
}

info "Starting symlink creation..."

# Create symlinks for .config directory
if [ -d ".config" ]; then
    info "--- Processing .config files ---"
    for file in .config/*; do
        if [ -e "$file" ]; then
            create_symlink "$file" "$HOME/.config/$(basename "$file")"
        fi
    done
fi

# Create symlinks for dotfiles in root directory
info "--- Processing dotfiles ---"
dotfiles=(
    .Brewfile
    .gitattributes.global
    .gitconfig
    .gitconfig.alias
    .gitconfig.delta
    .gitconfig.user
    .gitignore.global
)

for file in "${dotfiles[@]}"; do
    if [ -e "$file" ]; then
        create_symlink "$file" "$HOME/$file"
    fi
done

info "✨ Symlink creation completed"
