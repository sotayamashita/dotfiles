#!/usr/bin/env bash
#
# Symlink management script for dotfiles
# Usage: symlink.sh [--dry-run]

set -euo pipefail

#######################################
# Constants
#######################################
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly CONFIG_FILE="${DOTFILES_DIR}/.symlinks"
readonly TARGET_DIR="${HOME}"

#######################################
# Globals
#######################################
DRY_RUN=false

#######################################
# Log functions
#######################################
log() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1" >&2; }
err() { echo "[ERROR] $1" >&2; exit 1; }

#######################################
# Expand a glob pattern to matching files.
# Arguments:
#   base_dir - Directory to search in
#   pattern  - Glob pattern to expand
# Outputs:
#   Writes matching file paths to stdout
#######################################
expand_pattern() {
  local base_dir="$1"
  local pattern="$2"

  shopt -s globstar nullglob dotglob
  pushd "${base_dir}" > /dev/null
  for file in ${pattern}; do
    [[ -f "${file}" ]] && echo "${file}"
  done
  popd > /dev/null
  shopt -u globstar nullglob dotglob
}

#######################################
# Get files matching patterns from config.
# Processes include patterns and ! exclude patterns.
# Arguments:
#   config_file - Path to .symlinks config
#   base_dir    - Base directory for pattern matching
# Outputs:
#   Writes matching file paths to stdout (sorted)
#######################################
get_matching_files() {
  local config_file="$1"
  local base_dir="$2"
  local -A included_files=()

  while IFS= read -r line || [[ -n "${line}" ]]; do
    # Trim whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "${line}" || "${line}" == \#* ]] && continue

    if [[ "${line}" == !* ]]; then
      # Exclude pattern
      local pattern="${line#!}"
      while IFS= read -r file; do
        unset "included_files[${file}]"
      done < <(expand_pattern "${base_dir}" "${pattern}")
    else
      # Include pattern
      while IFS= read -r file; do
        included_files["${file}"]=1
      done < <(expand_pattern "${base_dir}" "${line}")
    fi
  done < "${config_file}"

  printf '%s\n' "${!included_files[@]}" | sort
}

#######################################
# Create a symlink for a single file.
# Skips if correct symlink exists. In dry-run mode,
# only logs what would be done.
# Arguments:
#   source - Source file path (in dotfiles)
#   target - Target path (in $HOME)
#######################################
create_symlink() {
  local source="$1"
  local target="$2"
  local target_dir
  target_dir="$(dirname "${target}")"

  # Skip if correct symlink exists
  if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" == "${source}" ]]; then
    log "Already linked: ${target}"
    return 0
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    if [[ -e "${target}" || -L "${target}" ]]; then
      log "[DRY-RUN] Would remove: ${target}"
    fi
    log "[DRY-RUN] Would create: ${target} -> ${source}"
    return 0
  fi

  # Create parent directory if needed
  [[ -d "${target_dir}" ]] || mkdir -p "${target_dir}"

  # Remove existing file/link
  [[ -e "${target}" || -L "${target}" ]] && rm -rf "${target}"

  # Create symlink
  ln -s "${source}" "${target}"
  log "Created: ${target} -> ${source}"
}

#######################################
# Parse command line arguments.
# Globals:
#   DRY_RUN
# Arguments:
#   Command line arguments
#######################################
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      *)
        err "Unknown option: $1"
        ;;
    esac
  done
}

#######################################
# Main entry point.
# Arguments:
#   Command line arguments
#######################################
main() {
  parse_args "$@"

  if [[ ! -f "${CONFIG_FILE}" ]]; then
    err "Config file not found: ${CONFIG_FILE}"
  fi

  log "Dotfiles directory: ${DOTFILES_DIR}"
  log "Target directory: ${TARGET_DIR}"
  log "Config file: ${CONFIG_FILE}"
  [[ "${DRY_RUN}" == true ]] && log "Dry-run mode enabled"

  local files
  mapfile -t files < <(get_matching_files "${CONFIG_FILE}" "${DOTFILES_DIR}")

  if [[ ${#files[@]} -eq 0 ]]; then
    warn "No files matched patterns in ${CONFIG_FILE}"
    return 0
  fi

  log "Found ${#files[@]} files to symlink"

  for file in "${files[@]}"; do
    local source="${DOTFILES_DIR}/${file}"
    local target="${TARGET_DIR}/${file}"
    create_symlink "${source}" "${target}"
  done

  log "Done"
}

main "$@"
