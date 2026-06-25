function __gwt_usage
    printf '%s\n' \
        'Usage:' \
        '  gwt <branch>              Go to an existing worktree or create one' \
        '  gwt pr <number>           Go to or create a worktree for a GitHub PR' \
        '  gwt list                  List worktrees' \
        '  gwt path <branch>         Print the worktree path for a branch' \
        '  gwt rm <branch-or-path>   Remove a clean worktree' \
        '  gwt rm --force <target>   Remove a dirty worktree explicitly' \
        '' \
        'Defaults:' \
        '  Worktrees are created under $GWT_HOME/<repo-name>/<branch-slug>, or ~/.worktrees when unset.' \
        '  Missing branches start from $GWT_BASE_REF, origin/HEAD, origin/main, or HEAD.'
end

function __gwt_slug
    set -l slug (string replace -ra '[^A-Za-z0-9._-]+' '-' -- $argv[1])
    string replace -ra '(^-+|-+$)' '' -- $slug
end

function __gwt_repo_root
    command git rev-parse --show-toplevel 2>/dev/null
end

function __gwt_branch_exists
    command git show-ref --verify --quiet "refs/heads/$argv[1]"
end

function __gwt_remote_branch_exists
    command git show-ref --verify --quiet "refs/remotes/origin/$argv[1]"
end

function __gwt_base_ref
    if set -q GWT_BASE_REF; and test -n "$GWT_BASE_REF"
        printf '%s\n' "$GWT_BASE_REF"
        return 0
    end

    set -l origin_head (command git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
    if test -n "$origin_head"
        printf '%s\n' "$origin_head"
        return 0
    end

    for candidate in origin/main origin/master main master
        if command git rev-parse --verify --quiet "$candidate^{commit}" >/dev/null 2>/dev/null
            printf '%s\n' "$candidate"
            return 0
        end
    end

    printf '%s\n' HEAD
end

function __gwt_resolve_branch
    set -l name $argv[1]

    if string match -q 'refs/heads/*' -- $name
        string replace 'refs/heads/' '' -- $name
        return 0
    end

    if __gwt_branch_exists "$name"
        printf '%s\n' "$name"
        return 0
    end

    if __gwt_remote_branch_exists "$name"
        printf '%s\n' "$name"
        return 0
    end

    if string match -q '*/*' -- $name
        printf '%s\n' "$name"
        return 0
    end

    printf '%s\n' "$name"
end

function __gwt_worktree_path_for_branch
    set -l root (__gwt_repo_root)
    or return 1

    set -l base "$HOME/.worktrees"
    if set -q GWT_HOME; and test -n "$GWT_HOME"
        set base "$GWT_HOME"
    end

    set -l repo_name (basename "$root")
    set -l repo_key (__gwt_slug "$repo_name")
    set -l branch_key (__gwt_slug "$argv[1]")

    printf '%s\n' "$base/$repo_key/$branch_key"
end

function __gwt_worktree_for_branch
    set -l wanted "refs/heads/$argv[1]"
    set -l current_path

    command git worktree list --porcelain | while read -l line
        if string match -qr '^worktree ' -- "$line"
            set current_path (string replace 'worktree ' '' -- "$line")
        else if test "$line" = "branch $wanted"
            printf '%s\n' "$current_path"
            return 0
        end
    end
end

function __gwt_add_worktree_for_branch
    set -l branch $argv[1]
    set -l path (__gwt_worktree_path_for_branch "$branch")
    or return 1

    if test -e "$path"
        printf 'gwt: path already exists: %s\n' "$path" >&2
        return 1
    end

    command mkdir -p (dirname "$path")
    or return 1

    if __gwt_branch_exists "$branch"
        command git worktree add "$path" "$branch" >&2
        or return 1
    else if __gwt_remote_branch_exists "$branch"
        command git worktree add --track -b "$branch" "$path" "origin/$branch" >&2
        or return 1
    else
        set -l base_ref (__gwt_base_ref)
        command git worktree add -b "$branch" "$path" "$base_ref" >&2
        or return 1
    end

    printf '%s\n' "$path"
end

function __gwt_enter_branch
    if test (count $argv) -ne 1
        __gwt_usage >&2
        return 2
    end

    set -l branch (__gwt_resolve_branch "$argv[1]")
    set -l existing_path (__gwt_worktree_for_branch "$branch")

    if test -n "$existing_path"
        cd "$existing_path"
        return $status
    end

    set -l path (__gwt_add_worktree_for_branch "$branch")
    or return 1

    cd "$path"
end

function __gwt_fetch_same_repo_pr_branch
    set -l branch $argv[1]

    if __gwt_branch_exists "$branch"; or __gwt_remote_branch_exists "$branch"
        return 0
    end

    command git fetch origin "$branch:refs/remotes/origin/$branch"
end

function __gwt_enter_pr
    if test (count $argv) -ne 1
        printf 'gwt: expected a pull request number\n' >&2
        return 2
    end

    if not command -q gh
        printf 'gwt: gh is required for PR worktrees\n' >&2
        return 1
    end

    set -l number $argv[1]
    set -l info (command gh pr view "$number" --json headRefName,isCrossRepository --jq '[.headRefName, (.isCrossRepository | tostring)] | @tsv' 2>/dev/null)
    or begin
        printf 'gwt: failed to read PR #%s with gh\n' "$number" >&2
        return 1
    end

    set -l fields (string split \t -- "$info")
    set -l head_branch $fields[1]
    set -l is_cross_repo $fields[2]

    if test -z "$head_branch"
        printf 'gwt: PR #%s did not return a head branch\n' "$number" >&2
        return 1
    end

    set -l branch "$head_branch"
    if test "$is_cross_repo" = true
        set branch "pr/$number"
    else
        __gwt_fetch_same_repo_pr_branch "$branch"
        or return 1
    end

    set -l existing_path (__gwt_worktree_for_branch "$branch")
    if test -n "$existing_path"
        cd "$existing_path"
        return $status
    end

    if test "$is_cross_repo" = true; and not __gwt_branch_exists "$branch"
        command git fetch origin "pull/$number/head:refs/heads/$branch"
        or begin
            printf 'gwt: failed to fetch PR #%s from origin/pull/%s/head\n' "$number" "$number" >&2
            return 1
        end
    end

    set -l path (__gwt_add_worktree_for_branch "$branch")
    or return 1

    cd "$path"
end

function __gwt_print_path
    if test (count $argv) -ne 1
        printf 'gwt: expected a branch name\n' >&2
        return 2
    end

    set -l branch (__gwt_resolve_branch "$argv[1]")
    set -l path (__gwt_worktree_for_branch "$branch")

    if test -z "$path"
        printf 'gwt: no worktree found for %s\n' "$branch" >&2
        return 1
    end

    printf '%s\n' "$path"
end

function __gwt_remove
    set -l force 0
    set -l target

    for arg in $argv
        switch $arg
            case -f --force
                set force 1
            case '*'
                if test -n "$target"
                    printf 'gwt: expected one remove target\n' >&2
                    return 2
                end
                set target "$arg"
        end
    end

    if test -z "$target"
        printf 'gwt: expected a branch or path to remove\n' >&2
        return 2
    end

    set -l path
    if test -d "$target"
        set path "$target"
    else
        set -l branch (__gwt_resolve_branch "$target")
        set path (__gwt_worktree_for_branch "$branch")
        if test -z "$path"
            printf 'gwt: no worktree found for %s\n' "$branch" >&2
            return 1
        end
    end

    set -l changes (command git -C "$path" status --short --untracked-files=all)
    if test -n "$changes"; and test "$force" -ne 1
        printf 'gwt: worktree is dirty, refusing to remove: %s\n' "$path" >&2
        printf '%s\n' $changes >&2
        printf 'gwt: rerun with --force to remove it explicitly\n' >&2
        return 1
    end

    if test "$force" -eq 1
        command git worktree remove --force "$path"
    else
        command git worktree remove "$path"
    end
end

function gwt --description 'Go to or create Git worktrees'
    if test (count $argv) -eq 0
        __gwt_usage >&2
        return 2
    end

    switch $argv[1]
        case -h --help help
            __gwt_usage
        case list ls
            command git worktree list -v
        case path
            __gwt_print_path $argv[2..]
        case rm remove delete
            __gwt_remove $argv[2..]
        case pr
            __gwt_enter_pr $argv[2..]
        case '*'
            __gwt_enter_branch $argv
    end
end
