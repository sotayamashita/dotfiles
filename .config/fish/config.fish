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
fish_add_path /opt/homebrew/openssl@3/bin

# Node.js with Volta
# https://volta.sh/
fish_add_path $HOME/.volta/bin

# Ruby with rbenv
# https://github.com/rbenv/rbenv
status --is-interactive; and rbenv init - fish | source

# Rust
# https://www.rust-lang.org/
fish_add_path $HOME/.cargo/bin

# Utility
function g -w git
    git $argv
end

function help
    tldr $argv
end

function path
    echo $PATH | tr -s " " "\n"
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
