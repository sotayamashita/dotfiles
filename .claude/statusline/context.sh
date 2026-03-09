#!/bin/bash
# JSON extraction, session time, and Line 1 assembly
# Depends on: colors.sh, git.sh

build_line1() {
    local input="$1"

    # Extract all JSON fields in a single jq call
    local jq_out
    jq_out=$(echo "$input" | jq -r '[
        (.model.display_name // "Claude"),
        (.context_window.context_window_size // 200000 | tostring),
        (.context_window.current_usage.input_tokens // 0 | tostring),
        (.context_window.current_usage.cache_creation_input_tokens // 0 | tostring),
        (.context_window.current_usage.cache_read_input_tokens // 0 | tostring),
        (.cwd // ""),
        (.session.start_time // "")
    ] | join("\t")')

    local model_name size input_tokens cache_create cache_read cwd session_start
    IFS=$'\t' read -r model_name size input_tokens cache_create cache_read cwd session_start <<< "$jq_out"

    [ "$size" -eq 0 ] 2>/dev/null && size=200000
    local current=$(( input_tokens + cache_create + cache_read ))

    local pct_left
    if [ "$size" -gt 0 ]; then
        pct_left=$(( 100 - current * 100 / size ))
    else
        pct_left=100
    fi

    # Thinking mode
    local thinking_on=false
    local settings_path
    settings_path="$(dirname "${BASH_SOURCE[0]}")/../settings.json"
    if [ -f "$settings_path" ]; then
        local thinking_val
        thinking_val=$(jq -r '.alwaysThinkingEnabled // false' "$settings_path" 2>/dev/null)
        [ "$thinking_val" = "true" ] && thinking_on=true
    fi

    # Directory and git info
    local pct_color
    pct_color=$(color_for_pct "$(( 100 - pct_left ))")
    [ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd=$(pwd)
    local dirname
    dirname=$(basename "$cwd")

    local git_info git_branch git_dirty
    git_info=$(get_git_info "$cwd")
    git_branch=$(echo "$git_info" | awk '{print $1}')
    git_dirty=$(echo "$git_info" | awk '{print $2}')

    # Session duration
    local session_duration=""
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
