#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — iOS Build Script
# =============================================================================
# Builds for physical iOS/iPadOS devices (arm64).
# For simulator builds, use: ./scripts/test/test-ios-simulator.sh --build-only
#
# USAGE:
#   ./scripts/build/build-ios.sh                     # Standard build
#   BUILD_TYPE=Debug ./scripts/build/build-ios.sh    # Debug build
#
# CONFIGURATION (environment variables):
#   BUILD_DIR   - Build output directory (default: "build-ios")
#   BUILD_TYPE  - Debug/Release/RelWithDebInfo (default: "RelWithDebInfo")
#   JOBS        - Parallel jobs (default: physical CPU count)
#   CLEAN       - Set to "1" to force reconfigure
#   F1R_DISABLE_RME_LOGGING - Set to 1/ON to compile out Rebirth diagnostic logging
#
# NOTES:
#   - Requires Xcode with iOS SDK
#   - Code signing is disabled (for local development)
#   - For distribution, sign via Xcode or use proper signing identity
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/../.."

if [[ -f ".f1r-build.env" ]]; then
    # shellcheck disable=SC1091
    source ".f1r-build.env"
fi

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
BUILD_DIR="${BUILD_DIR:-build-ios}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"
CLEAN="${CLEAN:-0}"
TOOLCHAIN="cmake/toolchain/ios.toolchain.cmake"
LOGGING_FLAG_RAW="${F1R_DISABLE_RME_LOGGING:-0}"
LOGGING_FLAG_UPPER="$(printf '%s' "$LOGGING_FLAG_RAW" | tr '[:lower:]' '[:upper:]')"

case "$LOGGING_FLAG_UPPER" in
    1|ON|TRUE|YES) RME_LOGGING_CMAKE="ON" ;;
    0|OFF|FALSE|NO|"") RME_LOGGING_CMAKE="OFF" ;;
    *)
        echo "Invalid F1R_DISABLE_RME_LOGGING value: $LOGGING_FLAG_RAW (expected 0/1/ON/OFF)" >&2
        exit 2
        ;;
esac

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
log_info()  { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()    { echo -e "${GREEN}✅${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠️${NC}  $1"; }
log_error() { echo -e "${RED}❌${NC} $1"; }

echo ""
echo "=============================================="
echo " Fallout 1 Rebirth — iOS Build"
echo "=============================================="
echo " Build directory: $BUILD_DIR"
echo " Build type:      $BUILD_TYPE"
echo " Parallel jobs:   $JOBS"
echo " Target:          iOS Device (arm64)"
echo " RME logging:     $RME_LOGGING_CMAKE (compile option)"
echo "=============================================="
echo ""

# Verify toolchain exists
if [[ ! -f "$TOOLCHAIN" ]]; then
    log_error "iOS toolchain not found: $TOOLCHAIN"
    log_info "Ensure you're running from the project root"
    exit 1
fi

# Clean if requested
if [[ "$CLEAN" == "1" && -d "$BUILD_DIR" ]]; then
    log_warn "CLEAN=1 set, removing $BUILD_DIR..."
    rm -rf "$BUILD_DIR"
fi

# Configure (if missing or if logging mode changed)
NEEDS_CONFIG=0
if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
    NEEDS_CONFIG=1
else
    cached_flag="$(grep '^F1R_DISABLE_RME_LOGGING:BOOL=' "$BUILD_DIR/CMakeCache.txt" | head -n1 | cut -d'=' -f2 || true)"
    cached_flag_upper="$(printf '%s' "${cached_flag:-}" | tr '[:lower:]' '[:upper:]')"
    desired_flag_upper="$(printf '%s' "$RME_LOGGING_CMAKE" | tr '[:lower:]' '[:upper:]')"
    if [[ "$cached_flag_upper" != "$desired_flag_upper" ]]; then
        log_info "CMake option changed: F1R_DISABLE_RME_LOGGING=${cached_flag:-unset} -> $RME_LOGGING_CMAKE"
        NEEDS_CONFIG=1
    fi
fi

if [[ "$NEEDS_CONFIG" == "1" ]]; then
    log_info "Configuring CMake for iOS..."
    cmake -B "$BUILD_DIR" \
        -D CMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -D CMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
        -D F1R_DISABLE_RME_LOGGING="$RME_LOGGING_CMAKE" \
        -D ENABLE_BITCODE=0 \
        -D PLATFORM=OS64 \
        -D DEPLOYMENT_TARGET=26.0 \
        -G Xcode \
        -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY='' \
        || { log_error "CMake configuration failed"; exit 1; }
    log_ok "Configuration complete"
else
    log_info "Using existing CMake configuration"
fi

# Build
log_info "Building ($BUILD_TYPE, $JOBS parallel jobs)..."
if ! cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j "$JOBS"; then
    log_error "Build failed"
    exit 1
fi

# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------
APP_PATH="$BUILD_DIR/$BUILD_TYPE-iphoneos/fallout1-rebirth.app"
EXECUTABLE="$APP_PATH/fallout1-rebirth"

if [[ -d "$APP_PATH" && -x "$EXECUTABLE" ]]; then
    echo ""
    log_ok "iOS build successful!"
    echo ""
    echo "  App bundle: $APP_PATH"
    echo "  Size:       $(du -sh "$APP_PATH" | cut -f1)"
    echo ""
    # Show architecture info
    log_info "Binary architecture:"
    file "$EXECUTABLE" | sed 's/.*: /    /'
    echo ""
    echo "To create IPA for distribution:"
    echo "  cd $BUILD_DIR && cpack -C $BUILD_TYPE"
    echo ""
    echo "For simulator testing, use instead:"
    echo "  ./scripts/test/test-ios-simulator.sh"
else
    echo ""
    log_ok "iOS build complete!"
    echo ""
    log_info "Checking for build output..."
    # Xcode may place builds in different locations
    if [[ -d "$BUILD_DIR/$BUILD_TYPE-iphoneos" ]]; then
        echo "  Found: $BUILD_DIR/$BUILD_TYPE-iphoneos/"
        ls -la "$BUILD_DIR/$BUILD_TYPE-iphoneos/" 2>/dev/null | head -5
    elif [[ -d "$BUILD_DIR/build/$BUILD_TYPE-iphoneos" ]]; then
        echo "  Found: $BUILD_DIR/build/$BUILD_TYPE-iphoneos/"
        ls -la "$BUILD_DIR/build/$BUILD_TYPE-iphoneos/" 2>/dev/null | head -5
    else
        log_warn "Could not locate app bundle - check $BUILD_DIR for output"
    fi
    echo ""
    echo "To create IPA:"
    echo "  cd $BUILD_DIR && cpack -C $BUILD_TYPE"
fi
