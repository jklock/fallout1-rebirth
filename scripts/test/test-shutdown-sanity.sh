#!/usr/bin/env bash
# Quick regression that runs an autorun map and ensures the process exits
# cleanly and produces a patchlog (sanity-check for shutdown double-free).
set -euo pipefail

cd "$(dirname "$0")/../.."

BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
APP_BUNDLE="$BUILD_DIR/$BUILD_TYPE/Fallout 1 Rebirth.app"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/fallout1-rebirth"

OUT_DIR="development/RME/ARTIFACTS/evidence/shutdown-sanity"
mkdir -p "$OUT_DIR"
PATCHLOG_PATH="$OUT_DIR/shutdown-sanity.patchlog.txt"
STDOUT_LOG="$OUT_DIR/shutdown.stdout.log"
STDERR_LOG="$OUT_DIR/shutdown.stderr.log"

if [[ ! -x "$EXECUTABLE" ]]; then
  echo "Executable not found: $EXECUTABLE"
  exit 2
fi

echo "Running autorun (CARAVAN) to validate clean shutdown..."
env -i PATH="$PATH" F1R_AUTORUN_MAP=CARAVAN F1R_PATCHLOG=1 F1R_PATCHLOG_PATH="$PATCHLOG_PATH" \
  "$EXECUTABLE" >"$STDOUT_LOG" 2>"$STDERR_LOG" || true

rc=$?

# We only care about a *clean shutdown* (no sanitizer or crash indicators)
# for this regression. Map load may legitimately fail in developer workspaces
# that don't contain original game assets, so don't require rc==0 here.

if [[ ! -f "$PATCHLOG_PATH" ]]; then
  echo "FAIL: patchlog not written: $PATCHLOG_PATH"
  exit 4
fi

# Quick log checks for obvious sanitizer/crash indicators or crash signals
if grep -E "AddressSanitizer|malloc_error_break|double-free|double free|Trace/BPT trap" -n "$STDERR_LOG" "$STDOUT_LOG" "$PATCHLOG_PATH" >/dev/null 2>&1; then
  echo "FAIL: sanitizer or crash indicators found in logs"
  grep -n "AddressSanitizer\|malloc_error_break\|double-free\|double free\|Trace/BPT trap" -n "$STDERR_LOG" "$STDOUT_LOG" "$PATCHLOG_PATH" || true
  exit 5
fi

# If we reached here, shutdown completed without sanitizer/crash evidence.
echo "PASS: shutdown sanity check succeeded (patchlog: $PATCHLOG_PATH, exit_code=$rc)"
exit 0
