# dotfiles

## Simplified Setup

Run this single command to start the automated setup process:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/sotayamashita/dotfiles/main/bootstrap.sh)"
```

```mermaid
flowchart TD
    Start([Start Execution]) --> CheckState{Check State}
    
    CheckState -->|initial| Stage1[Stage 1: Initial Setup]
    CheckState -->|homebrew_installed| Stage2[Stage 2: SSH Configuration]
    CheckState -->|ssh_configured| Stage3[Stage 3: Complete Setup]
    CheckState -->|completed| AlreadyDone[Setup Already Completed]
    CheckState -->|unknown| ResetState[Reset State]
    
    ResetState --> CheckState
    
    Stage1 --> InstallPrereq[Install Prerequisites\nXcode CLT, Homebrew]
    InstallPrereq --> SetupCore1[Setup Core Functionality\nSymlinks, Brewfile]
    SetupCore1 --> SetupMacOS1[Configure macOS\nDock, System Preferences]
    SetupMacOS1 --> SaveState1[Save State: homebrew_installed]
    SaveState1 --> Exit1[Temporary Exit\nContinue on Next Run]
    
    Stage2 --> SetupSSH[Configure SSH\n1Password SSH Agent]
    SetupSSH --> SaveState2[Save State: ssh_configured]
    SaveState2 --> Exit2[Temporary Exit\nContinue on Next Run]
    
    Stage3 --> CloneRepo[Clone Repository\nvia SSH]
    CloneRepo --> SetupCore2[Setup Core Functionality\nSymlinks, Brewfile]
    SetupCore2 --> RunInstallers[Run Installers\nRust, Volta, uv, etc.]
    RunInstallers --> SetupMacOS2[Configure macOS\nDock, System Preferences]
    SetupMacOS2 --> CleanupTemp[Clean Up Temporary Files]
    CleanupTemp --> SaveState3[Save State: completed]
    SaveState3 --> Completed[Setup Complete]
    
    AlreadyDone --> Completed
    
    classDef stage fill:#f9f,stroke:#333,stroke-width:2px;
    classDef state fill:#bbf,stroke:#33f,stroke-width:2px;
    classDef action fill:#dfd,stroke:#080,stroke-width:1px;
    
    class Stage1,Stage2,Stage3 stage;
    class CheckState,SaveState1,SaveState2,SaveState3 state;
    class InstallPrereq,SetupCore1,SetupCore2,SetupMacOS1,SetupMacOS2,SetupSSH,CloneRepo,RunInstallers,CleanupTemp action;
```

## Setup Process Details

This dotfiles repository uses a multi-stage setup process due to SSH dependency constraints on a fresh macOS installation:

1. **Initial Setup**: Downloads and applies basic configuration without requiring SSH
2. **SSH Configuration**: Sets up 1Password SSH Agent for GitHub authentication
3. **Complete Setup**: Clones the repository via SSH for proper version control

### Manual Setup (Alternative)

If you prefer to run the setup manually, follow these steps:

#### Stage 1: Initial Setup (without SSH)

```bash
cd; curl -#L https://github.com/sotayamashita/dotfiles/tarball/main | tar -xzv --strip-components 1 --exclude={README.md} --strip-components 1; ~/scripts/modules/core/symlinks.sh; ~/scripts/modules/core/brew.sh; rm -rf ~/scripts
```

This will:
- Download the repository as a tarball directly to your home directory
- Install essential tools (xcode-select, Homebrew)
- Apply basic configuration
- Remove the temporary scripts directory

#### Stage 2: Complete Setup (with SSH)

After the initial setup, follow these steps for a complete installation:

1. **Set up 1Password SSH Agent**:
   - Install 1Password from Homebrew
   - Enable SSH Agent in 1Password:
     1. `open -a "1Password"`
     2. <kbd>⌘ + ,</kbd>
     3. Enable Developer > Use the SSH Agent

   _[Learn more about the 1Password SSH Agent](https://developer.1password.com/docs/ssh/agent/)_

2. **Clone repository to permanent location**:
   ```bash
   git clone git@github.com:sotayamashita/dotfiles.git ~/Projects/dotfiles
   cd ~/Projects/dotfiles
   ```

3. **Run setup scripts**:
   ```bash
   ./scripts/modules/core/symlinks.sh
   ./scripts/modules/core/brew.sh
   ./scripts/modules/macos/preferences.sh
   ```

   _[Learn more about Sign Git commits with SSH](https://developer.1password.com/docs/ssh/git-commit-signing/)_

## Directory Structure

```bash
dotfiles/
├── .config/          # Configuration files
├── installers/       # Individual tool installers
├── bootstrap.sh      # Automated setup script
└── scripts/          # Setup scripts
    ├── lib/          # Common library functions
    │   ├── utils.sh              # Utility functions
    │   └── state.sh              # State management
    ├── modules/      # Modular scripts by functionality
    │   ├── core/                 # Core functionality
    │   │   ├── symlinks.sh       # Symlink creation
    │   │   └── brew.sh           # Homebrew package management
    │   └── macos/                # macOS specific settings
    │       ├── dock.sh           # Dock configuration
    │       └── preferences.sh    # System preferences
    └── installers/   # External tool installers
```

## Cross-Platform Support

This dotfiles repository supports macOS:

- **macOS**: Full support with macOS-specific configurations

The bootstrap process automatically applies the appropriate configurations.
