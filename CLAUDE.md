# Dotfiles Project Instructions

## Important: This is NOT the global Claude configuration file

This CLAUDE.md file is for **this dotfiles project only**. The global Claude configuration is located at `.claude/CLAUDE.md` within this repository, which gets symlinked to `~/.claude/CLAUDE.md`.

## File Structure Clarification

```
dotfiles/
├── CLAUDE.md                  # THIS FILE - Project-specific instructions
├── .claude/
│   └── CLAUDE.md              # Global Claude config (symlinked to ~/.claude/CLAUDE.md)
└── scripts/modules/core/
    └── symlinks.sh            # Creates all symlinks including .claude/CLAUDE.md
```

## Project Overview

This dotfiles repository manages system configuration files through symlinks. All files are stored in this repository and symlinked to their appropriate locations in the home directory.

## Key Concepts

1. **Symlink Management**: Files in this repo are NOT used directly. They are symlinked to `$HOME` via `symlinks.sh`
2. **Two-way Sync**: Changes to files here affect the system, and vice versa (they're symlinks)
3. **Global vs Project Config**: 
   - `.claude/CLAUDE.md` = Global Claude settings (affects all projects)
   - `CLAUDE.md` (this file) = Project-specific instructions

## Working with This Repository

### When modifying configuration files:
- Edit files directly in this repository
- Changes immediately affect the system (via symlinks)
- Test changes carefully before committing

### When adding new dotfiles:
1. Add the file to this repository in the appropriate location
2. Update `SYMLINK_TARGETS` array in `scripts/modules/core/symlinks.sh`
3. Run `./scripts/modules/core/symlinks.sh` to create the symlink

### Important Scripts:
- `init.sh` - Initial setup for new machines
- `sync.sh` - Sync configurations
- `scripts/modules/core/symlinks.sh` - Core symlink creation
- `scripts/modules/core/brew.sh` - Homebrew package management
- `scripts/modules/macos/` - macOS-specific settings

## Development Guidelines

1. **Test Before Commit**: Configuration changes affect the live system
2. **Backup First**: The symlink script creates backups, but be careful
3. **Document Changes**: Update relevant documentation when adding new configs
4. **Follow Conventions**: 
   - Use English for code and commit messages
   - Follow conventional commit format
   - Keep shell scripts POSIX-compliant where possible

## Common Tasks

### Add a new dotfile:
```bash
# 1. Add file to repository
# 2. Update SYMLINK_TARGETS in symlinks.sh
# 3. Run symlink creation
./scripts/modules/core/symlinks.sh
```

### Update Homebrew packages:
```bash
# Update .Brewfile first, then:
./scripts/modules/core/brew.sh
```

### Apply macOS preferences:
```bash
./scripts/modules/macos/preferences.sh
```
