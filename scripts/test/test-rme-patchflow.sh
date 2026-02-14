#!/usr/bin/env bash
# Orchestrator script for running RME patchflow selftests
# Usage: ./scripts/test/test-rme-patchflow.sh [--autorun-map <MAPNAME.MAP>] [path/to/patched-data]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
RME_STATE_DIR="${RME_STATE_DIR:-$REPO_ROOT/tmp/rme}"
RME_RUN_ROOT="${RME_RUN_ROOT:-$REPO_ROOT/tmp}"
GAMEFILES_ROOT="${FALLOUT_GAMEFILES_ROOT:-${GAMEFILES_ROOT:-}}"
DEFAULT_DATA_DIR="${GAME_DATA:-}"
if [[ -z "$DEFAULT_DATA_DIR" && -n "$GAMEFILES_ROOT" ]]; then
    DEFAULT_DATA_DIR="$GAMEFILES_ROOT/patchedfiles"
fi
# CLI flags: [--autorun-map <MAPNAME.MAP>] [--auto-fix] [--auto-fix-iterations N] [--auto-fix-apply] [--auto-fix-apply-whitelist] [--skip-build]
AUTO_FIX=0
AUTO_FIX_ITERATIONS=3
AUTO_FIX_APPLY=0
AUTO_FIX_APPLY_WHITELIST=0
DATA_DIR="$DEFAULT_DATA_DIR"
AUTORUN_MAP_NAME=""
APP_TIMEOUT_SECS="${APP_TIMEOUT_SECS:-120}"

# Simple parsing for the optional flags (preserve positional behavior for data directory)
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --autorun-map)
            if [[ "${2:-}" != "" && "${2:-}" != -* ]]; then
                AUTORUN_MAP_NAME="$2"
                shift 2
            else
                AUTORUN_MAP_NAME="${AUTORUN_MAP_NAME:-V13ENT.MAP}"
                shift
            fi
            ;;
        --auto-fix)
            AUTO_FIX=1
            shift
            ;;
        --auto-fix-iterations)
            AUTO_FIX_ITERATIONS="$2"
            shift 2
            ;;
        --auto-fix-apply)
            AUTO_FIX_APPLY=1
            shift
            ;;
        --auto-fix-apply-whitelist)
            AUTO_FIX_APPLY_WHITELIST=1
            shift
            ;;
        --skip-build)
            echo "Warning: --skip-build is deprecated; tests never build." >&2
            shift
            ;;
        --data-dir)
            DATA_DIR="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
        *)
            # First non-option arg is the DATA_DIR
            DATA_DIR="${1}"
            shift
            # Remaining args are ignored for now
            break
            ;;
    esac
done

if [[ -z "${DATA_DIR:-}" ]]; then
    echo "Missing patched data directory. Pass it as an argument or set GAME_DATA/FALLOUT_GAMEFILES_ROOT." >&2
    exit 2
fi

if [ ! -d "$DATA_DIR" ]; then
    echo "Patched data directory not found at $DATA_DIR" >&2
    TS_BLOCK="$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$RME_STATE_DIR/todo"
    BLOCKFILE="$RME_STATE_DIR/todo/${TS_BLOCK}-blocking-rme-patchflow.md"
    cat >"$BLOCKFILE" <<EOF
# Blocking: patched data missing for RME patchflow orchestrator

**timestamp:** ${TS_BLOCK}
**reason:** Patched data directory not found at path: ${DATA_DIR}

**action:** Provide a patched data directory containing master.dat, critter.dat, and data/ at ${DATA_DIR} so the RME validation harness can run.
EOF
    echo "Created blocking issue file: $BLOCKFILE" >&2
    exit 2
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
RUNDIR="$RME_RUN_ROOT/rme-run-${TS}"
WORKDIR="$RUNDIR/work"
mkdir -p "$WORKDIR" "$RUNDIR"

echo "Copying patched data -> $WORKDIR (rsync -a)"
rsync -a --delete "$DATA_DIR/" "$WORKDIR/"

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

# Locate binary inside app bundle or fallback. Test harness may set TEST_FALLBACK_BINARY to point to a fake binary for integration tests.
BINARY=""
if [ -n "${TEST_FALLBACK_BINARY:-}" ] && [ -x "${TEST_FALLBACK_BINARY}" ]; then
    BINARY="${TEST_FALLBACK_BINARY}"
elif [ -x "$REPO_ROOT/build/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build/fallout1-rebirth"
elif [ -x "$REPO_ROOT/build-macos/RelWithDebInfo/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build-macos/RelWithDebInfo/fallout1-rebirth"
elif [ -x "$REPO_ROOT/build/RelWithDebInfo/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build/RelWithDebInfo/fallout1-rebirth"
elif [ -x "$REPO_ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" ]; then
    BINARY="$REPO_ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
fi

if [ -z "$BINARY" ]; then
    echo "Could not find an existing build binary; expected inside app bundle or build/RelWithDebInfo" >&2
    echo "Build first with: ./scripts/build/build-macos.sh" >&2
    exit 3
fi

# Run the app with env overrides and limits
APP_STDOUT="$RUNDIR/app.stdout"
APP_STDERR="$RUNDIR/app.stderr"
RMELOG="$RUNDIR/rme.log"

echo "Running app (timeout 120s, ulimit 2GB where supported)"
# set memory limit (KB) to ~2GB
ulimit -v 2097152 >/dev/null 2>&1 || true

ENVVARS=(
    RME_WORKING_DIR="$WORKDIR"
    RME_SELFTEST=1
    RME_LOG="${RME_LOG_TOPICS:-all}"
    RME_LOG_FILE="$RMELOG"
)
if [[ -n "$AUTORUN_MAP_NAME" ]]; then
    ENVVARS+=(F1R_AUTORUN_MAP="$AUTORUN_MAP_NAME")
fi

# Launch and wait with timeout
env -i PATH="$PATH" "${ENVVARS[@]}" "$BINARY" >"$APP_STDOUT" 2>"$APP_STDERR" &
PID=$!

SECS="$APP_TIMEOUT_SECS"
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
PARSER="$REPO_ROOT/scripts/test/test-rme-parse-log.py"
SUMMARY="$RUNDIR/rme-run-summary.json"
if [ -x "$PARSER" ] || [ -f "$PARSER" ]; then
    echo "Running test-rme-parse-log.py"
    python3 "$PARSER" --rme-log "$RMELOG" --selftest "$WORKDIR/rme-selftest.json" --whitelist "$RME_STATE_DIR/validation/whitelist.txt" --max-db-open-failures 0 --max-selftest-failures 0 > "$SUMMARY" 2>"$RUNDIR/parse.err" || true
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

# Copy key artifacts to run dir for inspection
mkdir -p "$RUNDIR/artifacts"
for f in "${ARTIFACTS[@]}"; do
    if [ -f "$f" ]; then
        cp "$f" "$RUNDIR/artifacts/" || true
    fi
done

# Persist artifacts into the RME state area for inspection
mkdir -p "$RME_STATE_DIR/validation/run-${TS}"
cp -a "$RUNDIR/artifacts" "$RME_STATE_DIR/validation/run-${TS}/" || true

if [ "$PASS" -ne 1 ]; then
    echo "RME patchflow run FAILED; artifacts at $RUNDIR" >&2

    if [ "$AUTO_FIX" -eq 1 ]; then
        echo "Auto-fix enabled; snapshotting original artifacts"
        # Use rsync to snapshot artifacts, excluding previously created snapshots to avoid recursion
        mkdir -p "$RUNDIR/artifacts/original"
        rsync -a --exclude 'original' "$RUNDIR/artifacts/" "$RUNDIR/artifacts/original/" || true

        # Invoke autofix engine
        echo "Invoking test-rme-autofix.py (iterations=${AUTO_FIX_ITERATIONS}, apply=${AUTO_FIX_APPLY}, apply-whitelist=${AUTO_FIX_APPLY_WHITELIST})"
        PYTHON=python3
        "$PYTHON" "$REPO_ROOT/scripts/test/test-rme-autofix.py" --workdir "$WORKDIR" --iterations "$AUTO_FIX_ITERATIONS" $( [ "$AUTO_FIX_APPLY" -eq 1 ] && echo "--apply" ) $( [ "$AUTO_FIX_APPLY_WHITELIST" -eq 1 ] && echo "--apply-whitelist" ) --verbose
        AUTOFIX_RC=$?

        # Collect per-iter artifacts if present
        if [ -d "$WORKDIR/fixes" ]; then
            mkdir -p "$RUNDIR/artifacts/fixes/proposed"
            cp -a "$WORKDIR/fixes" "$RUNDIR/artifacts/" || true
        fi

        # If rme-autofix succeeded (exit 0) treat it as pass
        if [ "$AUTOFIX_RC" -eq 0 ]; then
            echo "PASS achieved after autofix; artifacts at $RUNDIR"
            exit 0
        fi

        echo "Autofix completed but run still failing; see proposed fixes under $RUNDIR/artifacts/fixes/proposed" >&2
        exit 1
    fi

    exit 1
fi

echo "RME patchflow run PASSED; artifacts at $RUNDIR"
exit 0
