# https://github.com/fish-shell/fish-shell/issues/4103
function setenv
    set -gx $argv
end
