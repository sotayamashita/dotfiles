# Color definitions and common helper functions

# ── Colors ──────────────────────────────────────────────
readonly BLUE='\033[38;2;0;153;255m'
readonly ORANGE='\033[38;2;255;176;85m'
readonly GREEN='\033[38;2;0;175;80m'
readonly CYAN='\033[38;2;86;182;194m'
readonly RED='\033[38;2;255;85;85m'
readonly YELLOW='\033[38;2;230;200;0m'
readonly WHITE='\033[38;2;220;220;220m'
readonly MAGENTA='\033[38;2;180;140;255m'
readonly DIM='\033[2m'
readonly RESET='\033[0m'

readonly SEP=" ${DIM}│${RESET} "

# ── Date formats ────────────────────────────────────────
readonly DATE_FMT_TIME="%H:%M"              # e.g. "15:00"
readonly DATE_FMT_DATETIME="%B %-d, %H:%M"  # e.g. "March 13, 12:00"
readonly DATE_FMT_DATE="%B %-d"             # e.g. "April 1"

# ── Helpers ─────────────────────────────────────────────

# Formats a token count into a human-readable string.
# Arguments:
#   $1 - token count (integer)
# Outputs:
#   Formatted string to stdout (e.g. "1.2m", "50k", "999")
format_tokens() {
  local num="$1"

  if (( num >= 1000000 )); then
    awk "BEGIN {printf \"%.1fm\", ${num} / 1000000}"
  elif (( num >= 1000 )); then
    awk "BEGIN {printf \"%.0fk\", ${num} / 1000}"
  else
    printf "%d" "${num}"
  fi
}

# Returns the ANSI color code for a given percentage.
# Arguments:
#   $1 - percentage (integer 0-100)
# Outputs:
#   ANSI color escape to stdout
color_for_pct() {
  local pct="$1"

  if (( pct >= 90 )); then
    printf "${RED}"
  elif (( pct >= 70 )); then
    printf "${YELLOW}"
  elif (( pct >= 50 )); then
    printf "${ORANGE}"
  else
    printf "${GREEN}"
  fi
}

# Builds a progress bar string with filled/empty indicators.
# Arguments:
#   $1 - percentage (integer 0-100)
#   $2 - bar width in characters
# Outputs:
#   Colored progress bar string to stdout
build_bar() {
  local pct="$1"
  local width="$2"

  (( pct < 0 )) && pct=0
  (( pct > 100 )) && pct=100

  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local bar_color
  bar_color=$(color_for_pct "${pct}")

  local filled_str="" empty_str=""
  local i
  for (( i = 0; i < filled; i++ )); do filled_str+="●"; done
  for (( i = 0; i < empty; i++ )); do empty_str+="○"; done

  printf "${bar_color}${filled_str}${DIM}${empty_str}${RESET}"
}

# Converts an ISO 8601 timestamp to a Unix epoch.
# Tries GNU date first, then falls back to BSD date.
# Arguments:
#   $1 - ISO 8601 timestamp string
# Outputs:
#   Unix epoch (integer) to stdout
# Returns:
#   0 on success, 1 on failure
iso_to_epoch() {
  local iso_str="$1"

  # Try GNU date first
  local epoch
  epoch=$(date -d "${iso_str}" +%s 2>/dev/null)
  if [[ -n "${epoch}" ]]; then
    echo "${epoch}"
    return 0
  fi

  # Fall back to BSD date
  local stripped="${iso_str%%.*}"
  stripped="${stripped%%Z}"
  stripped="${stripped%%+*}"
  stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"

  if [[ "${iso_str}" == *"Z"* ]] \
    || [[ "${iso_str}" == *"+00:00"* ]] \
    || [[ "${iso_str}" == *"-00:00"* ]]; then
    epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "${stripped}" +%s 2>/dev/null)
  else
    epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${stripped}" +%s 2>/dev/null)
  fi

  if [[ -n "${epoch}" ]]; then
    echo "${epoch}"
    return 0
  fi

  return 1
}

# Formats an ISO 8601 reset time for display.
# Arguments:
#   $1 - ISO 8601 timestamp string
#   $2 - style: "time", "datetime", or "" (date only)
# Outputs:
#   Formatted date string to stdout
format_reset_time() {
  local iso_str="$1"
  local style="$2"

  [[ -z "${iso_str}" || "${iso_str}" == "null" ]] && return

  local epoch
  epoch=$(iso_to_epoch "${iso_str}")
  [[ -z "${epoch}" ]] && return

  case "${style}" in
    time)
      LC_ALL=C date -j -r "${epoch}" +"${DATE_FMT_TIME}" 2>/dev/null \
        || LC_ALL=C date -d "@${epoch}" +"${DATE_FMT_TIME}" 2>/dev/null
      ;;
    datetime)
      LC_ALL=C date -j -r "${epoch}" +"${DATE_FMT_DATETIME}" 2>/dev/null \
        || LC_ALL=C date -d "@${epoch}" +"${DATE_FMT_DATETIME}" 2>/dev/null
      ;;
    *)
      LC_ALL=C date -j -r "${epoch}" +"${DATE_FMT_DATE}" 2>/dev/null \
        || LC_ALL=C date -d "@${epoch}" +"${DATE_FMT_DATE}" 2>/dev/null
      ;;
  esac
}
