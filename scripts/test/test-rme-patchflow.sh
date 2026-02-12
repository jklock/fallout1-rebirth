#!/usr/bin/env bash
# Orchestrator script for running RME patchflow selftests
# Usage: ./scripts/test/test-rme-patchflow.sh [--autorun-map] [path/to/GOG/patchedfiles]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
GOG_DIR="${2:-${1:-$REPO_ROOT/GOG/patchedfiles}}"
AUTORUN_MAP=0
if [ "${1:-}" = "--autorun-map" ]; then
    AUTORUN_MAP=1
    GOG_DIR="${2:-$REPO_ROOT/GOG/patchedfiles}"
fi

if [ ! -d "$GOG_DIR" ]; then
    echo "GOG patchedfiles directory not found at $GOG_DIR" >&2
    TS_BLOCK="$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$REPO_ROOT/development/RME/todo"
    BLOCKFILE="$REPO_ROOT/development/RME/todo/${TS_BLOCK}-blocking-rme-patchflow.md"
    cat >"$BLOCKFILE" <<EOF
# Blocking: GOG patchedfiles missing for RME patchflow orchestrator

**timestamp:** ${TS_BLOCK}
**reason:** GOG patchedfiles directory not found at path: ${GOG_DIR}

**action:** Please provide the authoritative patched files at ${GOG_DIR} so the RME validation harness can run.
EOF
    echo "Created blocking issue file: $BLOCKFILE" >&2
    exit 2
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
RUNDIR="$REPO_ROOT/tmp/rme-run-${TS}"
WORKDIR="$RUNDIR/work"
mkdir -p "$WORKDIR" "$RUNDIR"

echo "Copying GOG patchedfiles -> $WORKDIR (rsync -a)"
rsync -a --delete "$GOG_DIR/" "$WORKDIR/"

# Ensure minimal config files exist
if [ ! -f "$WORKDIR/fallout.cfg" ]; then
    if [ -f "$REPO_ROOT/gameconfig/macos/fallout.cfg" ]; then
        cp "$REPO_ROOT/gameconfig/macos/fallout.cfg" "$WORKDIR/fallout.cfg"
    fi
fi
if [ ! -f "$WORKDIR/f1_res.ini" ]; then
    if [ -f "$REPO_ROOT/gameconfig/macos/f1_res.ini" ]; then
        cp "$REPO_ROOT/gameconfig/macos/f1_res.ini" "$WORKDIR/f1_res.ini"
    fi
fi

# Build the app (low parallelism to avoid system pressure)
echo "Building macOS app (low parallelism)"
# Use build-macos.sh which invokes xcodebuild
$REPO_ROOT/scripts/build/build-macos.sh --build-only

# Locate binary inside app bundle or fallback
BINARY=""
if [ -x "$REPO_ROOT/build/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build/fallout1-rebirth"
elif [ -x "$REPO_ROOT/build-macos/RelWithDebInfo/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build-macos/RelWithDebInfo/fallout1-rebirth"
elif [ -x "$REPO_ROOT/build/RelWithDebInfo/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build/RelWithDebInfo/fallout1-rebirth"
elif [ -x "$REPO_ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
fi

if [ -z "$BINARY" ]; then
    echo "Could not find built binary after build; expected inside app bundle or build/RelWithDebInfo" >&2
    exit 3
fi

# Run the app with env overrides and limits
APP_STDOUT="$RUNDIR/app.stdout"
APP_STDERR="$RUNDIR/app.stderr"
RMELOG="$RUNDIR/rme.log"

echo "Running app (timeout 120s, ulimit 2GB where supported)"
# set memory limit (KB) to ~2GB
ulimit -v 2097152 || true

ENVVARS=(
    RME_WORKING_DIR="$WORKDIR"
    RME_SELFTEST=1
    RME_LOG=all
    RME_LOG_FILE="$RMELOG"
)
if [ "$AUTORUN_MAP" -eq 1 ]; then
    ENVVARS+=(F1R_AUTORUN_MAP=1)
fi

# Launch and wait with timeout
env -i PATH="$PATH" "${ENVVARS[@]}" "$BINARY" >"$APP_STDOUT" 2>"$APP_STDERR" &
PID=$!

SECS=120
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

# Collect artifacts: app stdout/stderr, rme.log, rme-selftest.json
ARTIFACTS=("$APP_STDOUT" "$APP_STDERR" "$RMELOG" "$WORKDIR/rme-selftest.json")
for f in "${ARTIFACTS[@]}"; do
    if [ -f "$f" ]; then
        echo "collected: $f"
    else
        echo "missing: $f"
    fi
done

# If parser exists, run it to produce rme-run-summary.json
PARSER="$REPO_ROOT/scripts/test/parse-rme-log.py"
SUMMARY="$RUNDIR/rme-run-summary.json"
if [ -x "$PARSER" ] || [ -f "$PARSER" ]; then
    echo "Running parse-rme-log.py"
    python3 "$PARSER" --rme-log "$RMELOG" --selftest "$WORKDIR/rme-selftest.json" --whitelist "$REPO_ROOT/development/RME/validation/whitelist.txt" --max-db-open-failures 0 --max-selftest-failures 0 > "$SUMMARY" 2>"$RUNDIR/parse.err" || true
else
    echo "Parser not found at $PARSER; skipping parse step"
fi

# Evaluate results: if parser returned non-zero or missing selftest+rme.log report failure
PASS=1
if [ -f "$SUMMARY" ]; then
    jq -e '.pass == true' "$SUMMARY" >/dev/null 2>&1 || PASS=0
else
    # Fallback: consider presence of rme-selftest.json with failures non-empty as failure
    if [ -f "$WORKDIR/rme-selftest.json" ]; then
        # crude check for "failures": [] empty
        if grep -q '"failures": \[\]' "$WORKDIR/rme-selftest.json"; then
            PASS=1
        else
            PASS=0
        fi
    else
        PASS=0
    fi
fi

# Copy canonical artifacts to run dir for inspection
mkdir -p "$RUNDIR/artifacts"
for f in "${ARTIFACTS[@]}"; do
    if [ -f "$f" ]; then
        cp "$f" "$RUNDIR/artifacts/" || true
    fi
done

# Persist canonical copy into development area only if requested by caller
mkdir -p "$REPO_ROOT/development/RME/validation/run-${TS}"
cp -a "$RUNDIR/artifacts" "$REPO_ROOT/development/RME/validation/run-${TS}/" || true

if [ "$PASS" -ne 1 ]; then
    echo "RME patchflow run FAILED; artifacts at $RUNDIR" >&2
    exit 1
fi

echo "RME patchflow run PASSED; artifacts at $RUNDIR"
exit 0
