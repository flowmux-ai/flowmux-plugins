#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Run a Flowmux GUI with its own state and runtime directories, so a fix can
# be checked without touching the Flowmux the user is working in.
#
# Usage:
#   fm-isolated.sh start [GUI_BINARY]   # default: ./target/debug/flowmux
#   fm-isolated.sh stop ROOT            # stops only the process `start` created
#   fm-isolated.sh env                  # print exports for an isolated root
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

# Paths under a fresh root. /tmp keeps the socket path short enough on macOS.
isolate() {
    root=$(mktemp -d /tmp/fm-live.XXXXXX)
    mkdir -p "$root"/{tmp,run,config,state/flowmux,data,cache}
    chmod 700 "$root/run"
    # HOME stays the user's: skip onboarding and never refresh installed skills.
    touch "$root/state/flowmux/welcome-seen"
    echo 9999.0.0 > "$root/state/flowmux/installed-skill-version"
}

exports() {
    cat <<VARS
for v in \$(env | grep -o '^FLOWMUX_[A-Z_]*'); do unset "\$v"; done
unset CODEX_THREAD_ID CODEX_SESSION_ID CLAUDECODE CLAUDE_CODE_ENTRYPOINT
unset CLAUDE_CONFIG_DIR CODEX_HOME GEMINI_CLI_HOME
export TMPDIR='$root/tmp' FLOWMUX_RUNTIME_DIR='$root/run' XDG_RUNTIME_DIR='$root/run'
export XDG_CONFIG_HOME='$root/config' XDG_STATE_HOME='$root/state'
export XDG_DATA_HOME='$root/data' XDG_CACHE_HOME='$root/cache'
export FM_ISOLATED_ROOT='$root'
VARS
}

case ${1:-} in
start)
    gui=${2:-$PWD/target/debug/flowmux}
    [[ -x $gui ]] || die "no GUI binary at $gui (run cargo build --workspace)"
    gui=$(cd "$(dirname "$gui")" && pwd)/$(basename "$gui")
    isolate
    eval "$(exports)"
    export PATH="$(dirname "$gui"):$PATH"
    (cd "$root" && exec nohup "$gui" >"$root/gui.log" 2>&1) &
    pid=$!
    echo "$pid" > "$root/pid"
    echo "$gui" > "$root/gui"
    socket="$root/run/flowmux-$pid.sock"
    for _ in $(seq 1 240); do
        [[ -S $socket ]] && break
        kill -0 "$pid" 2>/dev/null || die "GUI exited during startup; see $root/gui.log"
        sleep 0.25
    done
    [[ -S $socket ]] || die "no socket after 60s; see $root/gui.log (pid $pid still running)"
    printf 'ROOT=%s\nPID=%s\nSOCKET=%s\n' "$root" "$pid" "$socket"
    ;;
stop)
    root=${2:-}
    [[ $root == /tmp/fm-live.* && -f $root/pid ]] || die "not an isolated root: $root"
    pid=$(<"$root/pid")
    # The PID may have been reused; only signal the binary this root started.
    if [[ $(ps -o command= -p "$pid" 2>/dev/null) == "$(<"$root/gui")"* ]]; then
        kill -TERM "$pid"
        for _ in $(seq 1 40); do kill -0 "$pid" 2>/dev/null || break; sleep 0.25; done
        kill -0 "$pid" 2>/dev/null && kill -KILL "$pid"
    fi
    echo "stopped $pid; evidence kept in $root"
    ;;
env)
    isolate
    exports
    ;;
*)
    sed -n '3,10p' "$0" >&2
    exit 2
    ;;
esac
