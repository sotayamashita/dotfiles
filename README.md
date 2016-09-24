# dotfiles

> Dotfiles for OSX


## Install

**Using Git and the install script**

```bash
sh -c "`curl -fsSL https://raw.githubusercontent.com/sotayamashita/dotfiles/master/bootstrap.sh`"
```


## Update

```bash
git -C $HOME/.dotfiles pull --rebase
cp -r $HOME/.dotfiles/.config/fish/* ~/.config/fish/
source ~/.config/fish/config.fish
```


## License

MIT © Sota Yamashita
