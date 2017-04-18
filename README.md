# dotfiles

> :zap: Superautomate - Dotfiles for OSX

## Install

**Using Git and then run the install script**

```bash
sh -c "`curl -fsSL https://raw.githubusercontent.com/sotayamashita/dotfiles/master/bin/bootstrap.sh`"
```

## Update

```bash
git -C $HOME/.dotfiles pull --rebase
cp -r $HOME/.dotfiles/.config/fish/* ~/.config/fish/
source ~/.config/fish/config.fish
```

## Todos

I am tring to automate everything but there are still issues with [`todo` label](https://github.com/sotayamashita/dotfiles/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen%20label%3Atodo%20).   
If you know the way, I would appreciate if you could create pull requests.

## Acknowledgements

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)

## License

MIT © Sota Yamashita
