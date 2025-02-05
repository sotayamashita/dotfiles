# To change login shell to fish:
# echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
# chsh -s /opt/homebrew/bin/fish
# echo $SHELL

# Disable default greeting message ⋊>
# https://fishshell.com/docs/current/faq.html#how-do-i-change-the-greeting-message
set -U fish_greeting


# Programming languages/libraries

# Dotfiles
fish_add_path $HOME/.dotfiles/bin

# Homebrew
# https://brew.sh/
fish_add_path /opt/homebrew/sbin

# Openssl
# https://www.openssl.org/
# https://github.com/puma/puma/issues/2603
fish_add_path /opt/homebrew/opt/openssl@3/bin

# Node.js with Volta
# https://volta.sh/
set -l VOLTA_HOME $HOME/.volta
if test -d $VOLTA_HOME
    fish_add_path $VOLTA_HOME/bin
    volta completions fish | source
end

# Python with pyenv
# https://github.com/pyenv/pyenv
set -l PYTHON_HOME $HOME/.pyenv
if test -d $PYTHON_HOME
    fish_add_path $HOME/.pyenv/bin
    pyenv init - | source
end

# Ruby with rbenv
# https://github.com/rbenv/rbenv
set -l RBENV_HOME $HOME/.rbenv
if test -d $RBENV_HOME
    status --is-interactive; and rbenv init - fish | source
end

# Rust
# https://www.rust-lang.org/
set -l CARGO_HOME $HOME/.cargo
if test -d $CARGO_HOME
    fish_add_path $CARGO_HOME/bin
end

# Golang
# https://go.dev/doc/install
set -l GO_HOME /usr/local/go
if test -d $GO_HOME
    fish_add_path $GO_HOME/bin
end


# Mojo
# https://docs.modular.com/mojo/manual/get-started/hello-world.html
set -l MODULAR_HOME $HOME/.modular
if test -d $MODULAR_HOME
    fish_add_path $MODULAR_HOME/pkg/packages.modular.com_mojo/bin
end

# Flutter
set -l FLUTTER_HOME $HOME/development/flutter
if test -d $FLUTTER_HOME
    fish_add_path $FLUTTER_HOME/bin
end

# pipx
# https://github.com/pypa/pipx
if test -d $HOME/.local/bin
    fish_add_path $HOME/.local/bin
end

# Utility
function g -w git
    git $argv
end

# https://pnpm.io/installation#using-a-shorter-alias
function pn -w pnpm
    pnpm $argv
end

function help
    tldr $argv
end

function path
    echo $PATH | tr -s " " "\n"
end

function localserver
    python3 -m http.server $argv
end

# Navigation

function ws
    cd ~/Documents/workspace
end

function ..
    cd ..
end

function ...
    cd ../../
end

function ....
    cd ../../..
end

function icloud
    cd ~/Library/Mobile\ Documents/com~apple\~CloudDocs
end

# Replacement for X

# Replacement for ls
# https://github.com/eza-community/eza
function ls -w eza
    if command -v eza >/dev/null 2>&1
        eza -al -hg --icons --color=always --group-directories-first $argv
    else
        echo "eza is not installed. Using ls instead." >&2
        echo "To install eza: brew install eza" >&2
        command ls $argv
    end
end

# Replacement for cat
# https://github.com/sharkdp/bat
function cat -w bat
    if command -v bat >/dev/null 2>&1
        bat --style=header,grid $argv
    else
        echo "bat is not installed. Using cat instead." >&2
        echo "To install bat: brew install bat" >&2
        command cat $argv
    end
end

# Replacement for top
# https://github.com/ClementTsang/bottom
function top -w btm
    if command -v btm >/dev/null 2>&1
        btm
    else
        echo "btm is not installed. Using top instead." >&2
        echo "To install btm: brew install bottom" >&2
        command top $argv
    end
end

# Replacement for ps
# https://github.com/dalance/procs
function ps -w procs
    if command -v procs >/dev/null 2>&1
        procs $argv
    else
        echo "procs is not installed. Using ps instead." >&2
        echo "To install procs: brew install procs" >&2
        command ps $argv
    end
end

# Replacement for ping
# https://github.com/denilsonsa/prettyping
function ping -w prettyping
    if command -v prettyping >/dev/null 2>&1
        prettyping --nolegend $argv
    else
        echo "prettyping is not installed. Using ping instead." >&2
        echo "To install prettyping: brew install prettyping" >&2
        command ping $argv
    end
end

# Terminal prompt with Starship
# Note: Must be end of the file 
# https://starship.rs/
starship init fish | source



# Added by Windsurf
fish_add_path /Users/sotayamashita/.codeium/windsurf/bin
