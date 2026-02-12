#!/usr/bin/env bash
# Simple integration test for RME_WORKING_DIR override
# Usage: ./scripts/test/test-rme-working-dir.sh [path/to/GOG/patchedfiles]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
GOG_DIR="${1:-$REPO_ROOT/GOG/patchedfiles}"
if [ ! -d "$GOG_DIR" ]; then
    echo "GOG patchedfiles directory not found at $GOG_DIR" >&2
    TS_BLOCK="$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$REPO_ROOT/development/RME/todo"
    BLOCKFILE="$REPO_ROOT/development/RME/todo/${TS_BLOCK}-blocking-rme-working-dir.md"
    cat >"$BLOCKFILE" <<EOF
# Blocking: GOG patchedfiles missing for RME working-dir test

**timestamp:** ${TS_BLOCK}
**reason:** GOG patchedfiles directory not found at path: ${GOG_DIR}

**action:** Please provide the authoritative patched files at ${GOG_DIR} so the RME validation harness can run.
EOF
    echo "Created blocking issue file: $BLOCKFILE" >&2
    exit 2
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
WORKDIR="$REPO_ROOT/tmp/rme-run-${TS}/work"
mkdir -p "$WORKDIR"

echo "Copying GOG patchedfiles -> $WORKDIR (rsync -a)"
rsync -a --delete "$GOG_DIR/" "$WORKDIR/"

# Build the app (build-macos script should put binary at build/fallout1-rebirth or build-macos path)
echo "Building app (this may take a bit)"
$REPO_ROOT/scripts/build/build-macos.sh --build-only

# Attempt to locate binary
BINARY=""
# Prefer build/fallout1-rebirth
if [ -x "$REPO_ROOT/build/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build/fallout1-rebirth"
elif [ -x "$REPO_ROOT/build-macos/RelWithDebInfo/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build-macos/RelWithDebInfo/fallout1-rebirth"
elif [ -x "$REPO_ROOT/build/RelWithDebInfo/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build/RelWithDebInfo/fallout1-rebirth"
fi

if [ -z "$BINARY" ]; then
    echo "Could not find built binary after build; expected at build/fallout1-rebirth or build-macos/RelWithDebInfo/fallout1-rebirth" >&2
    exit 3
fi

echo "Running binary in verify mode..."
# Ensure we capture stdout/stderr and run with a timeout
TMPDIR="$REPO_ROOT/tmp/rme-run-${TS}"
mkdir -p "$TMPDIR"

env -i PATH="$PATH" RME_WORKING_DIR="$WORKDIR/" RME_WORKING_DIR_VERIFY=1 "$BINARY" >"$TMPDIR/app.stdout" 2>"$TMPDIR/app.stderr" || true

# The process exits with code 0 if master.dat + critter.dat were found; our code writes rme-working-dir-verify.json in the working dir.
VERIFY_FILE="$WORKDIR/rme-working-dir-verify.json"

if [ -f "$VERIFY_FILE" ]; then
    echo "VERIFY FILE FOUND: $VERIFY_FILE"
    cat "$VERIFY_FILE"
    jq -e '."master.dat" == 1 and ."critter.dat" == 1' "$VERIFY_FILE" >/dev/null && echo "Verification OK" || (echo "Verification failed: missing files" && exit 4)
else
    echo "Verification file not created; check $TMPDIR/app.stdout and $TMPDIR/app.stderr" >&2
    exit 5
fi

echo "Running binary to capture rme.log (timeout 30s)"
# Run app with RME_LOG=all and a short timeout; capture separate outputs so we can inspect logs
APP_RME_STDOUT="$TMPDIR/app.rmelog.stdout"
APP_RME_STDERR="$TMPDIR/app.rmelog.stderr"

# Start the process in background, wait up to 30s, then kill it if still running
env -i PATH="$PATH" RME_WORKING_DIR="$WORKDIR/" RME_LOG=all "$BINARY" >"$APP_RME_STDOUT" 2>"$APP_RME_STDERR" &
PID=$!

SECS=30
for i in $(seq 1 "$SECS"); do
    if ! kill -0 "$PID" 2>/dev/null; then
        break
    fi
    sleep 1
done
# If still running, terminate
if kill -0 "$PID" 2>/dev/null; then
    echo "Process exceeded ${SECS}s timeout; killing PID $PID" >&2
    kill "$PID" || true
    sleep 2
    kill -9 "$PID" || true
fi
wait "$PID" 2>/dev/null || true

# Look for rme.log and the working-directory override message in likely locations
FOUND=0
SEARCH_STRING="working directory override"
CANDIDATES=("$WORKDIR/rme.log" "$REPO_ROOT/rme.log" "$TMPDIR/rme.log" "$TMPDIR/app.stdout" "$APP_RME_STDOUT" "$APP_RME_STDERR")
for f in "${CANDIDATES[@]}"; do
    if [ -f "$f" ] && grep -q "$SEARCH_STRING" "$f"; then
        echo "Found working directory override message in $f"
        FOUND=1
        break
    fi
done

if [ "$FOUND" -eq 0 ]; then
    echo "ERROR: Could not find working directory override message in rme.log or stdout/stderr" >&2
    echo "--- $TMPDIR/app.stdout ---"
    sed -n '1,200p' "$TMPDIR/app.stdout" || true
    echo "--- $APP_RME_STDOUT ---"
    sed -n '1,200p' "$APP_RME_STDOUT" || true
    echo "--- $APP_RME_STDERR ---"
    sed -n '1,200p' "$APP_RME_STDERR" || true
    echo "--- Listing $WORKDIR ---"
    ls -la "$WORKDIR" || true
    exit 6
fi

echo "Test complete. Artifacts in $TMPDIR and working copy at $WORKDIR"
exit 0
