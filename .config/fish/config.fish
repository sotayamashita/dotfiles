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
fish_add_path $HOME/.volta/bin

# Ruby with rbenv
# https://github.com/rbenv/rbenv
status --is-interactive; and rbenv init - fish | source

# Rust
# https://www.rust-lang.org/
fish_add_path $HOME/.cargo/bin

# Golang
# https://go.dev/doc/install
fish_add_path /usr/local/go/bin

# Python
# https://github.com/pyenv/pyenv
fish_add_path $HOME/.pyenv/bin
pyenv init - | source

# Docker Desktop
# Added by Docker Desktop automatically
source $HOME/.docker/init-fish.sh | true

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

# Replacement for X

# https://github.com/ogham/exa
function ls -w exa
    exa -al -hg --icons --color=always --group-directories-first $argv
end

# https://github.com/sharkdp/bat
function cat -w bat
    bat --style=header,grid $argv
end

# https://github.com/ClementTsang/bottom
function top -w btm
    btm
end

# https://github.com/dalance/procs
function ps -w procs
    procs $argv
end

# https://github.com/denilsonsa/prettyping
function ping -w prettyping
    prettyping --nolegend $argv
end



# Terminal prompt with Starship
# Note: Must be end of the file
# https://starship.rs/
starship init fish | source
