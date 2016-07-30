# Suppress intro message
#
set -U fish_greeting ""

# Ensure fisherman and plugins are installed
#
if not test -f $HOME/.config/fish/functions/fisher.fish
  curl -sLo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
  fisher
end

# Files
#
source ~/.config/fish/alias.fish
source ~/.config/fish/path.fish

# Gitconfig.user
# Need: create it manually
#
source ~/.secrets
