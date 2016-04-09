# Dotfiles

<a href="https://github.com/sotayamashita/simple" target="_blank"><img src="https://cloud.githubusercontent.com/assets/1587053/14232267/44241d32-f9df-11e5-86ed-9c96befba0f3.png" width="550"/></a>

_Prompt from [simple](https://github.com/sotayamashita/simple)_


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
