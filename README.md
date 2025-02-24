For 

```bash
cd; curl -#L https://github.com/sotayamashita/dotfiles/tarball/next | tar -xzv --strip-components 1 --exclude={README.md} --strip-components 1; ~/scripts/init.sh; ~/scripts/macos.sh; rm -rf ~/scripts
```

## Manual Setup

### Enable SSH Agent in 1Password

1. `open -a "1Password"`
2. <kbd>⌘ + ,</kbd>
3. Enable Developer > Use the SSH Agent

_[Learn more about the 1Password SSH Agent](https://developer.1password.com/docs/ssh/agent/)_<br/>

### Clone repository

```bash
git clone git@github.com:sotayamashita/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
```

### Create symbolic links

```bash
./scripts/symlinks
```

### Configure Git Commit Singing

```bash
./scripts/signing.sh
```

_[Learn more about Sign Git commits with SSH](https://developer.1password.com/docs/ssh/git-commit-signing/)_

### Divvy

1. Open Divvy
2. Open the following link in any browser
    ```
    divvy://import/YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGpCwwULC00PT5GVSRudWxs0g0ODxNaTlMub2JqZWN0c1YkY2xhc3OjEBESgAKABYAHgAjdFRYXGBkOGhscHR4fICEiIyQlJiclISkqIytYc2l6ZVJvd3NfEA9zZWxlY3Rpb25FbmRSb3dfEBFzZWxlY3Rpb25TdGFydFJvd1pzdWJkaXZpZGVkVmdsb2JhbF8QEnNlbGVjdGlvbkVuZENvbHVtbldlbmFibGVkW3NpemVDb2x1bW5zV25hbWVLZXlca2V5Q29tYm9Db2RlXxAUc2VsZWN0aW9uU3RhcnRDb2x1bW5da2V5Q29tYm9GbGFncxAGEAUQAAgJgAQQAgmAAxAEEgAIAABQ0i4vMDFaJGNsYXNzbmFtZVgkY2xhc3Nlc1hTaG9ydGN1dKIyM1hTaG9ydGN1dFhOU09iamVjdN0VFhcYGQ4aGxwdHh8gISIjJCUmIiUhOTo7PAgJgAQJgAYQJRADEgAIAABQ3RUWFxgZDhobHB0eHyAhIiMkJSYiJSE5RCNFCAmABAmABhAsEgAIAADSLi9HSF5OU011dGFibGVBcnJheaNHSUpXTlNBcnJheVhOU09iamVjdAAIABEAGgAkACkAMgA3AEkATABRAFMAXQBjAGgAcwB6AH4AgACCAIQAhgChAKoAvADQANsA4gD3AP8BCwETASABNwFFAUcBSQFLAUwBTQFPAVEBUgFUAVYBWwFcAWEBbAF1AX4BgQGKAZMBrgGvAbABsgGzAbUBtwG5Ab4BvwHaAdsB3AHeAd8B4QHjAegB7QH8AgACCAAAAAAAAAIBAAAAAAAAAEsAAAAAAAAAAAAAAAAAAAIR
    ```
3. Set <kbd>Option + D</kbd> as global shortcut

_[Learn more about Divvy](https://mizage.com/downloads/DivvyMacHelp.pdf)_

### iTerms

1. Open iTerm
2. Open Settings
3. Set Appearance > General > Theme to Minimal
4. Set Profiles > Text > Font Size to 14
3. Set Profiles > Text > Font to Fira Code Nerd Font

### Google Japanese IME

_Note: Restart is required_

1. Open Google Japanese IME
2. Open Settings
3. Set Language > Input Method to Google Japanese IME's input method
4. Remove default input method

## References

- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [diimdeep/dotfiles](https://github.com/diimdeep/dotfiles)