# API usage fetch, caching, and rate limit display
# Depends on: colors.sh, oauth.sh

# Formats a single rate-limit period line.
# Arguments:
#   $1 - label (e.g. "current", "weekly ")
#   $2 - utilization percentage
#   $3 - ISO reset timestamp
#   $4 - reset time style ("time" or "datetime")
#   $5 - bar width
# Outputs:
#   Formatted rate line to stdout
_format_rate_period() {
  local label="$1" pct="$2" reset_iso="$3" reset_style="$4" bar_width="$5"

  local reset_str
  reset_str=$(format_reset_time "${reset_iso}" "${reset_style}")
  local bar
  bar=$(build_bar "${pct}" "${bar_width}")
  local pct_color
  pct_color=$(color_for_pct "${pct}")
  local pct_fmt
  pct_fmt=$(printf "%3d" "${pct}")

  printf "%b" "${WHITE}${label}${RESET} ${bar} ${pct_color}${pct_fmt}%${RESET} ${DIM}⟳${RESET} ${WHITE}${reset_str}${RESET}"
}

# Builds the rate-limit display lines.
# Fetches usage data from the API (with caching) and formats it.
# Arguments:
#   $1 - JSON input from Claude Code (unused, reserved)
# Outputs:
#   Formatted rate-limit lines to stdout
build_rate_lines() {
  local input="$1"

  # Fetch usage data (cached)
  local cache_file="/tmp/claude/statusline-usage-cache.json"
  local cache_max_age=60
  mkdir -p /tmp/claude

  local needs_refresh=true
  local usage_data=""

  if [[ -f "${cache_file}" ]]; then
    local cache_mtime now cache_age
    cache_mtime=$(stat -c %Y "${cache_file}" 2>/dev/null \
      || stat -f %m "${cache_file}" 2>/dev/null)
    now=$(date +%s)
    cache_age=$(( now - cache_mtime ))
    if (( cache_age < cache_max_age )); then
      needs_refresh=false
      usage_data=$(cat "${cache_file}" 2>/dev/null)
    fi
  fi

  if ${needs_refresh}; then
    local token
    token=$(get_oauth_token)
    if [[ -n "${token}" && "${token}" != "null" ]]; then
      local response
      response=$(curl -s --max-time 5 \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${token}" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "User-Agent: claude-code/2.1.34" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
      if [[ -n "${response}" ]] \
        && echo "${response}" | jq -e '.five_hour' >/dev/null 2>&1; then
        usage_data="${response}"
        echo "${response}" > "${cache_file}"
      fi
    fi
    if [[ -z "${usage_data}" && -f "${cache_file}" ]]; then
      usage_data=$(cat "${cache_file}" 2>/dev/null)
    fi
  fi

  [[ -z "${usage_data}" ]] && return

  # Extract all usage fields in a single jq call
  local jq_out
  jq_out=$(echo "${usage_data}" | jq -r '[
    (.five_hour.utilization // 0 | tostring),
    (.five_hour.resets_at // ""),
    (.seven_day.utilization // 0 | tostring),
    (.seven_day.resets_at // ""),
    (.extra_usage.is_enabled // false | tostring),
    (.extra_usage.utilization // 0 | tostring),
    (.extra_usage.used_credits // 0 | tostring),
    (.extra_usage.monthly_limit // 0 | tostring)
  ] | join("\t")' 2>/dev/null) || return

  local fh_util fh_reset sd_util sd_reset extra_enabled extra_util extra_used extra_limit
  IFS=$'\t' read -r fh_util fh_reset sd_util sd_reset \
    extra_enabled extra_util extra_used extra_limit <<< "${jq_out}"

  local bar_width=10
  local fh_pct sd_pct
  fh_pct=$(awk "BEGIN {printf \"%.0f\", ${fh_util}}")
  sd_pct=$(awk "BEGIN {printf \"%.0f\", ${sd_util}}")

  local rate_lines=""
  rate_lines+=$(_format_rate_period "current" "${fh_pct}" "${fh_reset}" "time" "${bar_width}")
  rate_lines+="\n"
  rate_lines+=$(_format_rate_period "weekly " "${sd_pct}" "${sd_reset}" "datetime" "${bar_width}")

  if [[ "${extra_enabled}" == "true" ]]; then
    local extra_pct extra_used_fmt extra_limit_fmt extra_bar extra_pct_color
    extra_pct=$(awk "BEGIN {printf \"%.0f\", ${extra_util}}")
    extra_used_fmt=$(awk "BEGIN {printf \"%.2f\", ${extra_used} / 100}")
    extra_limit_fmt=$(awk "BEGIN {printf \"%.2f\", ${extra_limit} / 100}")
    extra_bar=$(build_bar "${extra_pct}" "${bar_width}")
    extra_pct_color=$(color_for_pct "${extra_pct}")

    local extra_reset
    extra_reset=$(LC_ALL=C date -v+1m -v1d +"${DATE_FMT_DATE}" 2>/dev/null)
    if [[ -z "${extra_reset}" ]]; then
      extra_reset=$(LC_ALL=C date -d "$(date +%Y-%m-01) +1 month" +"${DATE_FMT_DATE}" 2>/dev/null)
    fi

    rate_lines+="\n${WHITE}extra${RESET}   ${extra_bar} ${extra_pct_color}\$${extra_used_fmt}${DIM}/${RESET}${WHITE}\$${extra_limit_fmt}${RESET}"
    rate_lines+="\n${DIM}resets ${RESET}${WHITE}${extra_reset}${RESET}"
  fi

  printf "%b" "${rate_lines}"
}
