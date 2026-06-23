# Git branch and dirty state detection

# Gets the current branch name and dirty state for a directory.
# Arguments:
#   $1 - working directory path
# Outputs:
#   "<branch> <dirty>" to stdout, where branch is the branch name (or the
#   short commit SHA when in detached HEAD) and dirty is "*" or empty.
#   Empty output when the directory is not a git work tree.
get_git_info() {
  local cwd="$1"
  local branch="" dirty=""

  # Branch name, or the short commit SHA when in detached HEAD.
  # Both commands fail (branch stays empty) outside a git work tree.
  branch=$(git -C "${cwd}" symbolic-ref --quiet --short HEAD 2>/dev/null) ||
    branch=$(git -C "${cwd}" rev-parse --short HEAD 2>/dev/null) ||
    branch=""
  [[ -z "${branch}" ]] && {
    echo ""
    return
  }

  # Any staged, unstaged, or untracked change marks the tree dirty.
  [[ -n "$(git -C "${cwd}" status --porcelain 2>/dev/null)" ]] && dirty="*"

  echo "${branch} ${dirty}"
}
