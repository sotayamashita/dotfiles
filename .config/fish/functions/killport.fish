function killport --description "Terminate processes listening on a TCP port"
    if test (count $argv) -ne 1
        echo "Usage: killport <port>" >&2
        return 2
    end

    if not string match -rq '^[0-9]{1,5}$' -- "$argv[1]"
        echo "killport: port must be an integer between 1 and 65535" >&2
        return 2
    end
    if test "$argv[1]" -lt 1; or test "$argv[1]" -gt 65535
        echo "killport: port must be an integer between 1 and 65535" >&2
        return 2
    end

    if not command -q lsof
        echo "killport: lsof is required" >&2
        return 1
    end

    set -l pids (command lsof -nP -t -iTCP:"$argv[1]" -sTCP:LISTEN | command sort -u)
    if test (count $pids) -eq 0
        echo "killport: no process listening on TCP port $argv[1]"
        return 0
    end

    command kill -TERM $pids
end
