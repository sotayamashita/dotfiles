# ------------------------------
# Basic Shell Commands
# ------------------------------
alias g="git"
alias c="clear"
alias h="history"
alias v="vim"

# ------------------------------
# Navigation Shortcuts
# ------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Project directories
alias prj="cd ~/Projects"
alias icloud="cd ~/Library/Mobile\ Documents/com~apple~CloudDocs"

# ------------------------------
# Modern CLI Tools
# ------------------------------

# Function to check if command exists
function has_command
    type -q $argv[1]
end

# File and directory operations
# https://github.com/eza-community/eza
if has_command eza
    alias ls="eza -al -hg --icons --color=always --group-directories-first"
    alias ll="eza -l -hg --icons --color=always --group-directories-first"
    alias tree="eza --tree --icons --color=always"
end

# File viewing
# https://github.com/sharkdp/bat
if has_command bat
    alias cat="bat --style=header,grid --paging=never"
    alias less="bat --style=plain --paging=never"
end

# System monitoring
# https://github.com/ClementTsang/bottom
if has_command btm
    alias top="btm"
    alias htop="btm"
end

# Process management
# https://github.com/dalance/procs
if has_command procs
    alias ps="procs"
end

# Network utilities
# https://github.com/denilsonsa/prettyping
if has_command prettyping
    alias ping="prettyping --nolegend"
end

# Help
# https://github.com/tealdeer-rs/tealdeer
if has_command help
    alias help="tldr"
end

# Claude Code
if has_command $HOME/.claude/local/claude
    alias claude="$HOME/.claude/local/claude"
end
