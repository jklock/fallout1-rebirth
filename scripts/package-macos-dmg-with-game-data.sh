#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build-outputs/macOS"
GAME_DATA="$ROOT_DIR/GOG/Fallout1"
CONFIG_DIR="$ROOT_DIR/gameconfig/macos"

DMG_PATH="${1:-}"
if [[ -z "${DMG_PATH}" ]]; then
    DMG_PATH=$(ls -t "$OUTPUT_DIR"/*.dmg 2>/dev/null | head -1 || true)
fi

if [[ -z "${DMG_PATH}" || ! -f "${DMG_PATH}" ]]; then
    echo "❌ No DMG found. Provide a DMG path or run ./scripts/build-macos-dmg.sh first."
    exit 1
fi

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

TMP_DIR=$(mktemp -d)
RW_DMG="$TMP_DIR/$(basename "${DMG_PATH%.dmg}")-rw.dmg"
MOUNT_POINT=$(mktemp -d)

cleanup() {
    if mount | grep -q "$MOUNT_POINT"; then
        hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
    fi
    rm -rf "$MOUNT_POINT" "$TMP_DIR"
}
trap cleanup EXIT

hdiutil convert "$DMG_PATH" -format UDRW -o "$RW_DMG" >/dev/null

hdiutil attach "$RW_DMG" -mountpoint "$MOUNT_POINT" -nobrowse -readwrite >/dev/null

APP_PATH=$(find "$MOUNT_POINT" -maxdepth 1 -name "*.app" -print -quit)
if [[ -z "${APP_PATH}" ]]; then
    echo "❌ No .app found in mounted DMG"
    exit 1
fi

TARGET_DIR="$APP_PATH/Contents/MacOS"
mkdir -p "$TARGET_DIR"

cp -R "$GAME_DATA/data" "$TARGET_DIR/"
cp -f "$GAME_DATA/master.dat" "$TARGET_DIR/"
cp -f "$GAME_DATA/critter.dat" "$TARGET_DIR/"
cp -f "$CONFIG_DIR/fallout.cfg" "$TARGET_DIR/"
cp -f "$CONFIG_DIR/fallout.ini" "$TARGET_DIR/f1_res.ini"

sync
hdiutil detach "$MOUNT_POINT" >/dev/null

FINAL_DMG="$OUTPUT_DIR/$(basename "${DMG_PATH%.dmg}")-with-data.dmg"
hdiutil convert "$RW_DMG" -format UDZO -o "$FINAL_DMG" >/dev/null

trap - EXIT
cleanup

echo "✅ Created $FINAL_DMG"