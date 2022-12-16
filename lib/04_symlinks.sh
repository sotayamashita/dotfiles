#!/bin/bash

. $(dirname "$0")/helper/logger.sh
. $(dirname "$0")/helper/check.sh

readonly ROOT_ABS_PATH="$(cd "$(dirname "$1")" && pwd)"

main() {
  # Symbolic source and target links
  links=(
    ".config/fish/config.fish:.config/fish/config.fish"
    ".config/git/.gitconfig:.gitconfig"
    ".config/git/.gitconfig.alias:.gitconfig.alias"
    ".config/git/.gitconfig.user:.gitconfig.user"
    ".config/git/.gitconfig.delta:.gitconfig.delta"
    ".config/git/.gitignore.global:.gitignore.global"
    ".config/iterm2/com.googlecode.iterm2.plist:.config/iterm2/com.googlecode.iterm2.plist"
    ".config/starship.toml:.config/starship.toml"
  )

  # Create symbolic a link to a file
  for link in "${links[@]}"; do
    source="${ROOT_ABS_PATH}/${link%%:*}"
    target="${HOME}/${link##*:}"

    info "Linking file ${link%%:*} → ${link##*:}"
    ln -sf "${source}" "${target}"
  done
}

main "$@"
