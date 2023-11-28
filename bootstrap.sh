#!/bin/bash

set -euo pipefail

# Store the absolute path of the dotfiles root directory
DOTFILES_ROOT="$(cd "$(dirname "$0")" && pwd -P)"

# Clone the dotfiles repository if it doesn't exist
if [[ ! -e "${DOTFILES_ROOT}" ]]; then
    git clone --depth=1 https://github.com/sotayamashita/dotfiles.git "${DOTFILES_ROOT}" &>/dev/null
fi

os_name="$(uname -s)"
case "${os_name}" in
Linux*)
    echo "Setting up for Linux"

    if [[ -z $(command -v "apk") ]]; then
        apk update && apk install -y vim curl wget git-delta
    fi

    if [[ -z $(command -v "apt-get") ]]; then
        apt-get update && apt-get install -y vim curl wget git-delta
    fi
    ;;
Darwin*)
    echo "Setting up for macOS"
    # ./homebrew.sh
    ;;
*)
    echo "Unsupported OS: ${os_name}"
    exit 1
    ;;
esac

for file in $(find ${DOTFILES_ROOT}/symlinks -type f); do
    source="${DOTFILES_ROOT}/symlinks/${file##*/}"
    target="${HOME}/${file##*/}"

    ln -sf "${source}" "${target}"
done
