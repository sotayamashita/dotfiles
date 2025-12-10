# Locale
set -Ux LANG        ja_JP.UTF-8
set -Ux LC_CTYPE    ja_JP.UTF-8
set -Ux LC_MESSAGES ja_JP.UTF-8

# Load aliases
. ~/.config/fish/aliases.fish

# ------------------------------
# Shell Configuration
# ------------------------------
# Disable default greeting message
# https://fishshell.com/docs/current/faq.html#how-do-i-change-the-greeting-message
set -U fish_greeting

# Set XDG_CONFIG_HOME
set -gx XDG_CONFIG_HOME $HOME/.config

# Add local bin to path
fish_add_path $HOME/.local/bin

# ------------------------------
# Package Managers & System Tools
# ------------------------------
# Homebrew
# https://brew.sh/
# Determine Homebrew prefix based on architecture
set -l BREW_PREFIX (uname -m | grep -q arm64; and echo /opt/homebrew; or echo /usr/local)
fish_add_path $BREW_PREFIX/bin

# OpenSSL
# https://www.openssl.org/
fish_add_path $BREW_PREFIX/opt/openssl@3/bin

# ------------------------------
# Programming Languages & SDKs
# ------------------------------
# Node.js (Volta)
# https://volta.sh/
# -> Use mise instead of Volta for Node.js version management

# Python (pyenv)
# https://github.com/pyenv/pyenv
# -> Use mise instead of pyenv for Python version management

# Ruby (rbenv)
# https://github.com/rbenv/rbenv
# -> Use mise instead of pyenv for Python version management

# Rust 
# https://www.rust-lang.org/
# -> Use mise instead of rustup for Rust version management

# Mise
# https://code.claude.com/docs/en/setup
set -gx MISE_QUIET 1
if test -f $HOME/.local/bin/mise
    $HOME/.local/bin/mise activate fish | source
end

# ngrok
# https://ngrok.com/
if command -v ngrok &>/dev/null
    eval (ngrok completion)
end

# Google Cloud SDK
# https://cloud.google.com/sdk/docs/install
if test -f "$HOME/google-cloud-sdk/path.fish.inc"
    . "$HOME/google-cloud-sdk/path.fish.inc"
end

# fnox
# https://fnox.jdx.dev/guide/shell-integration.html#enable-shell-integration
if command -v fnox &>/dev/null
    fnox activate fish | source
end

# ------------------------------
# Shell Prompt
# ------------------------------
# Starship
# https://starship.rs/
# Note: Must be at the end of the file
starship init fish | source
