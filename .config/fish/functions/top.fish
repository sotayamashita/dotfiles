# https://github.com/ClementTsang/bottom
function top --wraps=btm --description 'Use btm if it is available'
    __fish_dynamic_alias top "btm" top % $argv
end
