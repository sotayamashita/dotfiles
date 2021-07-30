set fish_greeting

# Path
test -d /opt/homebrew/bin ; and set -g fish_user_paths "/opt/homebrew/bin" $fish_user_paths

# Utility
function ..      ; cd .. ; end
function ...     ; cd ../../ ; end
function ....    ; cd ../../../ ; end
function .....   ; cd ../../../../ ; end
function ......  ; cd ../../../../../ ; end
function ip      ; curl -s http://checkip.dyndns.com/ | sed 's/[^0-9\.]//g' ; end
function localip ; ipconfig getifaddr en0 ; end

## Commands that depend on other libraries
test -x /opt/homebrew/bin/hub ; and function g    ; hub $argv ; end
test -x /opt/homebrew/bin/lsd ; and function ls   ; lsd $argv ; end
test -x /opt/homebrew/bin/btm ; and function top  ; btm ; end
test -x /opt/homebrew/bin/bat ; and function cat  ; bat --style=header,grid $argv; end

# Load gituserconfig
test -e $HOME/.gituserconfig ; and source $HOME/.gituserconfig

# Init starship, which is The minimal, blazing-fast, and infinitely customizable prompt for any shell!
# https://starship.rs/guide/#%F0%9F%9A%80-installation
set -gx STARSHIP_CONFIG $HOME/.config/starship.toml
starship init fish | source

# Init asdf, which it Extendable version manager
# https://github.com/asdf-vm/asdf
source /opt/homebrew/opt/asdf/asdf.fish