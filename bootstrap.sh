#!/bin/bash
#
# Bootstraping dotfiles

#######################################
# Show normal message
# Arguments:
#   Message
# Returns:
#   None
#######################################
info() {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

#######################################
# Show success message
# Arguments:
#   Message
# Returns:
#   None
#######################################
success() {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

#######################################
# Show failure message
# Arguments:
#   Message
# Returns:
#   exit status
#######################################
fail() {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

#######################################
# Detect command is exist
# Arguments:
#   Command
# Returns:
#   0 or 1
#######################################
type_exists() {
  if type $1 > /dev/null 2>&1; then
    return 0
  fi
  return 1
}

#######################################
# Install xcode-select
# Arguments:
#   none
# Returns:
#   none
#######################################
install_xcode() {
  if ! type xcode-select >&- && xpath=$( xcode-select --print-path ) && test -d "${xpath}" && test -x "${xpath}"; then
    info "Installing xcode-select"
    xcode-select --install
  else
    success "xcode-select already installed"
  fi
}

#######################################
# Install homebrew
# Arguments:
#   none
# Returns:
#   none
#######################################
install_homebrew() {
  if ! type_exists "brew"; then
    info "Installing brew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  else
    success "all fomulas already installed"
  fi
}

#######################################
# Install fomulas
# Arguments:
#   none
# Returns:
#   none
#######################################
install_fomulas() {
  ./brew.sh
}

#######################################
# Install fish
# Arguments:
#   none
# Returns:
#   none
#######################################
install_fish() {
  if ! type_exists "fish"; then
    info "Installing fish"
    brew install fish
    info "To make Fish your default shell"
    chsh -s /usr/local/bin/fish
  else
    success "fish already installed"
  fi
}

#######################################
# Install fisherman
# Arguments:
#   none
# Returns:
#   none
#######################################
install_fisherman() {
  if [[ ! -f $HOME/.config/fish/functions/fisher.fish ]]; then
    info "Installing fisherman"
    curl -sLo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
    fisher
  else
    success "fisherman already installed"
  fi
}

#######################################
# Install dotfiles
# Arguments:
#   none
# Returns:
#   none
#######################################
install_dotfiles() {
  if [[ ! -d $HOME/.dotfiles ]]; then
    info "Installing dotfiles for the first time"
    git clone --depth=1 https://github.com/sotayamashita/dotfiles.git "$HOME/.dotfiles"
    cp -r $HOME/.dotfiles/.config/fish/* ~/.config/fish/
    success "Successfully, created ~/.dotfiles"
  else
    success "dotfiles already installed"
  fi
}

#######################################
# Create sercrets file
# Arguments:
#   none
# Returns:
#   none
#######################################
create_sercrets() {
  readonly FILENAME=".secrets"
  readonly FILEPATH="${HOME}/${FILENAME}"

  if [[ ! -e $FILEPATH ]]; then
    cat <<EOT >> $FILEPATH
# All
set AUTHOR_NAME                       "<Your Name>"
set AUTHOR_MAIL                       "<Your Email Address>"

# Git
set GIT_AUTHOR_NAME                   "\$AUTHOR_NAME"
set GIT_COMITTER_NAME                 "\$GIT_AUTHOR_NAME"
git config --global user.name         "\$GIT_COMITTER_NAME"

set GIT_AUTHOR_MAIL                   "\$AUTHOR_MAIL"
set GIT_COMITTER_EMAIL                "\$GIT_AUTHOR_MAIL"
git config --global user.email        "\$GIT_AUTHOR_MAIL"

set GIT_AUTHOR_SIGNINGKEY             "xxxxxxxx"
set GIT_COMMIT_SIGNINGKEY             "\$GIT_AUTHOR_SIGNINGKEY"
git config --global user.signingkey   "\$GIT_AUTHOR_SIGNINGKEY"

# NPM
set NPM_AUTHOR_NAME                   "\$AUTHOR_NAME"
npm config --global init-author-name  "\$NPM_AUTHOR_NAME"

set NPM_AUTHOR_EMAIL                  "\$AUTHOR_MAIL"
npm config --global init-author-email "\$NPM_AUTHOR_EMAIL"
EOT
  else
    success "/.secrets already created"
  fi
}

create_symlink() {
  if [[ -L $1 ]]; then
    if [[ -e $1 ]]; then
      info "${1} is already exist"
    else
      fail "${1} is broken link"
    fi
  elif [[ -e $1 ]]; then
    fail ""
  else
    info "Trying create symlink"
    ln -s $2 $1
    success "Successfully, create symlink"
  fi
}


create_ssh() {
  if [[ ! -d $HOME/.ssh ]]; then
    mkdir $HOME/.ssh
    chmod 700 $HOME/.ssh
  else
    success "/.ssh already created"
  fi
}

main() {
  # create ssh directory
  create_ssh

  # Install xcode-install
  install_xcode

  # Install homebrew formulas
  install_homebrew

  # Install fomulas
  install_fomulas

  # Install fish
  install_fish

  # Install fihser
  install_fisherman

  # Install dotfiles
  install_dotfiles

  # Create sercret file
  create_sercrets

  # Create symlink
  # TODO: Raise the level of abstraction
  create_symlink $HOME/.gitignore    $HOME/.dotfiles/git/gitignore
  create_symlink $HOME/.gitconfig    $HOME/.dotfiles/git/gitconfig
  create_symlink $HOME/.gitmessage   $HOME/.dotfiles/git/gitmessage
  create_symlink $HOME/.npmrc        $HOME/.dotfiles/npm/npmrc
  create_symlink $HOME/.editorconfig $HOME/.dotfiles/editorconfig/editorconfig
}

main "$@"
