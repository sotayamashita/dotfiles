# dotfiles

Configuration for .

## Install

```bash
git clone -b next https://github.com/sotayamashita/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./scripts/init.sh
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
