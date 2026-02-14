#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RME_SCRIPT_DIR="$ROOT/scripts/rme"

BASE_DIR="${BASE_DIR:-$ROOT/GOG/unpatchedfiles}"
PATCHED_DIR="$ROOT/GOG/patchedfiles"
if [[ -d "$ROOT/third_party/rme" ]]; then
  RME_DIR="${RME_DIR:-$ROOT/third_party/rme}"
else
  RME_DIR="${RME_DIR:-$ROOT/third_party/rme/source}"
fi
CONFIG_DIR="${CONFIG_DIR:-$ROOT/gameconfig/macos}"

OUT_DIR="${OUT_DIR:-$ROOT/tmp/rme/validation}"
RUNTIME_OUT="${RUNTIME_OUT:-$ROOT/tmp/rme/validation/runtime}"

APP="${APP:-$ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app}"
EXE="${EXE:-$APP/Contents/MacOS/fallout1-rebirth}"

TIMEOUT="${TIMEOUT:-60}"

REBUILD_PATCHED="${REBUILD_PATCHED:-0}"
FORCE_PATCH="${FORCE_PATCH:-0}"
SKIP_CHECKSUMS="${SKIP_CHECKSUMS:-0}"

RUN_IOS="${RUN_IOS:-0}"
RUN_IPA_PATCH="${RUN_IPA_PATCH:-0}"

log() { printf ">>> %s\n" "$*"; }

cleanup() {
  pkill -f "$EXE" >/dev/null 2>&1 || true
}
trap cleanup EXIT

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing required tool: $1" >&2
    exit 1
  fi
}

require_cmd python3
require_cmd xdelta3

log "Build macOS app"
"$ROOT/scripts/build/build-macos.sh"

if [[ ! -d "$PATCHED_DIR" || "$REBUILD_PATCHED" == "1" ]]; then
  log "Rebuild patched data"
  args=(--base "$BASE_DIR" --out "$PATCHED_DIR" --config-dir "$CONFIG_DIR" --rme "$RME_DIR")
  if [[ "$SKIP_CHECKSUMS" == "1" ]]; then
    args+=(--skip-checksums)
  fi
  if [[ "$FORCE_PATCH" == "1" ]]; then
    args+=(--force)
  fi
  "$ROOT/scripts/patch/rebirth-patch-data.sh" "${args[@]}"
fi

# Canonical source must exist and be complete before any validation/test execution.
"$RME_SCRIPT_DIR/rme-ensure-patched-data.sh" --quiet

log "Refresh validation evidence"
"$ROOT/scripts/patch/rebirth-refresh-validation.sh" \
  --unpatched "$BASE_DIR" \
  --patched "$PATCHED_DIR" \
  --rme "$RME_DIR" \
  --out "$OUT_DIR"

log "Audit script references"
python3 "$RME_SCRIPT_DIR/rme-audit-script-refs.py" \
  --patched-dir "$PATCHED_DIR" \
  --out-dir "$OUT_DIR/raw"

log "Validate patched data overlay"
"$ROOT/scripts/patch/rebirth-validate-data.sh" \
  --patched "$PATCHED_DIR" \
  --base "$BASE_DIR" \
  --rme "$RME_DIR"

log "Install/verify canonical patched data into app bundle"
"$RME_SCRIPT_DIR/rme-ensure-patched-data.sh" --target-app "$APP"

log "Headless macOS smoke test"
"$ROOT/scripts/test/test-macos-headless.sh"

log "Runtime map sweep (timeout=${TIMEOUT}s)"
python3 "$RME_SCRIPT_DIR/rme-runtime-sweep.py" \
  --exe "$EXE" \
  --out-dir "$RUNTIME_OUT" \
  --timeout "$TIMEOUT"

if [[ "$RUN_IPA_PATCH" == "1" ]]; then
  log "Patch IPA payload (optional)"
  "$ROOT/scripts/patch/rebirth-patch-ipa.sh" --base "$BASE_DIR" --out "$PATCHED_DIR" --rme "$RME_DIR" || true
fi

if [[ "$RUN_IOS" == "1" ]]; then
  log "iOS headless test (optional)"
  GAME_DATA="$PATCHED_DIR" "$ROOT/scripts/test/test-ios-headless.sh" || true
  log "iOS simulator test (optional)"
  GAME_DATA="$PATCHED_DIR" "$ROOT/scripts/test/test-ios-simulator.sh" || true
fi

log "All coverage steps complete"
