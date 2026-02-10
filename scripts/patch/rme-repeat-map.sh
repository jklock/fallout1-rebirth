#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP="${APP:-$ROOT/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app}"
EXE="${EXE:-$APP/Contents/MacOS/fallout1-rebirth}"
OUT_DIR="${OUT_DIR:-$ROOT/development/RME/validation/runtime}"
PATCHLOG_DIR="$OUT_DIR/patchlogs"
SCREEN_DIR="$OUT_DIR/screenshots-individual"
PRESENT_DIR="$OUT_DIR/present-anomalies"

mkdir -p "$PATCHLOG_DIR" "$SCREEN_DIR" "$PRESENT_DIR"

MAP="${1:-}"
REPEATS="${2:-5}"
TIMEOUT="${TIMEOUT:-60}"

if [[ -z "$MAP" ]]; then
  echo "Usage: $0 MAPNAME [REPEATS]"
  exit 2
fi

RESOURCES_DIR="$APP/Contents/Resources"
if [[ ! -d "$RESOURCES_DIR" ]]; then
  echo "Resources dir not found: $RESOURCES_DIR" >&2
  exit 2
fi

printf "Running %s for %s (repeats=%s)\n" "$0" "$MAP" "$REPEATS"

for i in $(seq 1 "$REPEATS"); do
  printf "Run %d/%d for %s\n" "$i" "$REPEATS" "$MAP"

  # Remove stale screenshots before the run
  rm -f "$RESOURCES_DIR"/scr*.bmp || true

  PL_PATH="$PATCHLOG_DIR/${MAP}.iter$(printf "%02d" $i).patchlog.txt"
  RUN_LOG="$PATCHLOG_DIR/${MAP}.iter$(printf "%02d" $i).run.log"

  # Run the executable with a sanitized environment to avoid leaking host env vars
  # Run the executable with a timeout to avoid indefinite hangs; write output to run log.
  (
    # Run from the app Resources dir so master.dat/critter.dat are discoverable
    cd "$RESOURCES_DIR" && env -i PATH="$PATH" F1R_AUTORUN_MAP="$MAP" F1R_AUTOSCREENSHOT=1 F1R_PATCHLOG=1 \
      F1R_PATCHLOG_PATH="$PL_PATH" F1R_PATCHLOG_VERBOSE=1 F1R_PRESENT_ANOM_DIR="$PRESENT_DIR" \
      "$EXE" > "$RUN_LOG" 2>&1
  ) &
  pid=$!
  # Background killer: wait TIMEOUT seconds and kill the process if still running
  (
    sleep "$TIMEOUT"
    if kill -0 "$pid" 2>/dev/null; then
      echo "[TIMEOUT] Killing pid $pid after $TIMEOUT seconds" >> "$RUN_LOG"
      kill "$pid" 2>/dev/null || true
      sleep 2
      kill -9 "$pid" 2>/dev/null || true
    fi
  ) &
  killer=$!
  # Wait for the process to finish, then cancel the killer
  wait $pid || true
  kill $killer 2>/dev/null || true

  # Move the produced screenshot (if any) into our artifacts dir
  SHOT_FIRST="$(ls -1 "$RESOURCES_DIR"/scr*.bmp 2>/dev/null | head -n1 || true)"
  if [[ -n "$SHOT_FIRST" ]]; then
    cp -f "$SHOT_FIRST" "$SCREEN_DIR/${MAP}.iter$(printf "%02d" $i).bmp" || true
  fi

  # Run analyzer and capture output next to the patchlog
  PY_OUT="${PL_PATH%.txt}_analyze.txt"
  python3 "$ROOT/scripts/dev/patchlog_analyze.py" "$PL_PATH" > "$PY_OUT" 2>&1 || true

  if ! grep -q "No suspicious GNW_SHOW_RECT surf_pre>0 && surf_post==0 found" "$PY_OUT"; then
    echo "SUSPICIOUS event found in $MAP run $i; analyze output: $PY_OUT"
    echo "Artifacts are available in:"
    echo "  patchlog: $PL_PATH"
    echo "  run log: $RUN_LOG"
    echo "  screenshot (if any): $SCREEN_DIR/${MAP}.iter$(printf "%02d" $i).bmp"
    exit 3
  fi

done

printf "All %d runs for %s OK\n" "$REPEATS" "$MAP"
exit 0
