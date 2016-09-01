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

function type_exists
  if type $argv > /dev/null/ 2>&1
    return 0
  end
  return 1
end

# Load rbenv automatically by appending
#
if type_exists 'rbenv'
  status --is-interactive; and . (rbenv init -|psub)
end
