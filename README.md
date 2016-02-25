# Dotfiles

> Default for OSX

## Setup

**Requirements**

* Fish: http://fishshell.com/
* Git: https://git-scm.com/
* Fisherman: https://github.com/fisherman/fisherman
* powerline/fonts: https://github.com/powerline/fonts

## Install

```bash
curl -s https://raw.githubusercontent.com/sotayamashita/dotfiles/master/bootstrap.sh | sh
```

## Update

```bash
cd $HOME/.shdr
git pull --rebase
cp -r $HOME/.shdr/.config/fish/* ~/.config/fish/
```

## Install Homebrew formulae

```bash
./brew.sh
```
