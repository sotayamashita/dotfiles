#!/usr/bin/env bash

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source utility.sh using the script directory as base
source "${SCRIPT_DIR}/utility.sh"

# Check if ~/.gitconfig.signing exists
if [ -f ~/.gitconfig.signing ]; then
    info "~/.gitconfig.signing already exists so skipping signing configuration"
    exit 1
fi

# Check if 1Password CLI is installed
if ! command -v op &> /dev/null; then
    error "1Password CLI is not installed so install it and try again"
    exit 1
fi

# Ask if user wants to open 1Password
read -p "Do you want to open 1Password? (y/n): " open1Password
if [ "$open1Password" = "y" ]; then
    open -a "1Password"
fi

# Ask for GitHub GPG signing key name in 1Password
read -p "Enter your GitHub GPG signing key name in 1Password: " signingkeyName

# Get GPG signing key from 1Password
PUBLIC_KEY=$(op item get $signingkeyName --fields label=public_key)

# Create .gitconfig.signing file
info "--- Creating .gitconfig.signing file ---"
cat <<EOF > ~/.gitconfig.signing
[user]
  signingkey = $PUBLIC_KEY

[gpg]
  format = ssh

[gpg "ssh"]
  program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"

[commit]
  gpgsign = true
EOF

info "✨ Git signing configuration created"
