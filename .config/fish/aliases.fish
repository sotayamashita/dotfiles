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

# Safe delete
# https://github.com/sindresorhus/trash-cli
if has_command trash
    alias rm="trash"
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
    function ccd --description "Claude Code (skip permissions)"
        # Reduce flickering in terminal output
        # See: https://x.com/bcherny/status/2039421575422980329
        command env CLAUDE_CODE_NO_FLICKER=1 claude --dangerously-skip-permissions $argv
    end
end

# Deno
# Supply chain attack mitigation: 7-day cooldown on newly published packages.
# See: https://blog.yossarian.net/2025/11/21/We-should-all-be-using-dependency-cooldowns
if has_command deno
    function deno --wraps=deno --description "Deno with minimum-dependency-age"
        switch $argv[1]
            case install update outdated
                command deno $argv[1] --minimum-dependency-age=P7D $argv[2..]
            case '*'
                command deno $argv
        end
    end
end

# Socket Firewall (sfw)
# Supply chain attack mitigation: intercept package manager network requests
# and block confirmed malware before download.
# https://github.com/SocketDev/sfw-free
if has_command sfw
    function npm --wraps=npm --description "Run npm through Socket Firewall"
        command sfw npm $argv
    end
    function pnpm --wraps=pnpm --description "Run pnpm through Socket Firewall"
        command sfw pnpm $argv
    end
    function pip --wraps=pip --description "Run pip through Socket Firewall"
        command sfw pip $argv
    end
    function uv --wraps=uv --description "Run uv through Socket Firewall"
        command sfw uv $argv
    end
    function cargo --wraps=cargo --description "Run cargo through Socket Firewall"
        command sfw cargo $argv
    end
end

# PDF to Markdown conversion using docling
# https://github.com/docling-project/docling
if has_command mise
    function pdf2md --description "Convert PDF to Markdown using mise"
        mise x -- uvx docling --to md --pipeline vlm --vlm-model granite_docling $argv
    end
end
