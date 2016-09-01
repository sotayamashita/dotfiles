# Suppress intro message
#
set -U fish_greeting ""

# Files
#
source ~/.config/fish/alias.fish
source ~/.config/fish/path.fish

# Gitconfig.user
# Need: create it manually
#
source ~/.secrets

# Load rbenv automatically by appending
#
rbenv init - | source
