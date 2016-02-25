# Dotfiles

> Default for OSX

## Setup

**Requirements**

* Fish: http://fishshell.com/
* Git: https://git-scm.com/
* Fisherman: https://github.com/fisherman/fisherman
* powerline/fonts: https://github.com/powerline/fonts

## Install

**Using Git and the bootstrap script**

```javascript
curl -s https://raw.githubusercontent.com/sotayamashita/dotfiles/master/install.sh | sh
```

**Git-free**

```javascript
mkdir ~/.shdr and cd $_; curl -#L https://github.com/sotayamashita/dotfiles/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,bootstrap.sh,LICENSE-MIT.txt}
```

## Install Homebrew formulae

```bash
./brew.sh
```

## Update

```bash
cd $HOME/.shdr
git pull --rebase
cp -r $HOME/.shdr/.config/fish/* ~/.config/fish/
```

## Acknowledgements

Inspiration and code was taken from many sources, including:

* [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles)
* [Nicolas Gallagher's dotfiles](https://github.com/necolas/dotfiles)

## License

MIT © Sota Yamashita
