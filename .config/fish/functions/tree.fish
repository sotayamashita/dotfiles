# https://github.com/eza-community/eza
function tree --wraps=eza --description 'Use eza if it is available'
    __fish_dynamic_alias tree "eza --tree --icons --color=auto" tree % $argv
end
