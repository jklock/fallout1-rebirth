#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

APP="${APP:-$ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app}"
EXE="${EXE:-$APP/Contents/MacOS/fallout1-rebirth}"
RES="${RES:-$APP/Contents/Resources}"

PATCHED_DIR="${PATCHED_DIR:-$ROOT/GOG/patchedfiles}"
UNPATCHED_DIR="${UNPATCHED_DIR:-$ROOT/GOG/unpatchedfiles}"
RME_DIR="${RME_DIR:-$ROOT/third_party/rme/source}"

OUT_DIR="${OUT_DIR:-$ROOT/development/RME/validation/runtime}"
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

log "Install unpatched data (sanity check)"
"$ROOT/scripts/test/test-install-game-data.sh" --source "$UNPATCHED_DIR" --target "$APP"

log "Install patched data"
"$ROOT/scripts/test/test-install-game-data.sh" --source "$PATCHED_DIR" --target "$APP"

log "Validate patched data overlay"
"$ROOT/scripts/patch/rebirth-validate-data.sh" --patched "$RES" --base "$UNPATCHED_DIR" --rme "$RME_DIR"

log "Headless smoke test"
"$ROOT/scripts/test/test-macos-headless.sh"

log "Runtime map sweep (timeout=${TIMEOUT}s)"
python3 "$ROOT/scripts/patch/rme-runtime-sweep.py" \
  --exe "$EXE" \
  --out-dir "$OUT_DIR" \
  --timeout "$TIMEOUT"

log "Done"
