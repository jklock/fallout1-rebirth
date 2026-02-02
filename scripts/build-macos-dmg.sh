#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build-outputs/macOS"
BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
VOLUME_NAME="Fallout 1 Rebirth"
APP_NAME="Fallout 1 Rebirth.app"
BUNDLE_DATA=0

for arg in "$@"; do
    case "$arg" in
        --bundle)
            BUNDLE_DATA=1
            ;;
        --help|-h)
            echo "Usage: $0 [--bundle]"
            echo "  --bundle   Include game data (GOG/Fallout1) and config in DMG"
            exit 0
            ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

"$ROOT_DIR/scripts/build-macos.sh"

CREATE_DMG="$ROOT_DIR/third_party/create-dmg/create-dmg"
if [[ -x "$CREATE_DMG" ]]; then
    :
elif command -v create-dmg >/dev/null 2>&1; then
    CREATE_DMG="$(command -v create-dmg)"
else
    echo "❌ create-dmg not found. Install with: brew install create-dmg"
    echo "   Or add submodule: git submodule add https://github.com/create-dmg/create-dmg third_party/create-dmg"
    exit 1
fi

APP_PATH="$ROOT_DIR/$BUILD_DIR/$BUILD_TYPE/$APP_NAME"
if [[ ! -d "$APP_PATH" ]]; then
    APP_PATH=$(find "$ROOT_DIR/$BUILD_DIR" -name "$APP_NAME" -maxdepth 3 -print -quit)
fi

if [[ -z "${APP_PATH}" || ! -d "$APP_PATH" ]]; then
    echo "❌ App bundle not found: $APP_NAME"
    exit 1
fi

TMP_DIR=$(mktemp -d)
STAGING_DIR="$TMP_DIR/staging"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$STAGING_DIR/.background"
ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME"

if [[ "$BUNDLE_DATA" -eq 1 ]]; then
    GAME_DATA="$ROOT_DIR/GOG/Fallout1"
    CONFIG_DIR="$ROOT_DIR/gameconfig/macos"

    if [[ ! -d "$GAME_DATA/data" ]]; then
        echo "❌ Missing $GAME_DATA/data"
        exit 1
    fi

    for file in "$GAME_DATA/master.dat" "$GAME_DATA/critter.dat"; do
        if [[ ! -f "$file" ]]; then
            echo "❌ Missing $file"
            exit 1
        fi
    done

    for file in "$CONFIG_DIR/fallout.cfg" "$CONFIG_DIR/fallout.ini"; do
        if [[ ! -f "$file" ]]; then
            echo "❌ Missing $file"
            exit 1
        fi
    done

    TARGET_DIR="$STAGING_DIR/$APP_NAME/Contents/MacOS"
    mkdir -p "$TARGET_DIR"
    ditto "$GAME_DATA/data" "$TARGET_DIR/data"
    cp -f "$GAME_DATA/master.dat" "$TARGET_DIR/"
    cp -f "$GAME_DATA/critter.dat" "$TARGET_DIR/"
    cp -f "$CONFIG_DIR/fallout.cfg" "$TARGET_DIR/"
    cp -f "$CONFIG_DIR/fallout.ini" "$TARGET_DIR/f1_res.ini"

    cat > "$STAGING_DIR/HOW2INSTALL.txt" << 'EOF'
Fallout 1 Rebirth (Bundled)

1) Drag "Fallout 1 Rebirth.app" into the Applications folder.
2) Game data is already bundled. You can launch the app right away.

Need help? See README.md in the repository.
EOF
else
    cat > "$STAGING_DIR/HOW2INSTALL.txt" << 'EOF'
Fallout 1 Rebirth

1) Drag "Fallout 1 Rebirth.app" into the Applications folder.
2) Open the app once, then copy your game data into the app folder as described in README.

Need help? See README.md in the repository.
EOF
fi

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
if [[ "$BUNDLE_DATA" -eq 1 ]]; then
    SIZE_MB=$((SIZE_KB / 1024 + 300))
else
    SIZE_MB=$((SIZE_KB / 1024 + 80))
fi

if [[ "$BUNDLE_DATA" -eq 1 ]]; then
    FINAL_DMG="$OUTPUT_DIR/${VOLUME_NAME}-with-data.dmg"
else
    FINAL_DMG="$OUTPUT_DIR/${VOLUME_NAME}.dmg"
fi

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

CREATE_LOG="$TMP_DIR/create-dmg.log"
if ! "$CREATE_DMG" "${CREATE_ARGS[@]}" "$FINAL_DMG" "$STAGING_DIR" >"$CREATE_LOG" 2>&1; then
    echo "❌ create-dmg failed. Log:"
    cat "$CREATE_LOG"
    exit 1
fi

trap - EXIT
cleanup

echo "✅ DMG created at $FINAL_DMG"
