#!/usr/bin/env bash
# Symlink creation module

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/utils.sh"

# Create a symlink for a file
create_file_symlink() {
    local source_file="$1"
    local target_file="$2"
    
    # Ensure all parent directories exist
    local target_dir=$(dirname "$target_file")
    if [ ! -d "$target_dir" ]; then
        info "Creating directory structure: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    if [ -L "$target_file" ]; then
        info "Symlink already exists: $target_file"
    elif [ -f "$target_file" ]; then
        backup_file "$target_file"
        ln -sf "$source_file" "$target_file"
        info "Created symlink for file: $target_file -> $source_file"
    elif [ -d "$target_file" ]; then
        warn "Target is a directory, not a file: $target_file"
    else
        ln -sf "$source_file" "$target_file"
        info "Created symlink for file: $target_file -> $source_file"
    fi
}

# Define target files and directories to symlink
SYMLINK_TARGETS=(
    ".config/fish/config.fish"
    ".config/fish/aliases.fish"
    ".config/starship.toml"
    ".config/ghostty/config"
    ".gitconfig"
    ".gitconfig.alias"
    ".gitconfig.user"
    ".gitconfig.diff-so-fancy"
    ".gitignore.global"
    ".gitattributes.global"
    ".Brewfile"
)

# Setup symlinks
setup_symlinks() {
    info "Setting up symlinks..."
    
    # Find source directory
    local source_dir="$DOTFILES_FINAL_DIR"
    if [ ! -d "$source_dir" ]; then
        if [ -d "$DOTFILES_HOME_DIR" ]; then
            source_dir="$DOTFILES_HOME_DIR"
        else
            warn "Source directory does not exist"
            return 1
        fi
    fi
    
    # Process each target directly
    for target in "${SYMLINK_TARGETS[@]}"; do
        local source_file="$source_dir/$target"
        local target_file="$HOME/$target"
        
        if [ -e "$source_file" ]; then
            create_file_symlink "$source_file" "$target_file"
        else
            warn "Source file does not exist: $source_file"
        fi
    done
    
    info "✅ Symlinks created"
}

# Run the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_symlinks
fi 
