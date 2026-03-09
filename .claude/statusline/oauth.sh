# OAuth token resolution for Claude Code API

# Extracts the OAuth access token from a JSON blob.
# Arguments:
#   $1 - JSON string containing claudeAiOauth credentials
# Outputs:
#   Access token to stdout if found
# Returns:
#   0 if token found, 1 otherwise
_extract_oauth_token() {
  local json="$1"
  [[ -z "${json}" ]] && return 1

  local token
  token=$(echo "${json}" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  if [[ -n "${token}" && "${token}" != "null" ]]; then
    echo "${token}"
    return 0
  fi
  return 1
}

# Resolves an OAuth token from available credential sources.
# Checks in order: env var, macOS Keychain, credentials file, Linux secret-tool.
# Outputs:
#   OAuth token to stdout (empty string if not found)
get_oauth_token() {
  if [[ -n "${CLAUDE_CODE_OAUTH_TOKEN}" ]]; then
    echo "${CLAUDE_CODE_OAUTH_TOKEN}"
    return 0
  fi

  if command -v security >/dev/null 2>&1; then
    local blob
    blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    _extract_oauth_token "${blob}" && return 0
  fi

  local creds_file="${HOME}/.claude/.credentials.json"
  if [[ -f "${creds_file}" ]]; then
    _extract_oauth_token "$(cat "${creds_file}" 2>/dev/null)" && return 0
  fi

  if command -v secret-tool >/dev/null 2>&1; then
    local blob
    blob=$(timeout 2 secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
    _extract_oauth_token "${blob}" && return 0
  fi

  echo ""
}
