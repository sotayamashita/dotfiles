# dotfiles

> :zap: Superautomate - Dotfiles for OSX

## Install

**Run script and it is changing your environment immediately**

```bash
sh -c "`curl -fsSL https://raw.githubusercontent.com/sotayamashita/dotfiles/master/bootstrap.sh`"
```

## Update

```bash
git -C $HOME/.dotfiles pull --rebase
cp -r $HOME/.dotfiles/.config/fish/* ~/.config/fish/
source ~/.config/fish/config.fish
```

## Acknowledgement

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)

## License

MIT © Sota Yamashita
