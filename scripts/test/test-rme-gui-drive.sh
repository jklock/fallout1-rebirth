#!/usr/bin/env bash
# RME GUI exercise runner (macOS)
# Builds, sanity-checks, launches the GUI with RME_LOG=1, drives basic keys, and captures rme.log.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_NAME="Fallout 1 Rebirth"
BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
APP_DIR="$REPO_ROOT/$BUILD_DIR/$BUILD_TYPE/$APP_NAME.app/Contents/MacOS"
APP_BIN="$APP_DIR/fallout1-rebirth"
LOG_DIR="${LOG_DIR:-$REPO_ROOT/tmp/rme-log-sweep}"
RUNTIME="${RUNTIME:-25}" # seconds to allow app to run
TIMEOUT_BIN=""

pick_timeout() {
    if command -v gtimeout >/dev/null 2>&1; then
        TIMEOUT_BIN="gtimeout"
    elif command -v timeout >/dev/null 2>&1; then
        TIMEOUT_BIN="timeout"
    else
        TIMEOUT_BIN=""
    fi
}

summarize() {
    local file="$1"
    local miss casec
    miss=$(grep -i -E "dat miss|missing" "$file" | wc -l | tr -d ' ')
    casec=$(grep -i "case" "$file" | wc -l | tr -d ' ')
    echo "==> $(basename "$file") missing_lines=$miss case_lines=$casec"
}

send_mouse_clicks() {
    /usr/bin/osascript <<'EOF'
    tell application "System Events"
        -- wait for process
        repeat 30 times
            if exists process "Fallout 1 Rebirth" then exit repeat
            delay 0.5
        end repeat
        if not (exists process "Fallout 1 Rebirth") then return
        set frontmost of process "Fallout 1 Rebirth" to true
        delay 1
        -- simple clicks: center to skip intro, then menu area clicks
        click at {960, 540}
        delay 1
        click at {960, 780}
        delay 0.5
        click at {960, 840}
    end tell
EOF
}

run_gui() {
    echo "--- GUI run with RME_LOG=1 ---"
    rm -f "$APP_DIR/rme.log" "$APP_DIR/rme.log.1"

    if [[ -n "$TIMEOUT_BIN" ]]; then
        (cd "$APP_DIR" && RME_LOG=1 "$TIMEOUT_BIN" "$RUNTIME" "$APP_BIN") &
    else
        (cd "$APP_DIR" && RME_LOG=1 "$APP_BIN") &
    fi
    app_pid=$!

    # drive a few UI inputs (mouse clicks)
    send_mouse_clicks || true

    sleep "$RUNTIME"
    kill "$app_pid" 2>/dev/null || true
    sleep 1
    kill -KILL "$app_pid" 2>/dev/null || true

    if [[ -f "$APP_DIR/rme.log" ]]; then
        mkdir -p "$LOG_DIR"
        local dst="$LOG_DIR/gui.log"
        cp "$APP_DIR/rme.log" "$dst"
        summarize "$dst"
    else
        echo "!! rme.log not produced"
    fi
}

main() {
    cd "$REPO_ROOT"

    echo "[1/5] Build macOS"
    ./scripts/build/build-macos.sh

    echo "[2/5] macOS verify"
    ./scripts/test/test-macos.sh --verify

    echo "[3/5] Locate app"
    if [[ ! -x "$APP_BIN" ]]; then
        echo "App binary not found at $APP_BIN" >&2
        exit 1
    fi

    pick_timeout
    echo "Using timeout: ${TIMEOUT_BIN:-none} (runtime ${RUNTIME}s)"

    echo "[4/5] GUI exercise"
    run_gui

    echo "[5/5] Logs stored in $LOG_DIR"
}

main "$@"
