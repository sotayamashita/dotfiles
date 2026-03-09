#!/bin/bash
# Git branch and dirty state detection

get_git_info() {
    local cwd="$1"
    local branch=""
    local dirty=""

    if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
        if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
            dirty="*"
        fi
    fi

    echo "$branch $dirty"
}
