# Suppress intro message
set -U fish_greeting ""

# Don’t clear the screen after quitting a manual page
set -x MANPAGER "less -X"

# Config Fisherman
set fisher_home ~/fisherman
set fisher_config ~/.config/fisherman
source $fisher_home/config.fish

#
source ~/.config/fish/alias.fish
source ~/.config/fish/programming.fish

# Gitconfig.user
source ~/.secrets
