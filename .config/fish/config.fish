# Suppress intro message
set -U fish_greeting ""

# Ensure fisherman and plugins are installed
if not test -f $HOME/.config/fish/functions/fisher.fish
  echo "==> Fisherman not found.  Installing."
  # Install fisherman
  curl -sLo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher

  # Confirm version 
  fisher -v
  fin -v

  # Install plguins
  fisher
end

# files
source ~/.config/fish/alias.fish
source ~/.config/fish/programming.fish

# Gitconfig.user
# TODO: You should create it manually
source ~/.secrets
