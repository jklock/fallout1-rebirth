#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# Prefer Python implementation if present (keeps backward-compatible shell wrapper).
PY="$ROOT/scripts/test/rme-repeat-map.py"
if [[ -x "$PY" ]]; then
  exec python3 "$PY" "$@"
fi
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
# Enforce minimum test duration per RME harness (tests must run >= 10s)
if [[ "$TIMEOUT" -lt 10 ]]; then
  echo "[WARN] TIMEOUT ($TIMEOUT) < 10s; bumping to 10s"
  TIMEOUT=10
fi

if [[ -z "$MAP" ]]; then
  echo "Usage: $0 MAPNAME [REPEATS]"
  exit 2
fi

RESOURCES_DIR="$APP/Contents/Resources"
if [[ ! -d "$RESOURCES_DIR" ]]; then
  echo "Resources dir not found: $RESOURCES_DIR" >&2
  exit 2
fi

# Preflight: ensure required game data and the specific map are present in the
# app Resources. Running the engine without master.dat/critter.dat or the map
# file leads to DB_OPEN_FAIL and masks real issues; try to auto-install the
# patched files from the repo's GOG/patchedfiles and fail only if they remain
# missing.
PATCHED_DIR="$ROOT/GOG/patchedfiles"
if [[ (! -f "$RESOURCES_DIR/master.dat" || ! -f "$RESOURCES_DIR/critter.dat") ]]; then
  if [[ -d "$PATCHED_DIR" && -f "$PATCHED_DIR/master.dat" ]]; then
    echo "[INFO] Required game data missing in app bundle — attempting auto-install from $PATCHED_DIR"
    "$ROOT/scripts/test/test-install-game-data.sh" --source "$PATCHED_DIR" --target "$APP" || true
  fi
fi

if [[ ! -f "$RESOURCES_DIR/master.dat" || ! -f "$RESOURCES_DIR/critter.dat" ]]; then
  echo "[ERROR] Required game data missing in app bundle Resources: master.dat and/or critter.dat" >&2
  echo "Install game data and retry, for example: ./scripts/test/test-install-game-data.sh --source GOG/patchedfiles --target \"$APP\"" >&2
  exit 2
fi

MAP_FILE="$RESOURCES_DIR/data/maps/${MAP}.MAP"
if [[ ! -f "$MAP_FILE" ]]; then
  # Try to auto-install patched data (map may be inside patchedfiles/data/maps)
  if [[ -d "$PATCHED_DIR" && -f "$PATCHED_DIR/data/maps/${MAP}.MAP" ]]; then
    echo "[INFO] Map file $MAP missing — auto-installing patched data from $PATCHED_DIR"
    "$ROOT/scripts/test/test-install-game-data.sh" --source "$PATCHED_DIR" --target "$APP" || true
  fi
fi

if [[ ! -f "$MAP_FILE" ]]; then
  echo "[ERROR] Map file not found for $MAP: $MAP_FILE" >&2
  echo "Install the patched data (GOG/patchedfiles) into the app bundle and retry." >&2
  exit 2
fi

printf "Running %s for %s (repeats=%s)\n" "$0" "$MAP" "$REPEATS"

for i in $(seq 1 "$REPEATS"); do
  printf "Run %d/%d for %s\n" "$i" "$REPEATS" "$MAP"

  # Remove stale screenshots before the run
  rm -f "$RESOURCES_DIR"/scr*.bmp || true

  PL_PATH="$PATCHLOG_DIR/${MAP}.iter$(printf "%02d" $i).patchlog.txt"
  RUN_LOG="$PATCHLOG_DIR/${MAP}.iter$(printf "%02d" $i).run.log"

  # Normally do NOT pre-create an empty patchlog (it masks early crashes).
  # When running under the RME orchestrator (evidence artifacts path) or when
  # RME_PLACEHOLDER_PATCHLOG=1 is set, create a marked placeholder so downstream
  # analyzers always have a file to inspect. The placeholder will be detected
  # after the run and treated as a failure so we don't mask real crashes.
  if [[ "${OUT_DIR}" == *"/development/RME/ARTIFACTS/evidence"* || "${RME_PLACEHOLDER_PATCHLOG:-}" == "1" ]]; then
    mkdir -p "$(dirname "$PL_PATH")"
    echo "[PLACEHOLDER PATCHLOG] created by rme-repeat-map.sh - engine may crash before producing a real patchlog" > "$PL_PATH"
  fi

  # Require the engine to write a real patchlog; we validate after the run and fail if it's missing/empty.

  # Run the executable with a sanitized environment to avoid leaking host env vars
  # Run the executable with a timeout to avoid indefinite hangs; write output to run log.
  (
    # Diagnostics
    echo "[INFO] PWD=$(pwd)"
    echo "[INFO] APP=$APP"
    echo "[INFO] EXE=$EXE"
    echo "[INFO] RESOURCES_DIR=$RESOURCES_DIR"
    echo "[INFO] PATCHLOG=$PL_PATH"

    # Ensure executable exists and is runnable
    if [[ ! -x "$EXE" ]]; then
      echo "[ERROR] executable not found or not executable: $EXE" >&2
      exit 2
    fi

    # Run from the app Resources dir so master.dat/critter.dat are discoverable
    cd "$RESOURCES_DIR" || exit 2
    env -i PATH="$PATH" \
      F1R_AUTORUN_MAP="$MAP" \
      F1R_AUTORUN_CLICK="${F1R_AUTORUN_CLICK:-0}" \
      F1R_AUTORUN_CLICK_DELAY="${F1R_AUTORUN_CLICK_DELAY:-7}" \
      F1R_AUTORUN_HOLD_SECS="${F1R_AUTORUN_HOLD_SECS:-10}" \
      F1R_AUTOSCREENSHOT=1 \
      F1R_PATCHLOG=1 \
      F1R_PATCHLOG_PATH="$PL_PATH" \
      F1R_PATCHLOG_VERBOSE=1 \
      F1R_PRESENT_ANOM_DIR="$PRESENT_DIR" \
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

  # Fail early if the engine did not produce a real patchlog (empty file masks crashes)
  # or if the placeholder we created was not replaced by a real patchlog.
  if [[ ! -s "$PL_PATH" || "$(head -n 1 "$PL_PATH" 2>/dev/null)" == "[PLACEHOLDER PATCHLOG"* ]]; then
    echo "[ERROR] patchlog missing or placeholder for $MAP run $i; see run log: $RUN_LOG" >&2
    echo "-- run log (head 200 lines) --" >&2
    head -n 200 "$RUN_LOG" >&2 || true
    echo "-- end run log head --" >&2
    exit 4
  fi

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
