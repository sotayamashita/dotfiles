#!/bin/bash
# API usage fetch, caching, and rate limit display
# Depends on: colors.sh, oauth.sh

build_rate_lines() {
    local input="$1"

    # Fetch usage data (cached)
    local cache_file="/tmp/claude/statusline-usage-cache.json"
    local cache_max_age=60
    mkdir -p /tmp/claude

    local needs_refresh=true
    local usage_data=""

    if [ -f "$cache_file" ]; then
        local cache_mtime now cache_age
        cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
        now=$(date +%s)
        cache_age=$(( now - cache_mtime ))
        if [ "$cache_age" -lt "$cache_max_age" ]; then
            needs_refresh=false
            usage_data=$(cat "$cache_file" 2>/dev/null)
        fi
    fi

    if $needs_refresh; then
        local token
        token=$(get_oauth_token)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            local response
            response=$(curl -s --max-time 5 \
                -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $token" \
                -H "anthropic-beta: oauth-2025-04-20" \
                -H "User-Agent: claude-code/2.1.34" \
                "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
            if [ -n "$response" ] && echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
                usage_data="$response"
                echo "$response" > "$cache_file"
            fi
        fi
        if [ -z "$usage_data" ] && [ -f "$cache_file" ]; then
            usage_data=$(cat "$cache_file" 2>/dev/null)
        fi
    fi

    # Rate limit lines
    local rate_lines=""

    if [ -n "$usage_data" ] && echo "$usage_data" | jq -e . >/dev/null 2>&1; then
        local bar_width=10

        local five_hour_pct five_hour_reset_iso five_hour_reset five_hour_bar five_hour_pct_color five_hour_pct_fmt
        five_hour_pct=$(echo "$usage_data" | jq -r '.five_hour.utilization // 0' | awk '{printf "%.0f", $1}')
        five_hour_reset_iso=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty')
        five_hour_reset=$(format_reset_time "$five_hour_reset_iso" "time")
        five_hour_bar=$(build_bar "$five_hour_pct" "$bar_width")
        five_hour_pct_color=$(color_for_pct "$five_hour_pct")
        five_hour_pct_fmt=$(printf "%3d" "$five_hour_pct")

        rate_lines+="${white}current${reset} ${five_hour_bar} ${five_hour_pct_color}${five_hour_pct_fmt}%${reset} ${dim}⟳${reset} ${white}${five_hour_reset}${reset}"

        local seven_day_pct seven_day_reset_iso seven_day_reset seven_day_bar seven_day_pct_color seven_day_pct_fmt
        seven_day_pct=$(echo "$usage_data" | jq -r '.seven_day.utilization // 0' | awk '{printf "%.0f", $1}')
        seven_day_reset_iso=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty')
        seven_day_reset=$(format_reset_time "$seven_day_reset_iso" "datetime")
        seven_day_bar=$(build_bar "$seven_day_pct" "$bar_width")
        seven_day_pct_color=$(color_for_pct "$seven_day_pct")
        seven_day_pct_fmt=$(printf "%3d" "$seven_day_pct")

        rate_lines+="\n${white}weekly${reset}  ${seven_day_bar} ${seven_day_pct_color}${seven_day_pct_fmt}%${reset} ${dim}⟳${reset} ${white}${seven_day_reset}${reset}"

        local extra_enabled
        extra_enabled=$(echo "$usage_data" | jq -r '.extra_usage.is_enabled // false')
        if [ "$extra_enabled" = "true" ]; then
            local extra_pct extra_used extra_limit extra_bar extra_pct_color
            extra_pct=$(echo "$usage_data" | jq -r '.extra_usage.utilization // 0' | awk '{printf "%.0f", $1}')
            extra_used=$(echo "$usage_data" | jq -r '.extra_usage.used_credits // 0' | awk '{printf "%.2f", $1/100}')
            extra_limit=$(echo "$usage_data" | jq -r '.extra_usage.monthly_limit // 0' | awk '{printf "%.2f", $1/100}')
            extra_bar=$(build_bar "$extra_pct" "$bar_width")
            extra_pct_color=$(color_for_pct "$extra_pct")

            local extra_reset
            extra_reset=$(date -v+1m -v1d +"%b %-d" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            if [ -z "$extra_reset" ]; then
                extra_reset=$(date -d "$(date +%Y-%m-01) +1 month" +"%b %-d" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            fi

            local extra_col="${white}extra${reset}   ${extra_bar} ${extra_pct_color}\$${extra_used}${dim}/${reset}${white}\$${extra_limit}${reset}"
            local extra_reset_line="${dim}resets ${reset}${white}${extra_reset}${reset}"
            rate_lines+="\n${extra_col}"
            rate_lines+="\n${extra_reset_line}"
        fi
    fi

    [ -n "$rate_lines" ] && printf "%b" "$rate_lines"
}
