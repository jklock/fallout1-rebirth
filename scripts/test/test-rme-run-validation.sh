#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RME_SCRIPT_DIR="$ROOT/scripts/test"
GAMEFILES_ROOT="${FALLOUT_GAMEFILES_ROOT:-${GAMEFILES_ROOT:-}}"

APP="${APP:-$ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app}"
EXE="${EXE:-$APP/Contents/MacOS/fallout1-rebirth}"

PATCHED_DIR="${PATCHED_DIR:-${GAME_DATA:-}}"
UNPATCHED_DIR="${UNPATCHED_DIR:-}"
if [[ -z "$PATCHED_DIR" && -n "$GAMEFILES_ROOT" ]]; then
  PATCHED_DIR="$GAMEFILES_ROOT/patchedfiles"
fi
if [[ -z "$UNPATCHED_DIR" && -n "$GAMEFILES_ROOT" ]]; then
  UNPATCHED_DIR="$GAMEFILES_ROOT/unpatchedfiles"
fi
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

if [[ -z "$PATCHED_DIR" || -z "$UNPATCHED_DIR" ]]; then
  echo "[ERROR] Missing PATCHED_DIR/UNPATCHED_DIR. Set flags/env or export FALLOUT_GAMEFILES_ROOT." >&2
  exit 2
fi

if [[ ! -x "$EXE" ]]; then
  echo "[ERROR] App executable not found: $EXE" >&2
  echo "[ERROR] Build the app first with: ./scripts/build/build-macos.sh" >&2
  exit 2
fi

log "Ensure patched data is installed"
"$RME_SCRIPT_DIR/test-rme-ensure-patched-data.sh" --patched-dir "$PATCHED_DIR" --target-app "$APP"

log "Validate patched data overlay"
"$ROOT/scripts/test/test-rebirth-validate-data.sh" --patched "$PATCHED_DIR" --base "$UNPATCHED_DIR" --rme "$RME_DIR"

log "Headless smoke test"
"$ROOT/scripts/test/test-macos-headless.sh"

log "Runtime map sweep (timeout=${TIMEOUT}s)"
python3 "$RME_SCRIPT_DIR/test-rme-runtime-sweep.py" \
  --exe "$EXE" \
  --data-root "$PATCHED_DIR" \
  --out-dir "$OUT_DIR" \
  --timeout "$TIMEOUT"

log "Done"
