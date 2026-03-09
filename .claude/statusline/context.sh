#!/bin/bash
# JSON extraction, session time, and Line 1 assembly
# Depends on: colors.sh, git.sh

build_line1() {
    local input="$1"

    # Extract JSON data
    local model_name
    model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')

    local size
    size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
    [ "$size" -eq 0 ] 2>/dev/null && size=200000

    local input_tokens cache_create cache_read current
    input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
    cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
    cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
    current=$(( input_tokens + cache_create + cache_read ))

    local used_tokens total_tokens pct_used
    used_tokens=$(format_tokens $current)
    total_tokens=$(format_tokens $size)

    local pct_left
    if [ "$size" -gt 0 ]; then
        pct_left=$(( 100 - current * 100 / size ))
    else
        pct_left=100
    fi

    # Thinking mode
    local thinking_on=false
    local settings_path="$HOME/.claude/settings.json"
    if [ -f "$settings_path" ]; then
        local thinking_val
        thinking_val=$(jq -r '.alwaysThinkingEnabled // false' "$settings_path" 2>/dev/null)
        [ "$thinking_val" = "true" ] && thinking_on=true
    fi

    # Directory and git info
    local pct_color
    pct_color=$(color_for_pct "$(( 100 - pct_left ))")
    local cwd
    cwd=$(echo "$input" | jq -r '.cwd // ""')
    [ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd=$(pwd)
    local dirname
    dirname=$(basename "$cwd")

    local git_info git_branch git_dirty
    git_info=$(get_git_info "$cwd")
    git_branch=$(echo "$git_info" | awk '{print $1}')
    git_dirty=$(echo "$git_info" | awk '{print $2}')

    # Session duration
    local session_duration=""
    local session_start
    session_start=$(echo "$input" | jq -r '.session.start_time // empty')
    if [ -n "$session_start" ] && [ "$session_start" != "null" ]; then
        local start_epoch
        start_epoch=$(iso_to_epoch "$session_start")
        if [ -n "$start_epoch" ]; then
            local now_epoch elapsed
            now_epoch=$(date +%s)
            elapsed=$(( now_epoch - start_epoch ))
            if [ "$elapsed" -ge 3600 ]; then
                session_duration="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m"
            elif [ "$elapsed" -ge 60 ]; then
                session_duration="$(( elapsed / 60 ))m"
            else
                session_duration="${elapsed}s"
            fi
        fi
    fi

    # Build line1
    local line1="${blue}${model_name}${reset}"
    line1+="${sep}"
    line1+="${pct_color}${pct_left}% left${reset}"
    line1+="${sep}"
    line1+="${cyan}${dirname}${reset}"
    if [ -n "$git_branch" ]; then
        line1+=" ${green}(${git_branch}${red}${git_dirty}${green})${reset}"
    fi
    if [ -n "$session_duration" ]; then
        line1+="${sep}"
        line1+="${dim}⏱ ${reset}${white}${session_duration}${reset}"
    fi
    line1+="${sep}"
    if $thinking_on; then
        line1+="${magenta}◐ thinking${reset}"
    else
        line1+="${dim}◑ thinking${reset}"
    fi

    printf "%b" "$line1"
}
