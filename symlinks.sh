#!/usr/bin/env bash

set -euo pipefail

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
        echo "Error: Source file does not exist: $source" >&2
        return 1
    fi
    
    # Check if we have write permission to target directory
    local target_dir="$(dirname "$target")"
    if [ ! -w "$target_dir" ]; then
        echo "Error: No write permission to target directory: $target_dir" >&2
        return 1
    fi
    
    # Handle existing target
    if [ -e "$target" ]; then
        if [ -L "$target" ]; then
            echo "Updating existing symlink: $target"
            rm "$target"
        else
            local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
            echo "Creating backup: $backup"
            if ! mv "$target" "$backup"; then
                echo "Error: Failed to create backup" >&2
                return 1
            fi
        fi
    fi
    
    # Create symlink
    if ! ln -s "$source" "$target"; then
        echo "Error: Failed to create symlink" >&2
        return 1
    fi
    echo "Created symlink: $source -> $target"
}

echo "Starting symlink creation..."

# Create symlinks for .config directory
if [ -d ".config" ]; then
    echo "--- Processing .config files ---"
    for file in .config/.*; do
        # Skip . and .. directory entries
        [[ "$(basename "$file")" =~ ^\.\.?$ ]] && continue
        if [ -e "$file" ]; then
            create_symlink "$file" "$HOME/.config/$(basename "$file")"
        fi
    done
    # Also process non-dot files
    for file in .config/*; do
        [[ -e "$file" ]] && create_symlink "$file" "$HOME/.config/$(basename "$file")"
    done
fi

# Create symlinks for symlinks directory
if [ -d "symlinks" ]; then
    echo "--- Processing symlinks files ---"
    for file in symlinks/.*; do
        # Skip . and .. directory entries
        [[ "$(basename "$file")" =~ ^\.\.?$ ]] && continue
        if [ -e "$file" ]; then
            create_symlink "$file" "$HOME/$(basename "$file")"
        fi
    done
    # Also process non-dot files
    for file in symlinks/*; do
        [[ -e "$file" ]] && create_symlink "$file" "$HOME/$(basename "$file")"
    done
fi

echo "✨ Symlink creation completed"
