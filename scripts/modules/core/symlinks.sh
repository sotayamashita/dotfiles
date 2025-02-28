#!/usr/bin/env bash
# Symlink creation module

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../lib/utils.sh"

# Setup symlinks
setup_symlinks() {
    info "Setting up symlinks..."
    
    # Define files to symlink
    local files=(
        ".gitconfig"
        ".gitconfig.alias"
        ".gitconfig.user"
        ".gitignore.global"
        ".gitattributes.global"
        ".Brewfile"
    )
    
    # Create symlinks
    for file in "${files[@]}"; do
        local source_file="$DOTFILES_FINAL_DIR/$file"
        local target_file="$HOME/$file"
        
        # Skip if source doesn't exist
        if [ ! -f "$source_file" ]; then
            if [ -f "$DOTFILES_HOME_DIR/$file" ]; then
                source_file="$DOTFILES_HOME_DIR/$file"
            else
                warn "Source file does not exist: $source_file"
                continue
            fi
        fi
        
        # Create symlink
        if [ -L "$target_file" ]; then
            info "Symlink already exists: $target_file"
        elif [ -f "$target_file" ]; then
            backup_file "$target_file"
            ln -sf "$source_file" "$target_file"
            info "Created symlink: $target_file -> $source_file"
        else
            ln -sf "$source_file" "$target_file"
            info "Created symlink: $target_file -> $source_file"
        fi
    done
    
    # Create .config directory if it doesn't exist
    ensure_dir_exists "$HOME/.config"
    
    # Symlink config directories
    local config_dirs=(
        "fish"
    )
    
    for dir in "${config_dirs[@]}"; do
        local source_dir="$DOTFILES_FINAL_DIR/.config/$dir"
        local target_dir="$HOME/.config/$dir"
        
        # Skip if source doesn't exist
        if [ ! -d "$source_dir" ]; then
            if [ -d "$DOTFILES_HOME_DIR/.config/$dir" ]; then
                source_dir="$DOTFILES_HOME_DIR/.config/$dir"
            else
                warn "Source directory does not exist: $source_dir"
                continue
            fi
        fi
        
        # Create symlink
        if [ -L "$target_dir" ]; then
            info "Symlink already exists: $target_dir"
        elif [ -d "$target_dir" ]; then
            backup_dir "$target_dir"
            ln -sf "$source_dir" "$target_dir"
            info "Created symlink: $target_dir -> $source_dir"
        else
            ln -sf "$source_dir" "$target_dir"
            info "Created symlink: $target_dir -> $source_dir"
        fi
    done
    
    info "✅ Symlinks created"
}

# Run the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_symlinks
fi 