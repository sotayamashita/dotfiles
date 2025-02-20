# https://github.com/dalance/procs
function ps --wraps=procs --description 'Use procs if it is available'
    __fish_dynamic_alias ps "procs --tree" ps % $argv
end
