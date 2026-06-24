#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: lint Japanese Markdown with textlint
# (preset-ja-technical-writing) after Codex edits files with apply_patch.
#
# Scope: only *.md files whose body contains Japanese characters, so the rule
# set never fires on English-only Markdown in unrelated repositories.
#
# Exit 2 = send the textlint report to Codex as feedback. Exit 0 = no action.

# Ensure Homebrew and mise-managed runtimes (rg, node) are reachable regardless
# of the environment Codex launched the hook in.
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

case "${tool_name}" in
apply_patch | Edit | Write) ;;
*) exit 0 ;;
esac

candidate_files() {
  local file_path
  file_path="$(echo "${input}" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')"
  if [[ -n "${file_path}" ]]; then
    printf '%s\n' "${file_path}"
    return
  fi

  echo "${input}" | jq -r '.tool_input.command // empty' | sed -nE '
    s/^\*\*\* (Add|Update) File: (.+)$/\2/p
    s/^\*\*\* Move to: (.+)$/\1/p
  '
}

markdown_targets=()
while IFS= read -r file_path; do
  [[ -n "${file_path}" ]] || continue
  [[ "${file_path}" == *.md ]] || continue
  [[ -f "${file_path}" ]] || continue
  if [[ "${file_path}" = /* ]]; then
    markdown_targets+=("${file_path}")
  else
    markdown_targets+=("${PWD}/${file_path}")
  fi
done < <(candidate_files | sort -u)
readonly markdown_targets

if [[ "${#markdown_targets[@]}" -eq 0 ]]; then
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

# Dependencies not installed yet -- guide the user, but do not block the edit.
if [[ ! -x "${textlint_bin}" ]]; then
  echo "textlint not installed. Run: sfw pnpm -C ${textlint_dir} install" >&2
  exit 0
fi

lint_targets=()
for file_path in "${markdown_targets[@]}"; do
  # Skip Markdown without Japanese characters (hiragana, katakana, kanji).
  if rg -q '[\p{Hiragana}\p{Katakana}\p{Han}]' "${file_path}"; then
    lint_targets+=("${file_path}")
  fi
done
readonly lint_targets

if [[ "${#lint_targets[@]}" -eq 0 ]]; then
  exit 0
fi

# Run textlint from the workspace so it resolves the preset module. A non-zero
# exit means it reported problems worth surfacing to Codex.
if report="$(cd "${textlint_dir}" && "${textlint_bin}" -c .textlintrc.json "${lint_targets[@]}" 2>&1)"; then
  exit 0
fi

{
  echo "textlint (ja-technical-writing) reported issues:"
  echo
  echo "${report}"
  echo
  echo "Next: edit the Markdown files above to resolve each finding, following"
  echo "the ja-technical-writing rules (concise sentences, no dearu/desumasu"
  echo "mix, no doubled particles, etc.). This hook re-runs automatically after"
  echo "the edit, so iterate until it passes. If a finding is a genuine false"
  echo "positive, silence that rule in tools/textlint/.textlintrc.json or add a"
  echo "<!-- textlint-disable rule-name --> comment rather than leaving it unaddressed."
} >&2
exit 2
