# Dotfiles

> Default for OSX

## Install

**Using Git and the install script**

```javascript
curl -s https://raw.githubusercontent.com/sotayamashita/dotfiles/master/bin/install.sh | sh
```

## Update

```bash
git -C $HOME/.dotfiles pull --rebase
cp -r $HOME/.dotfiles/.config/fish/* ~/.config/fish/
source ~/.config/fish/config
```

## License

MIT © Sota Yamashita
