# https://github.com/eza-community/eza
function ls --wraps=eza --description 'Use eza if it is available'
    # Modern replacement for ls using eza (formerly exa)
    # Uses eza if available, falls back to exa, then to standard ls
    __fish_dynamic_alias ls "eza -al -hg --icons --color=auto" ls -al --color=auto % $argv
end