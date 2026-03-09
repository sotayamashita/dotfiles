#!/bin/bash
# Git branch and dirty state detection

get_git_info() {
    local cwd="$1"
    local branch=""
    local dirty=""

    local status_output
    status_output=$(git -C "$cwd" status --porcelain -b 2>/dev/null) || { echo ""; return; }

    # First line: ## branch...tracking
    branch=$(echo "$status_output" | head -1 | sed 's/^## //; s/\.\.\..*//; s/No commits yet on //')
    # Any lines after the header indicate dirty state
    if echo "$status_output" | grep -qv '^##'; then
        dirty="*"
    fi

    echo "$branch $dirty"
}
