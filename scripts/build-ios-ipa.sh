#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build-outputs/iOS"

mkdir -p "$OUTPUT_DIR"

"$ROOT_DIR/scripts/build-ios.sh"

pushd "$ROOT_DIR/build-ios" >/dev/null
cpack -C RelWithDebInfo
popd >/dev/null

IPA_PATH=$(ls -t "$ROOT_DIR/build-ios"/*.ipa 2>/dev/null | head -1 || true)
if [[ -z "${IPA_PATH}" ]]; then
    echo "❌ No IPA found in build-ios"
    exit 1
fi

cp -f "$IPA_PATH" "$OUTPUT_DIR/"

echo "✅ IPA copied to $OUTPUT_DIR/$(basename "$IPA_PATH")"