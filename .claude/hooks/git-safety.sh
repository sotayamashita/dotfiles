#!/bin/sh
set -eu

# Reject literal --no-gpg-sign text and force-push command text.
# Quoted examples, messages and filenames can also match these checks.
# This does not inspect shell expansions or commands inside external scripts.
command=$(jq -er '.tool_input.command | strings') || {
    echo "Cannot read the command. Execution blocked." >&2
    exit 2
}

case "$command" in
    *--no-gpg-sign*)
        echo "Disabling commit signing is always forbidden." >&2
        exit 2
        ;;
esac

# Split simple command chains and inspect literal words without executing them.
if printf '%s\n' "$command" | tr "\"'" '  ' | tr ';|&' '\n' | awk '
    {
        git_seen = push_seen = 0
        for (i = 1; i <= NF; i++) {
            if ($i ~ /(^|\/)git$/) git_seen = 1
            if (git_seen && $i == "push") push_seen = 1
            if (!push_seen) continue
            if ($i ~ /^--force($|[-=])/ || $i == "--mirror" ||
                $i ~ /^-[^-]*f/ || $i ~ /^\+./) {
                blocked = 1
            }
        }
    }
    END { exit blocked ? 0 : 1 }
'; then
    echo "Force-push is always forbidden." >&2
    exit 2
fi

exit 0
