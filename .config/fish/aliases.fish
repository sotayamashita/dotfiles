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

# Find
# https://github.com/sharkdp/fd
if has_command fd
    alias find="fd"
end

# Sed
# https://github.com/chmln/sd
if has_command sd
    alias sed="sd"
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
# https://docs.anthropic.com/en/docs/claude-code
if has_command claude
    function claude --description "Claude Code CLI with auto-update"
        if has_command brew
            brew upgrade --cask claude-code 2>/dev/null
        end
        command claude $argv
    end
end

# Codex
# https://github.com/openai/codex
if has_command codex
    function codex --description "Codex CLI with auto-update"
        if has_command brew
            brew upgrade --cask codex 2>/dev/null
        end
        command codex $argv
    end
end

# PDF to Markdown conversion using docling
# https://github.com/docling-project/docling
if has_command mise
    function pdf2md --description "Convert PDF to Markdown using mise"
        mise x -- uvx docling --to md --pipeline vlm --vlm-model granite_docling $argv
    end
end
