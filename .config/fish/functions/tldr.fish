# https://github.com/tealdeer-rs/tealdeer
function tldr --wraps=tldr --description 'Use tldr if it is available'
    __fish_dynamic_alias tldr "tldr --color=auto" tldr % $argv
end
