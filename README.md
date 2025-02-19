For 

```bash
cd; mkdir ~/.setupmac && curl -#L https://github.com/sotayamashita/dotfiles/tarball/next | tar -xzv --strip-components 1 --exclude={.config,symlinks,README.md} --strip-components 1 -C ~/.setupmac; ~/.setupmac/init.sh; ~/.setupmac/macos.sh; rm -rf ~/.setupmac
```

## Manual Setup

### 1Password

1. Open 1Password
2. Open Settings
3. Enable "Use the SSH Agent"
4. Find GitHub SSH Key on 1Password
5. Set up commit signing

_[Learn more about the 1Password SSH Agent](https://developer.1password.com/docs/ssh/agent/)_<br/>
_[Learn more about Sign Git commits with SSH](https://developer.1password.com/docs/ssh/agent/)_

### Divvy

1. Open Divvy
2. [Click to import Divvy settings](divvy://import/YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGpCwwULC00PT5GVSRudWxs0g0ODxNaTlMub2JqZWN0c1YkY2xhc3OjEBESgAKABYAHgAjdFRYXGBkOGhscHR4fICEiIyQlJiclISkqIytYc2l6ZVJvd3NfEA9zZWxlY3Rpb25FbmRSb3dfEBFzZWxlY3Rpb25TdGFydFJvd1pzdWJkaXZpZGVkVmdsb2JhbF8QEnNlbGVjdGlvbkVuZENvbHVtbldlbmFibGVkW3NpemVDb2x1bW5zV25hbWVLZXlca2V5Q29tYm9Db2RlXxAUc2VsZWN0aW9uU3RhcnRDb2x1bW5da2V5Q29tYm9GbGFncxAGEAUQAAgJgAQQAgmAAxAEEgAIAABQ0i4vMDFaJGNsYXNzbmFtZVgkY2xhc3Nlc1hTaG9ydGN1dKIyM1hTaG9ydGN1dFhOU09iamVjdN0VFhcYGQ4aGxwdHh8gISIjJCUmIiUhOTo7PAgJgAQJgAYQJRADEgAIAABQ3RUWFxgZDhobHB0eHyAhIiMkJSYiJSE5RCNFCAmABAmABhAsEgAIAADSLi9HSF5OU011dGFibGVBcnJheaNHSUpXTlNBcnJheVhOU09iamVjdAAIABEAGgAkACkAMgA3AEkATABRAFMAXQBjAGgAcwB6AH4AgACCAIQAhgChAKoAvADQANsA4gD3AP8BCwETASABNwFFAUcBSQFLAUwBTQFPAVEBUgFUAVYBWwFcAWEBbAF1AX4BgQGKAZMBrgGvAbABsgGzAbUBtwG5Ab4BvwHaAdsB3AHeAd8B4QHjAegB7QH8AgACCAAAAAAAAAIBAAAAAAAAAEsAAAAAAAAAAAAAAAAAAAIR)

_[Learn more about Divvy](https://mizage.com/downloads/DivvyMacHelp.pdf)_
