#!/usr/bin/env bash
# Automated signed device deploy + log collection for Fallout 1 Rebirth
# - Builds a signed device app (optional DEVELOPMENT_TEAM)
# - Installs to a connected iPad via devicectl
# - Copies game data into the app Documents container
# - Launches app with patchlog env enabled
# - Pulls patchlog + attempts to pull crash logs to dev/state/logs

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DEVICE_NAME="${DEVICE_NAME:-Dadpad}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-${TEAM_ID:-}}"
BUNDLE_ID="${BUNDLE_ID:-com.fallout1rebirth.game}"
GAME_DATA="${GAME_DATA:-${FALLOUT_GAMEFILES_ROOT:-}/patchedfiles}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
APP_PATH="build-ios/$BUILD_TYPE-iphoneos/fallout1-rebirth.app"
ATTACH_CONSOLE="${ATTACH_CONSOLE:-0}"

usage() {
  cat <<USAGE
Usage: DEVELOPMENT_TEAM=TEAM DEVICE_NAME=Name GAME_DATA=/abs/path/to/patchedfiles ./scripts/test/test-ios-device.sh

Environment overrides:
  DEVICE_NAME        device name or UDID (default: Dadpad)
  DEVELOPMENT_TEAM   Apple Team ID (recommended for automatic signing)
  BUNDLE_ID          app bundle id (default: com.fallout1rebirth.game)
  GAME_DATA          path to patchedfiles (master.dat, critter.dat, data/)
  ATTACH_CONSOLE     set to 1 to run app with --console attached

Examples:
  DEVELOPMENT_TEAM=34WPHG75HQ DEVICE_NAME=Dadpad GAME_DATA=/abs/path \
    ./scripts/test/test-ios-device.sh
USAGE
}

cmd_exists() { command -v "$1" >/dev/null 2>&1; }

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if ! cmd_exists xcrun; then
  echo "ERROR: xcrun not found in PATH"
  exit 1
fi

if ! cmd_exists devicectl && ! xcrun --version >/dev/null 2>&1; then
  echo "ERROR: devicectl not available (ensure Xcode command line tools are installed)"
  exit 1
fi

if [[ -z "$GAME_DATA" || ! -d "$GAME_DATA" ]]; then
  echo "ERROR: GAME_DATA not set or not a directory. Provide patchedfiles path (master.dat, critter.dat, data/)"
  usage
  exit 1
fi

if [[ ! -f "$GAME_DATA/master.dat" || ! -f "$GAME_DATA/critter.dat" || ! -d "$GAME_DATA/data" ]]; then
  echo "ERROR: GAME_DATA missing required files (master.dat, critter.dat, data/)"
  exit 1
fi

mkdir -p dev/state/logs

echo "[iOS device test] Device=${DEVICE_NAME} Bundle=${BUNDLE_ID} Team=${DEVELOPMENT_TEAM:-<unset>}"

# 1) Build signed device app (uses new --codesign flag in build-ios.sh)
export DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
echo ">>> Building signed device app (this may take a few minutes)"
./scripts/build/build-ios.sh -prod --device --codesign

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: expected app at $APP_PATH (build may have failed)"
  exit 1
fi

# 2) Install app on device
echo ">>> Installing app to device: $DEVICE_NAME"
xcrun devicectl device install app --device "${DEVICE_NAME}" "$APP_PATH"

# 3) Copy game data into app Documents
echo ">>> Copying game files to app container (Documents)"
xcrun devicectl device copy to \
  --device "${DEVICE_NAME}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --destination Documents \
  --source "${GAME_DATA}/master.dat" \
  --source "${GAME_DATA}/critter.dat"

xcrun devicectl device copy to \
  --device "${DEVICE_NAME}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --destination Documents \
  --source "${GAME_DATA}/data"

# optional config files
if [[ -f "${GAME_DATA}/fallout.cfg" ]]; then
  xcrun devicectl device copy to --device "${DEVICE_NAME}" --domain-type appDataContainer --domain-identifier "${BUNDLE_ID}" --destination Documents --source "${GAME_DATA}/fallout.cfg" || true
fi
if [[ -f "${GAME_DATA}/f1_res.ini" ]]; then
  xcrun devicectl device copy to --device "${DEVICE_NAME}" --domain-type appDataContainer --domain-identifier "${BUNDLE_ID}" --destination Documents --source "${GAME_DATA}/f1_res.ini" || true
fi

# verify files present (best-effort)
echo ">>> Verifying files in app Documents"
xcrun devicectl device info files --device "${DEVICE_NAME}" --domain-type appDataContainer --domain-identifier "${BUNDLE_ID}" --subdirectory Documents || true

# 4) Launch app with patchlog env enabled
echo ">>> Launching app (patchlog enabled)"
LAUNCH_CMD=(xcrun devicectl device process launch --device "${DEVICE_NAME}" --terminate-existing "${BUNDLE_ID}")
if [[ "$ATTACH_CONSOLE" == "1" ]]; then
  DEVICECTL_CHILD_F1R_PATCHLOG=1 DEVICECTL_CHILD_F1R_PATCHLOG_PATH=Documents/input-device.patchlog.txt "${LAUNCH_CMD[@]}" --console
else
  DEVICECTL_CHILD_F1R_PATCHLOG=1 DEVICECTL_CHILD_F1R_PATCHLOG_PATH=Documents/input-device.patchlog.txt "${LAUNCH_CMD[@]}"
fi

# allow a short window for the app to write patchlog
sleep 2

# 5) Pull patchlog back to repo
echo ">>> Pulling patchlog"
set +e
xcrun devicectl device copy from \
  --device "${DEVICE_NAME}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --source Documents/input-device.patchlog.txt \
  --destination "$(pwd)/dev/state/logs" || true
set -e

# 6) Best-effort: pull any crash logs (systemCrashLogs)
echo ">>> Checking for crash logs (best-effort)"
crash_listing="$(xcrun devicectl device info files --device "${DEVICE_NAME}" --domain-type systemCrashLogs 2>/dev/null || true)"
mapfile -t crash_paths < <(printf "%s\n" "$crash_listing" | grep -Eo '/[A-Za-z0-9_./-]*\.(crash|ips)' | uniq || true)
if [[ ${#crash_paths[@]} -gt 0 ]]; then
  echo "Found ${#crash_paths[@]} crash log(s); copying to dev/state/logs"
  for p in "${crash_paths[@]}"; do
    echo "  -> $p"
    xcrun devicectl device copy from --device "${DEVICE_NAME}" --domain-type systemCrashLogs --source "$p" --destination "$(pwd)/dev/state/logs" || true
  done
else
  echo "No matching crash logs found (you can run 'xcrun devicectl device info files --device ${DEVICE_NAME} --domain-type systemCrashLogs' to inspect)"
fi

# Summary
echo ""
echo "Logs & artifacts pulled to: dev/state/logs"
ls -la dev/state/logs || true

echo "Done. If you need console attach, set ATTACH_CONSOLE=1 to run the process with --console."
exit 0
