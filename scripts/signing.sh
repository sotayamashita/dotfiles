#!/usr/bin/env bash

set -euo pipefail

# Check if ~/.gitconfig.signing exists
if [ -f ~/.gitconfig.signing ]; then
    echo "~/.gitconfig.signing already exists"
    exit 1
fi

# Check if 1Password CLI is installed
if ! command -v op &> /dev/null; then
    echo "Error: 1Password CLI is not installed"
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
echo "--- Creating .gitconfig.signing file ---"
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

echo "✨ Git signing configuration created"
