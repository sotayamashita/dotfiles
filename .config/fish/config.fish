set fish_greeting

# Paths
test -d $HOME/.dotfiles/bin                              ; and set PATH $HOME/.dotfiles/bin $PATH
test -d /usr/local/sbin                                  ; and set PATH /usr/local/sbin $PATH
test -x /usr/local/share/git-core/contrib/diff-highlight ; and set PATH /usr/local/share/git-core/contrib/diff-highlight $PATH
test -d /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin; and set PATH /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin $PATH

# Navigation
function ..    ; cd .. ; end
function ...   ; cd ../../ ; end
function ....  ; cd ../../../ ; end
function ..... ; cd ../../../../ ; end
function ......; cd ../../../../../ ; end

function dt    ; cd $HOME/Desktop ; end
function work  ; cd $HOME/Documents/workspace ; end

# Utilities
function d         ; du -h -d=1 $argv ; end
function dig       ; dig +nocmd any +multiline +noall +answer ; end
function g         ; git $argv ; end
function grep      ; command grep --color=auto $argv ; end
function j         ; jobs ; end
function h         ; history ; end
function httpdump  ; sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E "Host\: .*|GET \/.*" ; end
function ip        ; curl -s http://checkip.dyndns.com/ | sed 's/[^0-9\.]//g' ; end
function localip   ; ipconfig getifaddr en0 ; end
function sniff     ; sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80' ; end
function urlencode ; python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);" ; end
function v         ; vim ; end

# Need extra libraries
test -x /usr/local/bin/hub  ; and function g  ; git $argv ; end
test -x /usr/local/bin/tree ; and function l  ; tree --dirsfirst -aFCNL 1 $argv ; end
test -x /usr/local/bin/tree ; and function ll ; tree --dirsfirst -ChFupDaLg 1 $argv ; end

# Gitconfig.user
test -e $HOME/.extra; and source $HOME/.extra

# Rust
test -e $HOME/.cargo/env; and source $HOME/.cargo/env

# Ruby
# Load rbenv automatically by appending
test -x /usr/local/bin/rbenv; and rbenv init - | source

# Python
# See: https://github.com/pyenv/pyenv#homebrew-on-mac-os-x
test -x /usr/local/bin/pyenv; and pyenv init - | source

# Java
# See: http://stackoverflow.com/questions/1348842/what-should-i-set-java-home-to-on-osx
test -x /usr/libexec/java_home; and set -x JAVA_HOME (/usr/libexec/java_home)
test -d $JAVA_HOME/bin; and set -x PATH $JAVA_HOME/bin $PATH

# Android
# See: https://stackoverflow.com/questions/19986214/setting-android-home-enviromental-variable-on-mac-os-x
# Set ANDROID_HOME
test -d $HOME/Library/Android/sdk; and set -x ANDROID_HOME $HOME/Library/Android/sdk
test -d $ANDROID_HOME/tools; and set -x PATH $ANDROID_HOME/tools $PATH
test -d $ANDROID_HOME/platform-tools; and set -x PATH $ANDROID_HOME/platform-tools $PATH

# Kitty
# See: https://sw.kovidgoyal.net/kitty/#fish
test -x /usr/local/bin/kitty; and kitty + complete setup fish | source

# Themes
# set -g fish_user_paths "/usr/local/opt/libxml2/bin" $fish_user_paths
set SPACEFISH_PROMPT_ORDER time user dir host git exec_time line_sep battery jobs exit_code char
