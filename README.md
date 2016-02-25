# Dotfiles

> Default for OSX

## Setup

**Requirements**

* Fisherman: https://github.com/fisherman/fisherman
* powerline/fonts: https://github.com/powerline/fonts

## Install

**Using Git and the install script**

```javascript
curl -s https://raw.githubusercontent.com/sotayamashita/dotfiles/master/bin/install.sh | sh
```

## Update

```bash
cd $HOME/.shdr
git pull --rebase
cp -r $HOME/.shdr/.config/fish/* ~/.config/fish/
```

## License

MIT © Sota Yamashita
