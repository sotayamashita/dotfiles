# dotfiles

For 

```bash
cd; mkdir ~/.setupmac && curl -#L https://github.com/sotayamashita/dotfiles/tarball/next | tar -xzv --strip-components 1 --exclude={.config,symlinks,README.md} --strip-components 1 -C ~/.setupmac; ~/.setupmac/init.sh && ~/.setupmac/macos.sh; rm -rf ~/.setupmac
```
