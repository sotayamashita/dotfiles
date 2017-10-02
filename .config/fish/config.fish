set fish_greeting

# Paths
test -d ~/.dotfiles/bin                                  ; and set PATH ~/.dotfiles/bin $PATH
test -d /usr/local/sbin                                  ; and set PATH /usr/local/sbin $PATH
test -e /usr/local/share/git-core/contrib/diff-highlight ; and set PATH /usr/local/share/git-core/contrib/diff-highlight $PATH

# Navigation
function ..    ; cd .. ; end
function ...   ; cd ../../ ; end
function ....  ; cd ../../../ ; end
function ..... ; cd ../../../../ ; end
function ......; cd ../../../../../ ; end
function dt    ; cd ~/Desktop ; end
function work  ; cd ~/Documents/workspace ; end
function src   ; cd ~/Documents/src ; end

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
function r         ; exec $SHELL -l ; end
function sniff     ; sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80' ; end
function t         ; command tree -C $argv ; end
function urlencode ; python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);" ; end
function v         ; vim ; end

# command which need extra library
test -e /usr/local/bin/hub  ; and function g  ; git $argv ; end
test -e /usr/local/bin/tree ; and function l  ; tree --dirsfirst -aFCNL 1 $argv ; end
test -e /usr/local/bin/tree ; and function ll ; tree --dirsfirst -ChFupDaLg 1 $argv ; end 


# View files/dirs
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
source ~/.extra

# Load rbenv automatically by appending
rbenv init - | source

# Load pyenv automatically by appending
# pyenv init -| source

# Java Home
# http://stackoverflow.com/questions/1348842/what-should-i-set-java-home-to-on-osx
export JAVA_HOME=(/usr/libexec/java_home)

