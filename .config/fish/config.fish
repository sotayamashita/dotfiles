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
fish_add_path /opt/homebrew/bin

# OpenSSL
# https://www.openssl.org/
fish_add_path /opt/homebrew/opt/openssl@3/bin

# ------------------------------
# Programming Languages & SDKs
# ------------------------------

# Node.js (Volta)
# https://volta.sh/
set -l VOLTA_HOME $HOME/.volta
if test -d $VOLTA_HOME
    fish_add_path $VOLTA_HOME/bin
    volta completions fish | source
end

# Python (pyenv)
# https://github.com/pyenv/pyenv
set -l PYTHON_HOME $HOME/.pyenv
if test -d $PYTHON_HOME
    fish_add_path $PYTHON_HOME/bin
    pyenv init - | source
end

# Ruby (rbenv)
# https://github.com/rbenv/rbenv
set -l RBENV_HOME $HOME/.rbenv
if test -d $RBENV_HOME
    status --is-interactive; and rbenv init - fish | source
end

# Rust
# https://www.rust-lang.org/
set -l CARGO_HOME $HOME/.cargo
if test -d $CARGO_HOME
    fish_add_path $CARGO_HOME/bin
end

# Go
# https://go.dev/doc/install
set -l GO_HOME /usr/local/go
if test -d $GO_HOME
    fish_add_path $GO_HOME/bin
end

# Mojo
# https://docs.modular.com/mojo/manual/get-started/hello-world.html
set -l MODULAR_HOME $HOME/.modular
if test -d $MODULAR_HOME
    fish_add_path $MODULAR_HOME/pkg/packages.modular.com_mojo/bin
end

# Flutter
# https://flutter.dev/
set -l FLUTTER_HOME $HOME/development/flutter
if test -d $FLUTTER_HOME
    fish_add_path $FLUTTER_HOME/bin
end

# ------------------------------
# Development Tools
# ------------------------------

# Windsurf 
# https://codeium.com/windsurf
if test -d $HOME/.codeium/windsurf/bin
    fish_add_path $HOME/.codeium/windsurf/bin
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

# ------------------------------
# Shell Prompt
# ------------------------------
# Starship
# https://starship.rs/
# Note: Must be at the end of the file
starship init fish | source
