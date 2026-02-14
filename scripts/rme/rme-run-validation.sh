#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RME_SCRIPT_DIR="$ROOT/scripts/rme"

APP="${APP:-$ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app}"
EXE="${EXE:-$APP/Contents/MacOS/fallout1-rebirth}"

PATCHED_DIR="$ROOT/GOG/patchedfiles"
UNPATCHED_DIR="${UNPATCHED_DIR:-$ROOT/GOG/unpatchedfiles}"
if [[ -d "$ROOT/third_party/rme" ]]; then
  RME_DIR="${RME_DIR:-$ROOT/third_party/rme}"
else
  RME_DIR="${RME_DIR:-$ROOT/third_party/rme/source}"
fi

OUT_DIR="${OUT_DIR:-$ROOT/tmp/rme/validation/runtime}"
TIMEOUT="${TIMEOUT:-60}"

log() {
  printf ">>> %s\n" "$*"
}

cleanup() {
  pkill -f "$EXE" >/dev/null 2>&1 || true
}
trap cleanup EXIT

log "Build macOS app"
"$ROOT/scripts/build/build-macos.sh"

log "Ensure canonical patched data is installed"
"$RME_SCRIPT_DIR/rme-ensure-patched-data.sh" --target-app "$APP"

log "Validate patched data overlay"
"$ROOT/scripts/patch/rebirth-validate-data.sh" --patched "$PATCHED_DIR" --base "$UNPATCHED_DIR" --rme "$RME_DIR"

log "Headless smoke test"
"$ROOT/scripts/test/test-macos-headless.sh"

log "Runtime map sweep (timeout=${TIMEOUT}s)"
python3 "$RME_SCRIPT_DIR/rme-runtime-sweep.py" \
  --exe "$EXE" \
  --out-dir "$OUT_DIR" \
  --timeout "$TIMEOUT"

log "Done"
