# https://github.com/sharkdp/bat
function cat --wraps='bat' --description 'Use bat if it is available'
    __fish_dynamic_alias cat "bat --style=header,grid --theme=ansi" cat % $argv
end