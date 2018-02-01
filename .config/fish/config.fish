set fish_greeting

# Paths
test -d $HOME/.dotfiles/bin                              ; and set PATH $HOME/.dotfiles/bin $PATH
test -d /usr/local/sbin                                  ; and set PATH /usr/local/sbin $PATH
test -x /usr/local/share/git-core/contrib/diff-highlight ; and set PATH /usr/local/share/git-core/contrib/diff-highlight $PATH
test -d /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin; and set PATH  /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin $PATH

# Navigation
function ..    ; cd .. ; end
function ...   ; cd ../../ ; end
function ....  ; cd ../../../ ; end
function ..... ; cd ../../../../ ; end
function ......; cd ../../../../../ ; end

function dt    ; cd $HOME/Desktop ; end
function work  ; cd $HOME/Documents/workspace ; end
function src   ; cd $HOME/Documents/src ; end

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
function t         ; command tree -C $argv ; end
function urlencode ; python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);" ; end
function v         ; vim ; end

# Need extra libraries
test -x /usr/local/bin/hub  ; and function g  ; git $argv ; end
test -x /usr/local/bin/tree ; and function l  ; tree --dirsfirst -aFCNL 1 $argv ; end
test -x /usr/local/bin/tree ; and function ll ; tree --dirsfirst -ChFupDaLg 1 $argv ; end

# View files/dirs
# TODO: sudo pip install pygments
function cat
  set arg_count (count $argv)

  if math "$arg_count==0" > /dev/null
    tree --dirsfirst -aFCNL 1 ./
    return
  end

  for i in $argv
    set_color yellow
    if math "$arg_count>1" > /dev/null; echo "$i:" 1>&2; end
    set_color normal

    if test -e $i; and test -r $i
      if test -d $i
        tree --dirsfirst -aFCNL 1 $i
      else
        pygmentize -O style=monokai -f console256 -g $i
      end
    else
      set_color red
      echo "Cannot open: $i" 1>&2
    end

    set_color normal
  end
end

function l; cat $argv; end

# Gitconfig.user
test -e $HOME/.extra; and source $HOME/.extra

# Rust
test -e $HOME/.cargo/env and source $HOME/.cargo/env

# Ruby
# Load rbenv automatically by appending
test -x /usr/local/bin/rbenv; and rbenv init - | source

# Java
# See: http://stackoverflow.com/questions/1348842/what-should-i-set-java-home-to-on-osx
test -x /usr/libexec/java_home; and set JAVA_HOME (/usr/libexec/java_home)

# Golang
# Set workspace path
test -d $HOME/Documents/go_workspace; and set -x GOPATH $HOME/Documents/go_workspace
# Add the go bin path to be able to execute our programs
test -x /usr/local/go/bin; and set -x PATH $PATH /usr/local/bin/go $GOPATH/bin
