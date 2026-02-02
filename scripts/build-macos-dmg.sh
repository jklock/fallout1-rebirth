#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build-outputs/macOS"

mkdir -p "$OUTPUT_DIR"

"$ROOT_DIR/scripts/build-macos.sh"

pushd "$ROOT_DIR/build-macos" >/dev/null
cpack -C RelWithDebInfo
popd >/dev/null

DMG_PATH=$(ls -t "$ROOT_DIR/build-macos"/*.dmg 2>/dev/null | head -1 || true)
if [[ -z "${DMG_PATH}" ]]; then
    echo "❌ No DMG found in build-macos"
    exit 1
fi

cp -f "$DMG_PATH" "$OUTPUT_DIR/"

echo "✅ DMG copied to $OUTPUT_DIR/$(basename "$DMG_PATH")"