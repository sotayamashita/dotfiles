#!/bin/bash
set -f

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

STATUSLINE_DIR="$(dirname "$0")/statusline"
source "$STATUSLINE_DIR/colors.sh"
source "$STATUSLINE_DIR/git.sh"
source "$STATUSLINE_DIR/oauth.sh"
source "$STATUSLINE_DIR/context.sh"
source "$STATUSLINE_DIR/usage.sh"

line1=$(build_line1 "$input")
rate_lines=$(build_rate_lines "$input")

printf "%b" "$line1"
[ -n "$rate_lines" ] && printf "\n\n%b" "$rate_lines"

exit 0
