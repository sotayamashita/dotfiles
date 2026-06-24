#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: lint Japanese Markdown with textlint
# (preset-ja-technical-writing) after an Edit, MultiEdit, or Write.
#
# Scope: only *.md files whose body contains Japanese characters, so the rule
# set never fires on English-only Markdown in unrelated repositories.
#
# Exit 2 = send the textlint report to Claude as feedback. Exit 0 = no action.

# Ensure Homebrew and mise-managed runtimes (rg, node) are reachable regardless
# of the environment Claude Code launched the hook in.
PATH="/opt/homebrew/bin:${HOME}/.local/share/mise/shims:${PATH}"
export PATH

if ! command -v jq &>/dev/null; then
  echo "Hook error: jq is required but not found" >&2
  exit 2
fi

input="$(cat)"
readonly input

tool_name="$(echo "${input}" | jq -r '.tool_name // empty')"
readonly tool_name

# Only react to file-editing tools.
case "${tool_name}" in
Edit | MultiEdit | Write) ;;
*) exit 0 ;;
esac

file_path="$(echo "${input}" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')"

# Only Markdown files that still exist on disk.
if [[ "${file_path}" != *.md ]] || [[ ! -f "${file_path}" ]]; then
  exit 0
fi

if [[ "${file_path}" != /* ]]; then
  file_path="${PWD}/${file_path}"
fi
readonly file_path

# Skip Markdown without Japanese characters (hiragana, katakana, kanji).
if ! rg -q '[\p{Hiragana}\p{Katakana}\p{Han}]' "${file_path}"; then
  exit 0
fi

# Resolve the repo-local textlint workspace via this hook's symlink target.
src="${BASH_SOURCE[0]}"
if [[ -L "${src}" ]]; then
  src="$(readlink "${src}")"
fi
hook_dir="$(cd "$(dirname "${src}")" && pwd)"
repo_root="$(cd "${hook_dir}/../.." && pwd)"
textlint_dir="${repo_root}/tools/textlint"
textlint_bin="${textlint_dir}/node_modules/.bin/textlint"
readonly src hook_dir repo_root textlint_dir textlint_bin

# Dependencies not installed yet — guide the user, but do not block the edit.
if [[ ! -x "${textlint_bin}" ]]; then
  echo "textlint not installed. Run: sfw pnpm -C ${textlint_dir} install" >&2
  exit 0
fi

# Run textlint from the workspace so it resolves the preset module. A non-zero
# exit means it reported problems worth surfacing to Claude.
if report="$(cd "${textlint_dir}" && "${textlint_bin}" -c .textlintrc.json "${file_path}" 2>&1)"; then
  exit 0
fi

{
  echo "textlint (ja-technical-writing) reported issues in ${file_path}:"
  echo
  echo "${report}"
  echo
  echo "Next: edit ${file_path} to resolve each finding above, following the"
  echo "ja-technical-writing rules (concise sentences, no dearu/desumasu mix,"
  echo "no doubled particles, etc.). This hook re-runs automatically after the"
  echo "edit, so iterate until it passes. If a finding is a genuine false"
  echo "positive, silence that rule in tools/textlint/.textlintrc.json or add a"
  echo "<!-- textlint-disable rule-name --> comment rather than leaving it unaddressed."
} >&2
exit 2
