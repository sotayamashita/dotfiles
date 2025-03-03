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

# Create a symlink for a directory
create_dir_symlink() {
    local source_dir="$1"
    local target_dir="$2"
    
    if [ -L "$target_dir" ]; then
        info "Symlink already exists: $target_dir"
    elif [ -d "$target_dir" ]; then
        backup_dir "$target_dir"
        ln -sf "$source_dir" "$target_dir"
        info "Created symlink for directory: $target_dir -> $source_dir"
    elif [ -f "$target_dir" ]; then
        warn "Target is a file, not a directory: $target_dir"
    else
        ln -sf "$source_dir" "$target_dir"
        info "Created symlink for directory: $target_dir -> $source_dir"
    fi
}

# Setup symlinks for .config directory contents
setup_config_symlinks() {
    info "Setting up .config symlinks..."
    
    # Create .config directory if it doesn't exist
    ensure_dir_exists "$HOME/.config"
    
    # Find source directory
    local source_config_dir="$DOTFILES_FINAL_DIR/.config"
    if [ ! -d "$source_config_dir" ]; then
        if [ -d "$DOTFILES_HOME_DIR/.config" ]; then
            source_config_dir="$DOTFILES_HOME_DIR/.config"
        else
            warn "Source .config directory does not exist"
            return 1
        fi
    fi
    
    # Process all files and directories in .config
    for source_item in "$source_config_dir"/*; do
        if [ -e "$source_item" ]; then
            local item_name=$(basename "$source_item")
            local target_item="$HOME/.config/$item_name"
            
            # Create appropriate symlink based on item type
            if [ -f "$source_item" ]; then
                create_file_symlink "$source_item" "$target_item"
            elif [ -d "$source_item" ]; then
                create_dir_symlink "$source_item" "$target_item"
            else
                warn "Unknown item type: $source_item"
            fi
        fi
    done
    
    info "✅ .config symlinks created"
}

# Setup symlinks
setup_symlinks() {
    info "Setting up symlinks..."
    
    # Define files to symlink
    local files=("$@")
    
    # Use default files if no arguments provided
    if [ ${#files[@]} -eq 0 ]; then
        files=(
            ".gitconfig"
            ".gitconfig.alias"
            ".gitconfig.user"
            ".gitignore.global"
            ".gitattributes.global"
            ".Brewfile"
        )
    fi
    
    # Create symlinks
    for file in "${files[@]}"; do
        # Skip .config as it will be handled separately
        if [ "$file" = ".config" ]; then
            continue
        fi
        
        local source_file="$DOTFILES_FINAL_DIR/$file"
        local target_file="$HOME/$file"
        
        # Skip if source doesn't exist
        if [ ! -f "$source_file" ] && [ ! -d "$source_file" ]; then
            if [ -f "$DOTFILES_HOME_DIR/$file" ] || [ -d "$DOTFILES_HOME_DIR/$file" ]; then
                source_file="$DOTFILES_HOME_DIR/$file"
            else
                warn "Source file/directory does not exist: $source_file"
                continue
            fi
        fi
        
        # Create appropriate symlink based on file type
        if [ -f "$source_file" ]; then
            create_file_symlink "$source_file" "$target_file"
        elif [ -d "$source_file" ]; then
            create_dir_symlink "$source_file" "$target_file"
        else
            warn "Unknown file type: $source_file"
        fi
    done
    
    # Always process .config directory contents
    setup_config_symlinks
    
    info "✅ Symlinks created"
}

# Run the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_symlinks "$@"
fi 
