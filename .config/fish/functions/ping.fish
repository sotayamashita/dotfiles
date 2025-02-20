# https://github.com/denilsonsa/prettyping
function ping --wraps=prettyping --description 'Use prettyping if it is available'
    __fish_dynamic_alias ping "prettyping --nolegend" ping % $argv
end
