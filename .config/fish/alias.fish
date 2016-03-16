# Navigation
function ..    ; cd .. ; end
function ...   ; cd ../../ ; end
function ....  ; cd ../../../ ; end
function ..... ; cd ../../../../ ; end
function l     ; tree --dirsfirst -aFCNL 1 $argv ; end
function ll    ; tree --dirsfirst -ChFupDaLg 1 $argv ; end

# Utilities
function g     ; git $argv ; end
function grep  ; command grep --color=auto $argv ; end

# `cat` with beautiful colors. requires Pygments installed.
#  Need - sudo easy_install -U Pygments
alias c='pygmentize -O style=monokai -f console256 -g'

# Networking. IP address, dig, DNS
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias dig="dig +nocmd any +multiline +noall +answer"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Recursively delete `.DS_Store` files
alias cleanup_dsstore="find . -name '*.DS_Store' -type f -ls -delete"

# Shortcuts
alias dt="cd ~/Desktop"
alias p="cd ~/Documents/projects"
alias src="cd ~/Documents/src"
alias j="jobs"
alias h="history"
alias git="hub"
alias g="git"
alias v="vim"
alias ungz="gunzip -k"
alias ssh=sshrc

# Empty the Trash on all mounted volumes and the main HDD. then clear the useless sleepimage
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; rm -rfv ~/.Trash; sudo rm /private/var/vm/sleepimage"

# URL-encode strings
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec $SHELL -l"
