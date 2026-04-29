#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: detect dependency changes in package manifests and
# instruct Codex to run the install command through sfw.
# Exit 2 = send feedback to Codex. Exit 0 = no action.

if ! command -v jq &>/dev/null; then
  echo "Hook error: jq is required but not found" >&2
  exit 2
fi

input="$(cat)"
readonly input

tool_name="$(echo "${input}" | jq -r '.tool_name // empty')"
readonly tool_name

check_dependency_manifest() {
  local manifest_path="$1"
  local install_command="$2"

  echo "Dependency change detected in ${manifest_path}. Run ${install_command} to install with supply chain protection." >&2
  exit 2
}

patch_for_file() {
  local target_path="$1"

  awk -v target_path="${target_path}" '
    /^\*\*\* (Add|Update|Delete) File: / {
      active = (substr($0, index($0, ": ") + 2) == target_path)
      next
    }
    /^\*\*\* Move to: / {
      active = (substr($0, index($0, ": ") + 2) == target_path)
      next
    }
    /^\*\*\* End Patch/ {
      active = 0
    }
    active {
      print
    }
  ' <<<"${patch_input}"
}

changed_line_content() {
  sed -nE '/^[+-]/ {
    /^[+]{3}/d
    /^[-]{3}/d
    s/^[+-]//
    p
  }'
}

package_json_dependency_changed() {
  local manifest_path="$1"

  patch_for_file "${manifest_path}" | awk '
    function is_dep_key(line) {
      return line ~ /^  "(dependencies|devDependencies|peerDependencies|optionalDependencies|bundleDependencies|bundledDependencies|overrides|resolutions)":/
    }

    function is_top_level_key(line) {
      return line ~ /^  "[^"]+":/
    }

    function is_changed(line) {
      return line ~ /^[+-]/ && line !~ /^[+-]{3}/
    }

    function is_dependency_version_line(line) {
      return line ~ /^    "[^"]+": "([~^<>=*0-9]|workspace:|file:|link:|portal:|npm:|github:|git\+|https?:)/
    }

    {
      line = $0
      content = line
      sub(/^[ +\-]/, "", content)

      if (is_dep_key(content)) {
        in_dependency_section = 1
        if (is_changed(line)) {
          found = 1
        }
        next
      }

      if (is_top_level_key(content)) {
        in_dependency_section = 0
      }

      if (in_dependency_section && is_changed(line) && content ~ /^    "[^"]+":/) {
        found = 1
      }

      if (is_changed(line) && is_dependency_version_line(content)) {
        found = 1
      }
    }

    END {
      exit found ? 0 : 1
    }
  '
}

cargo_dependency_changed() {
  local manifest_path="$1"

  patch_for_file "${manifest_path}" | awk '
    function is_dependency_section(line) {
      return line ~ /^\[([[:alnum:]_.-]+\.)?(dependencies|dev-dependencies|build-dependencies)\]$/ ||
        line ~ /^\[target\..*\.(dependencies|dev-dependencies|build-dependencies)\]$/
    }

    function is_section(line) {
      return line ~ /^\[[^]]+\]$/
    }

    function is_changed(line) {
      return line ~ /^[+-]/ && line !~ /^[+-]{3}/
    }

    {
      line = $0
      content = line
      sub(/^[ +\-]/, "", content)

      if (is_section(content)) {
        in_dependency_section = is_dependency_section(content)
        if (in_dependency_section && is_changed(line)) {
          found = 1
        }
        next
      }

      if (in_dependency_section && is_changed(line) && content !~ /^[[:space:]]*($|#)/) {
        found = 1
      }
    }

    END {
      exit found ? 0 : 1
    }
  '
}

pyproject_dependency_changed() {
  local manifest_path="$1"

  patch_for_file "${manifest_path}" | awk '
    function is_dependency_section(line) {
      return line ~ /^\[(project\.optional-dependencies|dependency-groups|tool\.uv(\.|])|build-system)\]$/
    }

    function is_section(line) {
      return line ~ /^\[[^]]+\]$/
    }

    function is_changed(line) {
      return line ~ /^[+-]/ && line !~ /^[+-]{3}/
    }

    {
      line = $0
      content = line
      sub(/^[ +\-]/, "", content)

      if (is_section(content)) {
        in_dependency_section = is_dependency_section(content)
        if (in_dependency_section && is_changed(line)) {
          found = 1
        }
        next
      }

      if (content ~ /^(dependencies|optional-dependencies|requires)[[:space:]]*=/) {
        if (is_changed(line)) {
          found = 1
        }
        in_dependency_section = 1
        next
      }

      if (in_dependency_section && is_changed(line) && content !~ /^[[:space:]]*($|#)/) {
        found = 1
      }
    }

    END {
      exit found ? 0 : 1
    }
  '
}

requirements_dependency_changed() {
  local manifest_path="$1"

  patch_for_file "${manifest_path}" | changed_line_content | grep -qEv '^[[:space:]]*($|#)'
}

pnpm_workspace_dependency_changed() {
  local manifest_path="$1"

  patch_for_file "${manifest_path}" | awk '
    function is_catalog_key(line) {
      return line ~ /^(catalog|catalogs):[[:space:]]*$/
    }

    function is_top_level_key(line) {
      return line ~ /^[[:alnum:]_-]+:[[:space:]]*/
    }

    function is_changed(line) {
      return line ~ /^[+-]/ && line !~ /^[+-]{3}/
    }

    {
      line = $0
      content = line
      sub(/^[ +\-]/, "", content)

      if (is_catalog_key(content)) {
        in_catalog = 1
        if (is_changed(line)) {
          found = 1
        }
        next
      }

      if (is_top_level_key(content)) {
        in_catalog = 0
      }

      if (in_catalog && is_changed(line) && content !~ /^[[:space:]]*($|#)/) {
        found = 1
      }
    }

    END {
      exit found ? 0 : 1
    }
  '
}

check_changed_file() {
  local file_path="$1"

  case "$(basename "${file_path}")" in
    package.json)
      if package_json_dependency_changed "${file_path}"; then
        check_dependency_manifest "${file_path}" "'sfw npm install' or 'sfw pnpm install'"
      fi
      ;;
    pnpm-workspace.yaml)
      if pnpm_workspace_dependency_changed "${file_path}"; then
        check_dependency_manifest "${file_path}" "'sfw pnpm install'"
      fi
      ;;
    Cargo.toml)
      if cargo_dependency_changed "${file_path}"; then
        check_dependency_manifest "${file_path}" "'sfw cargo build'"
      fi
      ;;
    pyproject.toml)
      if pyproject_dependency_changed "${file_path}"; then
        check_dependency_manifest "${file_path}" "'sfw uv add <pkg>' or 'sfw uv sync'"
      fi
      ;;
    requirements*.txt)
      if requirements_dependency_changed "${file_path}"; then
        check_dependency_manifest "${file_path}" "'sfw uv add <pkg>' or 'sfw uv sync'"
      fi
      ;;
  esac
}

if [[ "${tool_name}" != "apply_patch" ]]; then
  exit 0
fi

patch_input="$(echo "${input}" | jq -r '.tool_input.command // empty')"
readonly patch_input

while IFS= read -r file_path; do
  [[ -n "${file_path}" ]] || continue
  check_changed_file "${file_path}"
done < <(echo "${patch_input}" | sed -nE 's/^\*\*\* (Add|Update|Delete) File: (.+)$/\2/p')

exit 0
