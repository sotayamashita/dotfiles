# dotfiles

For 

## Install

```bash
cd; curl -#L https://github.com/sotayamashita/dotfiles/tarball/next | tar -xzv --strip-components 1
~/dotfiles/init.sh
```

## Structure

```
~/Projects/dotfiles/
├── .config/          # Configuration files for fish, etc.
├── symlinks/         # Files to be symlinked
├── scripts/          # Setup scripts
│   ├── init.sh      # Main setup script
│   ├── brew.sh      # Homebrew installation and configuration
│   └── macos.sh     # macOS specific settings (optional)
└── README.md        # This file
```

## Features

- 🔑 1Password SSH integration
- 🐟 Fish Shell configuration
- 🍺 Homebrew package management
-  macOS system preferences (optional)

## Symlinks

The following files will be created as symlinks in your home directory:

- `.config/*` → `~/.config/*`
- `symlinks/.*` → `~/.*`
