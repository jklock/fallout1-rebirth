#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — macOS DMG Build Script
# =============================================================================
# Creates a macOS DMG installer (app only, no game data).
#
# USAGE:
#   ./scripts/build/build-macos-dmg.sh
#
# CONFIGURATION (environment variables):
#   BUILD_DIR   - Build output directory (default: "build-macos")
#   BUILD_TYPE  - Debug/Release/RelWithDebInfo (default: "RelWithDebInfo")
#
# NOTES:
#   - Requires 'create-dmg' tool (brew install create-dmg)
#   - Game data is NOT bundled — users add their own files
#   - Output goes to build-outputs/macOS/
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build-outputs/macOS"
BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
VOLUME_NAME="Fallout 1 Rebirth"
APP_NAME="Fallout 1 Rebirth.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()    { echo -e "${GREEN}✅${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠️${NC}  $1"; }
log_error() { echo -e "${RED}❌${NC} $1"; }

echo ""
echo "=============================================="
echo " Fallout 1 Rebirth — macOS DMG"
echo "=============================================="
echo " Build directory: $BUILD_DIR"
echo " Build type:      $BUILD_TYPE"
echo " Output:          $OUTPUT_DIR"
echo "=============================================="
echo ""

mkdir -p "$OUTPUT_DIR"

# Run the build
log_info "Building macOS app..."
"$ROOT_DIR/scripts/build/build-macos.sh"

CREATE_DMG="$ROOT_DIR/third_party/create-dmg/create-dmg"
if [[ -x "$CREATE_DMG" ]]; then
    :
elif command -v create-dmg >/dev/null 2>&1; then
    CREATE_DMG="$(command -v create-dmg)"
else
    log_error "create-dmg not found. Install with: brew install create-dmg"
    echo "   Or add submodule: git submodule add https://github.com/create-dmg/create-dmg third_party/create-dmg"
    exit 1
fi

APP_PATH="$ROOT_DIR/$BUILD_DIR/$BUILD_TYPE/$APP_NAME"
if [[ ! -d "$APP_PATH" ]]; then
    APP_PATH=$(find "$ROOT_DIR/$BUILD_DIR" -name "$APP_NAME" -maxdepth 3 -print -quit)
fi

if [[ -z "${APP_PATH}" || ! -d "$APP_PATH" ]]; then
    log_error "App bundle not found: $APP_NAME"
    exit 1
fi

log_ok "Found app bundle: $APP_PATH"

TMP_DIR=$(mktemp -d)
STAGING_DIR="$TMP_DIR/staging"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$STAGING_DIR/.background"
ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME"

cat > "$STAGING_DIR/HOW2INSTALL.txt" << 'EOF'
Fallout 1 Rebirth

INSTALLATION:
1) Drag "Fallout 1 Rebirth.app" into the Applications folder.

2) Copy your Fallout 1 game data into the app bundle:
   - Right-click app → "Show Package Contents"
   - Navigate to Contents/MacOS/
   - Copy: master.dat, critter.dat, data/ folder
   - Copy: fallout.cfg and f1_res.ini (config files)

3) Launch the app!

GETTING GAME DATA:
- Obtain Fallout 1 from your preferred storefront
- See README.md in the repository for detailed instructions

Need help? https://github.com/fallout1-rebirth/fallout1-rebirth
EOF

BACKGROUND_IMAGE="$ROOT_DIR/img/dmgbackground.png"
ICON_FILE="$ROOT_DIR/os/macos/fallout1-rebirth.icns"

WINDOW_WIDTH=640
WINDOW_HEIGHT=427
if [[ -f "$BACKGROUND_IMAGE" ]]; then
    WINDOW_WIDTH=$(sips -g pixelWidth "$BACKGROUND_IMAGE" | awk '/pixelWidth/ {print $2}')
    WINDOW_HEIGHT=$(sips -g pixelHeight "$BACKGROUND_IMAGE" | awk '/pixelHeight/ {print $2}')
fi

# Bubble layout tuned for 640x427 background
APP_X=220
APP_Y=245
APPS_X=420
APPS_Y=245
README_X=320
README_Y=330

SIZE_KB=$(du -sk "$STAGING_DIR" | awk '{print $1}')
SIZE_MB=$((SIZE_KB / 1024 + 80))

FINAL_DMG="$OUTPUT_DIR/${VOLUME_NAME}.dmg"

CREATE_ARGS=(
    --volname "$VOLUME_NAME"
    --window-pos 100 100
    --window-size "$WINDOW_WIDTH" "$WINDOW_HEIGHT"
    --icon-size 64
    --icon "$APP_NAME" "$APP_X" "$APP_Y"
    --hide-extension "$APP_NAME"
    --app-drop-link "$APPS_X" "$APPS_Y"
    --icon "HOW2INSTALL.txt" "$README_X" "$README_Y"
    --hide-extension "HOW2INSTALL.txt"
    --text-size 10
    --disk-image-size "$SIZE_MB"
)

CREATE_DMG_HELP="$($CREATE_DMG --help 2>&1 || true)"
if echo "$CREATE_DMG_HELP" | grep -q -- '--applescript-sleep-duration'; then
    CREATE_ARGS+=(--applescript-sleep-duration 12)
fi
if echo "$CREATE_DMG_HELP" | grep -q -- '--hdiutil-retries'; then
    CREATE_ARGS+=(--hdiutil-retries 12)
fi

if [[ -f "$BACKGROUND_IMAGE" ]]; then
    CREATE_ARGS+=(--background "$BACKGROUND_IMAGE")
fi

if [[ -f "$ICON_FILE" ]]; then
    CREATE_ARGS+=(--volicon "$ICON_FILE")
fi

log_info "Creating DMG..."
CREATE_LOG="$TMP_DIR/create-dmg.log"
if ! "$CREATE_DMG" "${CREATE_ARGS[@]}" "$FINAL_DMG" "$STAGING_DIR" >"$CREATE_LOG" 2>&1; then
    log_error "create-dmg failed. Log:"
    cat "$CREATE_LOG"
    exit 1
fi

trap - EXIT
cleanup

echo ""
log_ok "DMG created: $FINAL_DMG"
echo "   Size: $(du -sh "$FINAL_DMG" | cut -f1)"
echo ""
