#!/usr/bin/env bash
# Build Fallout CE Rebirth for macOS
set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"

echo "=== Building Fallout CE Rebirth for macOS ==="
echo "Build directory: $BUILD_DIR"
echo "Build type: $BUILD_TYPE"
echo "Parallel jobs: $JOBS"
echo ""

# Configure
if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
    echo ">>> Configuring..."
    cmake -B "$BUILD_DIR" \
        -G Xcode \
        -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
fi

# Build
echo ">>> Building..."
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j "$JOBS"

# Report
APP_PATH="$BUILD_DIR/$BUILD_TYPE/Fallout Community Edition.app"
if [[ -d "$APP_PATH" ]]; then
    echo ""
    echo "✅ Build successful!"
    echo "App location: $APP_PATH"
    echo ""
    echo "To run (requires game data in same directory):"
    echo "  open \"$APP_PATH\""
else
    echo ""
    echo "❌ Build may have failed - app not found at expected location"
    exit 1
fi
