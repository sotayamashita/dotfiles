#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: detect dependency changes in package manifests and
# instruct Claude to run the install command through sfw.
# Exit 2 = send feedback to Claude. Exit 0 = no action.

if ! command -v jq &>/dev/null; then
  echo "Hook error: jq is required but not found" >&2
  exit 2
fi

input="$(cat)"
readonly input

tool_name="$(echo "${input}" | jq -r '.tool_name // empty')"
readonly tool_name

# Only check Edit and Write tools.
if [[ "${tool_name}" != "Edit" && "${tool_name}" != "Write" ]]; then
  exit 0
fi

file_path="$(echo "${input}" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')"
readonly file_path

case "$(basename "${file_path}")" in
  package.json)
    echo "Dependency change detected in ${file_path}. Run 'sfw npm install' or 'sfw pnpm install' to install with supply chain protection." >&2
    exit 2
    ;;
  pnpm-workspace.yaml)
    echo "Dependency change detected in ${file_path}. Run 'sfw pnpm install' to install with supply chain protection." >&2
    exit 2
    ;;
  Cargo.toml)
    echo "Dependency change detected in ${file_path}. Run 'sfw cargo build' to fetch dependencies with supply chain protection." >&2
    exit 2
    ;;
  pyproject.toml | requirements*.txt)
    echo "Dependency change detected in ${file_path}. Run 'sfw uv add <pkg>' or 'sfw uv sync' to install with supply chain protection." >&2
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
