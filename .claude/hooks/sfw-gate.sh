#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: block bare package manager commands and require sfw wrapper.
# Exit 2 = block with feedback to Claude. Exit 0 = allow.
#
# Limitation: commands prefixed with env/command/sudo or multi-line scripts
# can bypass this string-based gate. This catches direct invocations only.

if ! command -v jq &>/dev/null; then
  echo "Hook error: jq is required but not found" >&2
  exit 2
fi

command_str="$(jq -r '.tool_input.command // empty')"
readonly command_str

if [[ -z "${command_str}" ]]; then
  exit 0
fi

# Already wrapped with sfw — allow.
if [[ "${command_str}" =~ ^[[:space:]]*sfw[[:space:]] ]]; then
  exit 0
fi

# Supported by sfw Free: npm, pnpm, yarn, pip, uv, cargo
if echo "${command_str}" | grep -qE '^\s*(npm|pnpm|yarn)\s+(install|i|add|ci)\b'; then
  echo "Blocked: Use 'sfw' wrapper for supply chain protection. Example: sfw npm install" >&2
  exit 2
fi

if echo "${command_str}" | grep -qE '^\s*pip\s+install\b'; then
  echo "Blocked: Use 'sfw uv add' instead. pip is not allowed (see .claude/rules/python.md)." >&2
  exit 2
fi

if echo "${command_str}" | grep -qE '^\s*uv\s+(pip install|add|sync)\b'; then
  echo "Blocked: Use 'sfw uv' for supply chain protection." >&2
  exit 2
fi

if echo "${command_str}" | grep -qE '^\s*cargo\s+(install|add)\b'; then
  echo "Blocked: Use 'sfw cargo install' for supply chain protection." >&2
  exit 2
fi

exit 0
