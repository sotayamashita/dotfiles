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
status --is-interactive; and rbenv init - fish | source

# Rust
# https://www.rust-lang.org/
set -l CARGO_HOME $HOME/.cargo
test -d $CARGO_HOME; and fish_add_path $CARGO_HOME/bin

# Golang
# https://go.dev/doc/install
set -l GO_HOME /usr/local/go
test -d $GO_HOME; and fish_add_path $GO_HOME/bin

# Mojo
# https://docs.modular.com/mojo/manual/get-started/hello-world.html
set -l MODULAR_HOME $HOME/.modular
if test -d $MODULAR_HOME
    fish_add_path $MODULAR_HOME/pkg/packages.modular.com_mojo/bin
end

# Flutter
# https://flutter.dev/
set -l FLUTTER_HOME $HOME/development/flutter
if test -d $FLUTTER_HOME
    fish_add_path $FLUTTER_HOME/bin
end

# ngrok
# https://ngrok.com/
if command -v ngrok &>/dev/null
    eval "$(ngrok completion)"
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

# https://github.com/eza-community/eza
if command -v eza &>/dev/null
    function ls -w eza
        eza -al -hg --icons --color=always --group-directories-first $argv
    end
end

# https://github.com/sharkdp/bat
if command -v bat &>/dev/null
    function cat -w bat
        bat --style=header,grid $argv
    end
end

# https://github.com/ClementTsang/bottom
if command -v btm &>/dev/null
    function top -w btm
        btm
    end
end

# https://github.com/dalance/procs
if command -v procs &>/dev/null
    function ps -w procs
        procs $argv
    end
end

# https://github.com/denilsonsa/prettyping
if command -v prettyping &>/dev/null
    function ping -w prettyping
        prettyping --nolegend $argv
    end
end

# Created by `pipx` on 2024-03-10 05:06:23
set PATH $PATH /Users/sotayamashita/.local/bin
source /Users/sotayamashita/.config/op/plugins.sh

# Terminal prompt with Starship
# Note: Must be end of the file
# https://starship.rs/
starship init fish | source
