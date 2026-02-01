#!/usr/bin/env bash
# Build Fallout CE Rebirth for iOS
set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR="${BUILD_DIR:-build-ios}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"

echo "=== Building Fallout CE Rebirth for iOS ==="
echo "Build directory: $BUILD_DIR"
echo "Build type: $BUILD_TYPE"
echo "Parallel jobs: $JOBS"
echo ""

# Check toolchain exists
TOOLCHAIN="cmake/toolchain/ios.toolchain.cmake"
if [[ ! -f "$TOOLCHAIN" ]]; then
    echo "❌ iOS toolchain not found: $TOOLCHAIN"
    exit 1
fi

# Configure
if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
    echo ">>> Configuring..."
    cmake -B "$BUILD_DIR" \
        -D CMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -D CMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
        -D ENABLE_BITCODE=0 \
        -D PLATFORM=OS64 \
        -D DEPLOYMENT_TARGET=26.0 \
        -G Xcode \
        -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
fi

# Build
echo ">>> Building..."
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j "$JOBS"

echo ""
echo "✅ iOS build complete!"
echo ""
echo "To create IPA:"
echo "  cd $BUILD_DIR && cpack -C $BUILD_TYPE"
