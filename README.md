# Dotfiles

> Default for OSX

## Setup

**Required software**

* Fish: http://fishshell.com/
* Git: https://git-scm.com/
* Fisherman: https://github.com/fisherman/fisherman

## Install

```bash
curl -s https://raw.githubusercontent.com/sotayamashita/dotfiles/master/bootstrap.sh | sh
```

## Update

```bash
cd $HOME/.shdr
git pull --rabase
cp -r $HOME/.shdr/.config/fish/* ~/.config/fish/
```
