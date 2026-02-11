#!/usr/bin/env bash
# RME logging sweep runner (macOS)
# Uses only project scripts and captures per-topic rme.log snapshots.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_NAME="Fallout 1 Rebirth"
BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
APP_DIR="$REPO_ROOT/$BUILD_DIR/$BUILD_TYPE/$APP_NAME.app/Contents/MacOS"
APP_BIN="$APP_DIR/fallout1-rebirth"
LOG_DIR="$REPO_ROOT/tmp/rme-log-sweep"
RUNTIME="${RUNTIME:-20}" # seconds per run
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
    miss=$(grep -i "dat miss" "$file" | wc -l | tr -d ' ')
    casec=$(grep -i -E "case_mismatch=[1-9]" "$file" | wc -l | tr -d ' ')
    echo "==> $(basename "$file") missing_lines=$miss case_lines=$casec"
}

run_game() {
    local label="$1"
    local topics="$2"

    echo "--- run $label topics=$topics ---"
    rm -f "$APP_DIR/rme.log" "$APP_DIR/rme.log.1"

    if [[ -n "$TIMEOUT_BIN" ]]; then
        (cd "$APP_DIR" && RME_LOG="$topics" "$TIMEOUT_BIN" "$RUNTIME" "$APP_BIN") || true
    else
        (
            cd "$APP_DIR" || exit
            exec env RME_LOG="$topics" "$APP_BIN"
        ) &
        local pid=$!
        sleep "$RUNTIME"
        kill "$pid" 2>/dev/null || true
        sleep 1
        kill -KILL "$pid" 2>/dev/null || true
    fi

    if [[ -f "$APP_DIR/rme.log" ]]; then
        mkdir -p "$LOG_DIR"
        local dst="$LOG_DIR/${label}.log"
        cp "$APP_DIR/rme.log" "$dst"
        summarize "$dst"
    else
        echo "!! rme.log not produced for $label"
    fi
}

main() {
    cd "$REPO_ROOT"

    echo "[1/4] Build macOS"
    ./scripts/build/build-macos.sh

    echo "[2/4] Headless sanity"
    ./scripts/test/test-macos-headless.sh

    echo "[3/4] Locate app"
    if [[ ! -x "$APP_BIN" ]]; then
        echo "App binary not found at $APP_BIN" >&2
        exit 1
    fi

    pick_timeout
    echo "Using timeout: ${TIMEOUT_BIN:-none} (runtime ${RUNTIME}s)"

    echo "[4/4] Topic sweeps"
    run_game "all" "1"
    run_game "fonts_text_art" "text,art"
    run_game "movies" "movie"
    run_game "map_script_proto" "map,script,proto"
    run_game "text" "text"
    run_game "art" "art"
    run_game "sound" "sound"
    run_game "save" "save"
    run_game "db_config" "db,config"

    echo "Logs stored in $LOG_DIR"
}

main "$@"
