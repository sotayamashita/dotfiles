# disable default fish greeting ⋊>
set fish_greeting "" 

# Navigation
function ..      ; cd .. ; end
function ...     ; cd ../../ ; end
function ....    ; cd ../../../ ; end
function .....   ; cd ../../../../ ; end
function ......  ; cd ../../../../../ ; end

# Utility
function ip      ; curl -s http://checkip.dyndns.com/ | sed 's/[^0-9\.]//g' ; end
function localip ; ipconfig getifaddr en0 ; end

# Homebrew
if test -d (brew --prefix)
  fish_add_path (brew --prefix)/bin
end

# GPG
if type -q gpg-agent
  set -gx GPG_TTY (tty)
end

# Startship 
# https://starship.rs/
if test -d (brew --prefix starship)
  set -gx STARSHIP_CONFIG $HOME/.config/starship.toml
  starship init fish | source
end

# Node.js (Volta)
# https://volta.sh/
if test -d $HOME/.volta
  set -gx VOLTA_HOME $HOME/.volta
  fish_add_path $VOLTA_HOME/bin
end

# Ruby (rbenv)
# https://github.com/rbenv/rbenv
if test -d (brew --prefix rbenv)
  status --is-interactive; and rbenv init - fish | source
end

if test -d (brew --prefix openssl@3)
  fish_add_path (brew --prefix openssl@3)/bin
end


# Rust
# https://www.rust-lang.org/tools/install
if test -d $HOME/.cargo
  set -gx CARGO_HOME $HOME/.cargo
  fish_add_path $CARGO_HOME/bin
end

# Flutter
# https://docs.flutter.dev/get-started/install/macos
if test -d $HOME/flutter
  fish_add_path $HOME/flutter/bin
end

# Java
if test -d /usr/libexec/java_home
  set -gx JAVA_HOME /usr/libexec/java_home
  fish_add_path $JAVA_HOME/bin
end

# Android
if test -d $HOME/Library/Android/sdk
  set -gx ANDROID_HOME $HOME/Library/Android/sdk
  fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin
end

# Postgres
# Fix `Library not loaded: '/opt/homebrew/opt/postgresql/lib/libpq.5.dylib' (LoadError)`
if test -d (brew --prefix postgresql@14) 
  ln -sf /opt/homebrew/opt/postgresql/lib/postgresql@14/libpq.5.dylib /opt/homebrew/opt/postgresql/lib/libpq.5.dylib
end

# Commands that depend on other libraries
test -x /opt/homebrew/bin/git ; and function g    ; git $argv ; end
test -x /opt/homebrew/bin/lsd ; and function ls   ; lsd $argv ; end
test -x /opt/homebrew/bin/btm ; and function top  ; btm ; end
test -x /opt/homebrew/bin/bat ; and function cat  ; bat --style=header,grid $argv; end