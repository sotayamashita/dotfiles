function clean-dev-deps --description "Preview or remove project dependencies and build caches"
    argparse --exclusive apply,dry-run h/help n/dry-run apply -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'Usage: clean-dev-deps [--apply | --dry-run] [directory ...]' \
            'Defaults to a preview of the current directory.' \
            'Targets: node_modules, .next, .turbo, .pnpm-store, .venv, .venv-paddle, .venv312' \
            'Skips symlinks, .git directories, and targets containing Git-tracked files.' \
            '--apply permanently deletes the listed directories.'
        return 0
    end

    command -q git
    or return 1

    set -q argv[1]; or set argv "$PWD"

    set -l roots
    for root in $argv
        if not test -d "$root"; or test -L "$root"
            printf 'clean-dev-deps: not a directory or is a symlink: %s\n' "$root" >&2
            return 2
        end

        set root (path resolve -Z -- "$root" | string split0)
        if contains -- "$root" / "$HOME"
            echo 'clean-dev-deps: choose a project directory, not / or HOME' >&2
            return 2
        end

        set -a roots "$root"
    end

    # Collect first so a failed search cannot trigger a partial cleanup.
    set -l candidates
    command find -P $roots -name .git -prune -o \
        -type d \( -name node_modules -o -name .next -o -name .turbo \
        -o -name .pnpm-store -o -name .venv -o -name .venv-paddle -o -name .venv312 \) \
        -prune -print0 | while read -lz target
        if not contains -- "$target" $candidates
            set -a candidates "$target"
        end
    end
    test $pipestatus[1] -eq 0; or return 1

    if not set -q candidates[1]
        echo 'clean-dev-deps: no matching directories'
        return 0
    end

    for target in $candidates
        if test -e "$target/.git"
            printf 'Skipped Git repository: %s\n' "$target"
            continue
        end

        if command git -C "$target" rev-parse --show-toplevel >/dev/null 2>&1
            set -l tracked (command git -C "$target" ls-files -- .)
            or return 1
            if set -q tracked[1]
                printf 'Skipped Git-tracked files: %s\n' "$target"
                continue
            end
        end

        if not set -q _flag_apply
            printf 'Would remove: %s\n' "$target"
            continue
        end

        command rm -r -- "$target" </dev/null
        or return 1
        printf 'Removed: %s\n' "$target"
    end
end
