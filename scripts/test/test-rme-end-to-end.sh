#!/usr/bin/env bash
# End-to-end RME validation run:
# - apply patches when needed
# - validate patch artifacts
# - sweep all asset domains (maps/audio/critters/proto/scripts/text/art)
# - run full runtime MAP sweep with max logging enabled
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GAMEFILES_ROOT="${FALLOUT_GAMEFILES_ROOT:-${GAMEFILES_ROOT:-}}"

BASE_DIR="${BASE_DIR:-${UNPATCHED_DIR:-}}"
PATCHED_DIR="${PATCHED_DIR:-${GAME_DATA:-}}"

if [[ -z "$BASE_DIR" && -n "$GAMEFILES_ROOT" ]]; then
    BASE_DIR="$GAMEFILES_ROOT/unpatchedfiles"
fi
if [[ -z "$PATCHED_DIR" && -n "$GAMEFILES_ROOT" ]]; then
    PATCHED_DIR="$GAMEFILES_ROOT/patchedfiles"
fi

if [[ -d "$ROOT/third_party/rme" ]]; then
    RME_DIR="${RME_DIR:-$ROOT/third_party/rme}"
else
    RME_DIR="${RME_DIR:-$ROOT/third_party/rme/source}"
fi

CONFIG_DIR="${CONFIG_DIR:-$ROOT/gameconfig/macos}"
OUT_DIR="${OUT_DIR:-$ROOT/tmp/rme/final-e2e}"
VALIDATION_DIR_OVERRIDE="${VALIDATION_DIR:-}"
RUNTIME_DIR_OVERRIDE="${RUNTIME_DIR:-}"
ASSET_DIR_OVERRIDE="${ASSET_DIR:-}"
LOG_SWEEP_DIR_OVERRIDE="${LOG_SWEEP_DIR:-}"

APP="${APP:-$ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app}"
EXE="${EXE:-$APP/Contents/MacOS/fallout1-rebirth}"

TIMEOUT="${TIMEOUT:-60}"
RUN_IOS="${RUN_IOS:-0}"
REBUILD_PATCHED="${REBUILD_PATCHED:-0}"
FORCE_PATCH="${FORCE_PATCH:-0}"
SKIP_CHECKSUMS="${SKIP_CHECKSUMS:-0}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --base <dir>        Unpatched data root (master.dat/critter.dat/data)
  --patched <dir>     Patched data root (master.dat/critter.dat/data)
  --rme <dir>         RME payload directory
  --config-dir <dir>  Config template directory
  --out <dir>         Output root for reports/logs
  --timeout <sec>     Per-map runtime timeout for map sweep (default: ${TIMEOUT})
  --rebuild-patched   Force patch-data rebuild before validation
  --force-patch       Pass --force to patch-rebirth-data.sh
  --skip-checksums    Pass --skip-checksums to patch-rebirth-data.sh
  --run-ios           Also run iOS headless/simulator tests (best effort)
  --help              Show this message
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base) BASE_DIR="$2"; shift 2 ;;
        --patched) PATCHED_DIR="$2"; shift 2 ;;
        --rme) RME_DIR="$2"; shift 2 ;;
        --config-dir) CONFIG_DIR="$2"; shift 2 ;;
        --out) OUT_DIR="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --rebuild-patched) REBUILD_PATCHED=1; shift ;;
        --force-patch) FORCE_PATCH=1; shift ;;
        --skip-checksums) SKIP_CHECKSUMS=1; shift ;;
        --run-ios) RUN_IOS=1; shift ;;
        --help|-h) usage; exit 0 ;;
        *)
            echo "[ERROR] Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -z "$BASE_DIR" || -z "$PATCHED_DIR" ]]; then
    echo "[ERROR] Missing BASE_DIR/PATCHED_DIR. Set --base/--patched or FALLOUT_GAMEFILES_ROOT." >&2
    exit 2
fi

VALIDATION_DIR="${VALIDATION_DIR_OVERRIDE:-$OUT_DIR/validation}"
RUNTIME_DIR="${RUNTIME_DIR_OVERRIDE:-$OUT_DIR/runtime}"
ASSET_DIR="${ASSET_DIR_OVERRIDE:-$OUT_DIR/asset-sweep}"
LOG_SWEEP_DIR="${LOG_SWEEP_DIR_OVERRIDE:-$OUT_DIR/log-sweep}"
mkdir -p "$VALIDATION_DIR" "$RUNTIME_DIR" "$ASSET_DIR" "$LOG_SWEEP_DIR"

log() { printf ">>> %s\n" "$*"; }

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[ERROR] Missing required tool: $1" >&2
        exit 1
    fi
}

require_cmd python3
require_cmd xdelta3

if [[ ! -x "$EXE" ]]; then
    echo "[ERROR] App executable not found: $EXE" >&2
    echo "[ERROR] Build the app first with: ./scripts/build/build-macos.sh" >&2
    exit 2
fi

if [[ ! -d "$PATCHED_DIR" || "$REBUILD_PATCHED" == "1" ]]; then
    log "Build patched data payload"
    args=(--base "$BASE_DIR" --out "$PATCHED_DIR" --config-dir "$CONFIG_DIR" --rme "$RME_DIR")
    if [[ "$SKIP_CHECKSUMS" == "1" ]]; then
        args+=(--skip-checksums)
    fi
    if [[ "$FORCE_PATCH" == "1" ]]; then
        args+=(--force)
    fi
    "$ROOT/scripts/patch/patch-rebirth-data.sh" "${args[@]}"
fi

log "Ensure patched payload completeness"
"$ROOT/scripts/test/test-rme-ensure-patched-data.sh" --patched-dir "$PATCHED_DIR" --quiet

log "Refresh deterministic validation evidence"
"$ROOT/scripts/test/test-rebirth-refresh-validation.sh" \
  --unpatched "$BASE_DIR" \
  --patched "$PATCHED_DIR" \
  --rme "$RME_DIR" \
  --out "$VALIDATION_DIR"

log "Validate patched output against payload/xdelta"
"$ROOT/scripts/test/test-rebirth-validate-data.sh" \
  --patched "$PATCHED_DIR" \
  --base "$BASE_DIR" \
  --rme "$RME_DIR"

log "Run full asset domain sweep (maps/audio/critters/proto/scripts/text/art)"
python3 "$ROOT/scripts/test/test-rme-asset-sweep.py" \
  --data-root "$PATCHED_DIR" \
  --out-dir "$ASSET_DIR"

log "Install/verify patched data into app bundle resources"
"$ROOT/scripts/test/test-rme-ensure-patched-data.sh" --patched-dir "$PATCHED_DIR" --target-app "$APP"

log "Run runtime MAP sweep with maximal logging"
RME_LOG="${RME_LOG_TOPICS:-all}" \
F1R_PATCHLOG=1 \
F1R_PATCHLOG_VERBOSE="${F1R_PATCHLOG_VERBOSE:-1}" \
python3 "$ROOT/scripts/test/test-rme-runtime-sweep.py" \
  --exe "$EXE" \
  --data-root "$PATCHED_DIR" \
  --out-dir "$RUNTIME_DIR" \
  --timeout "$TIMEOUT"

log "Run topic-by-topic logging sweep"
LOG_DIR="$LOG_SWEEP_DIR" RUNTIME="${LOG_SWEEP_RUNTIME:-20}" "$ROOT/scripts/test/test-rme-log-sweep.sh"

if [[ "$RUN_IOS" == "1" ]]; then
    log "Run optional iOS validations (best effort)"
    GAME_DATA="$PATCHED_DIR" "$ROOT/scripts/test/test-ios-headless.sh" || true
    GAME_DATA="$PATCHED_DIR" "$ROOT/scripts/test/test-ios-simulator.sh" || true
fi

log "End-to-end validation complete"
printf "Outputs:\n  %s\n  %s\n  %s\n  %s\n" "$VALIDATION_DIR" "$ASSET_DIR" "$RUNTIME_DIR" "$LOG_SWEEP_DIR"
