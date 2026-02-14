#!/usr/bin/env bash
# Orchestrator script for running RME patchflow selftests
# Usage: ./scripts/rme/test-rme-patchflow.sh [--autorun-map] [path/to/GOG/patchedfiles]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
RME_STATE_DIR="${RME_STATE_DIR:-$REPO_ROOT/tmp/rme}"
CANONICAL_GOG_DIR="$REPO_ROOT/GOG/patchedfiles"
# CLI flags: [--autorun-map] [--auto-fix] [--auto-fix-iterations N] [--auto-fix-apply] [--auto-fix-apply-whitelist] [--skip-build]
AUTO_FIX=0
AUTO_FIX_ITERATIONS=3
AUTO_FIX_APPLY=0
AUTO_FIX_APPLY_WHITELIST=0
SKIP_BUILD=0
GOG_DIR="${2:-${1:-$CANONICAL_GOG_DIR}}"
AUTORUN_MAP=0

# Simple parsing for the optional flags (preserve positional behavior for GOG directory)
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --autorun-map)
            AUTORUN_MAP=1
            shift
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
            SKIP_BUILD=1
            shift
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
            # First non-option arg is the GOG_DIR
            GOG_DIR="${1}"
            shift
            # Remaining args are ignored for now
            break
            ;;
    esac
done

if [ "${AUTORUN_MAP}" -eq 1 ]; then
    GOG_DIR="${GOG_DIR:-$CANONICAL_GOG_DIR}"
fi

if [[ "$GOG_DIR" != "$CANONICAL_GOG_DIR" && "${RME_ALLOW_NON_CANONICAL_GAME_DATA:-0}" != "1" ]]; then
    echo "Non-canonical game data path blocked for RME validation: $GOG_DIR" >&2
    echo "Use canonical path: $CANONICAL_GOG_DIR" >&2
    exit 2
fi

if [ ! -d "$GOG_DIR" ]; then
    echo "GOG patchedfiles directory not found at $GOG_DIR" >&2
    TS_BLOCK="$(date -u +%Y%m%dT%H%M%SZ)"
    mkdir -p "$RME_STATE_DIR/todo"
    BLOCKFILE="$RME_STATE_DIR/todo/${TS_BLOCK}-blocking-rme-patchflow.md"
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
PARSER="$REPO_ROOT/scripts/rme/parse-rme-log.py"
SUMMARY="$RUNDIR/rme-run-summary.json"
if [ -x "$PARSER" ] || [ -f "$PARSER" ]; then
    echo "Running parse-rme-log.py"
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

# Copy canonical artifacts to run dir for inspection
mkdir -p "$RUNDIR/artifacts"
for f in "${ARTIFACTS[@]}"; do
    if [ -f "$f" ]; then
        cp "$f" "$RUNDIR/artifacts/" || true
    fi
done

# Persist canonical copy into the RME state area for inspection
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
        echo "Invoking rme-autofix.py (iterations=${AUTO_FIX_ITERATIONS}, apply=${AUTO_FIX_APPLY}, apply-whitelist=${AUTO_FIX_APPLY_WHITELIST})"
        PYTHON=python3
        "$PYTHON" "$REPO_ROOT/scripts/rme/rme-autofix.py" --workdir "$WORKDIR" --iterations "$AUTO_FIX_ITERATIONS" $( [ "$AUTO_FIX_APPLY" -eq 1 ] && echo "--apply" ) $( [ "$AUTO_FIX_APPLY_WHITELIST" -eq 1 ] && echo "--apply-whitelist" ) --verbose
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
