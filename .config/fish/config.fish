set fish_greeting

# Navigation
function ..      ; cd .. ; end
function ...     ; cd ../../ ; end
function ....    ; cd ../../../ ; end
function .....   ; cd ../../../../ ; end
function ......  ; cd ../../../../../ ; end

# Utility
function ip      ; curl -s http://checkip.dyndns.com/ | sed 's/[^0-9\.]//g' ; end
function localip ; ipconfig getifaddr en0 ; end

# GPG
set -gx GPG_TTY (tty)

# Startship
set -gx STARSHIP_CONFIG $HOME/.config/starship.toml && starship init fish | source

# Homebrew
fish_add_path /opt/homebrew/bin

# Node.js (Volta)
set -gx VOLTA_HOME $HOME/.volta
fish_add_path $VOLTA_HOME/bin

# Ruby
status --is-interactive; and rbenv init - fish | source

# Rust
set -gx CARGO_HOME $HOME/.cargo
fish_add_path $CARGO_HOME/bin

# Android
set -gx ANDROID_HOME $HOME/Library/Android/sdk
fish_add_path $HOME/Library/Android/sdk/cmdline-tools/latest/bin

set -gx JAVA_HOME /usr/libexec/java_home
fish_add_path $JAVA_HOME/bin

## Commands that depend on other libraries
test -x /opt/homebrew/bin/hub ; and function g    ; gh  $argv ; end
test -x /opt/homebrew/bin/lsd ; and function ls   ; lsd $argv ; end
test -x /opt/homebrew/bin/btm ; and function top  ; btm ; end
test -x /opt/homebrew/bin/bat ; and function cat  ; bat --style=header,grid $argv; end