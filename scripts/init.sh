#!/usr/bin/env bash

# Store the absolute path of the dotfiles root directory
DOTFILES_ROOT="${HOME}/Projects/dotfiles"
CONFIG_DIR="${DOTFILES_ROOT}/.config"
SYMLINKS_DIR="${DOTFILES_ROOT}/symlinks"

# Clone the repository if it doesn't exist
if [[ ! -e "${DOTFILES_ROOT}" ]]; then
    git clone --depth=1 https://github.com/sotayamashita/dotfiles.git "${DOTFILES_ROOT}"
fi

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install 1Password CLI
if ! command -v op &>/dev/null; then
    brew install --cask 1password-cli
fi

# Create symbolic links
echo "Creating symbolic links..."
for file in "${SYMLINKS_DIR}"/.* "${CONFIG_DIR}"/*; do
    if [ -f "$file" ]; then
        base=$(basename "$file")
        target="${HOME}/${base}"
        if [ -e "$target" ]; then
            echo "Backing up existing $target"
            mv "$target" "${target}.backup"
        fi
        ln -sf "$file" "$target"
        echo "Created symlink for $base"
    fi
done

# Run additional setup scripts
source "${DOTFILES_ROOT}/scripts/brew.sh"

# Optional: Remove apps from the Dock
read -p "Would you like to remove apps from the Dock? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing apps from the Dock..."
    source "${DOTFILES_ROOT}/scripts/clear-dock.sh"
fi

# Optional: Configure macOS settings
read -p "Would you like to configure macOS settings? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Configuring macOS settings..."
    source "${DOTFILES_ROOT}/scripts/macos.sh"
fi

echo "✨ Dotfiles setup completed!" 