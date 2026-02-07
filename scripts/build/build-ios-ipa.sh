#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — iOS IPA Build Script
# =============================================================================
# Builds the iOS app (device) and packages an IPA via CPack.
# Copies the resulting IPA into build-outputs/iOS.
#
# USAGE:
#   ./scripts/build/build-ios-ipa.sh
#   BUILD_TYPE=Debug ./scripts/build/build-ios-ipa.sh
#
# CONFIGURATION (environment variables):
#   BUILD_TYPE - CPack configuration to package (default: "RelWithDebInfo")
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build-outputs/iOS"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"

mkdir -p "$OUTPUT_DIR"

"$ROOT_DIR/scripts/build/build-ios.sh"

pushd "$ROOT_DIR/build-ios" >/dev/null
cpack -C "$BUILD_TYPE"
popd >/dev/null

IPA_PATH=$(ls -t "$ROOT_DIR/build-ios"/*.ipa 2>/dev/null | head -1 || true)
if [[ -z "${IPA_PATH}" ]]; then
    echo "❌ No IPA found in build-ios"
    exit 1
fi

cp -f "$IPA_PATH" "$OUTPUT_DIR/"

echo "✅ IPA copied to $OUTPUT_DIR/$(basename "$IPA_PATH")"
