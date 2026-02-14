#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — macOS Build Script
# =============================================================================
# Builds the macOS app bundle using Xcode generator.
#
# USAGE:
#   ./scripts/build/build-macos.sh              # Standard build
#   BUILD_TYPE=Debug ./scripts/build/build-macos.sh  # Debug build
#
# CONFIGURATION (environment variables):
#   BUILD_DIR   - Build output directory (default: "build-macos")
#   BUILD_TYPE  - Debug/Release/RelWithDebInfo (default: "RelWithDebInfo")
#   JOBS        - Parallel jobs (default: physical CPU count)
#   CLEAN       - Set to "1" to force reconfigure
#   F1R_DISABLE_RME_LOGGING - Set to 1/ON to compile out Rebirth diagnostic logging
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
BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"
CLEAN="${CLEAN:-0}"
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
echo " Fallout 1 Rebirth — macOS Build"
echo "=============================================="
echo " Build directory: $BUILD_DIR"
echo " Build type:      $BUILD_TYPE"
echo " Parallel jobs:   $JOBS"
echo " RME logging:     $RME_LOGGING_CMAKE (compile option)"
echo "=============================================="
echo ""

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
    log_info "Configuring CMake with Xcode generator..."
    cmake -B "$BUILD_DIR" \
        -G Xcode \
        -D F1R_DISABLE_RME_LOGGING="$RME_LOGGING_CMAKE" \
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
APP_PATH="$BUILD_DIR/$BUILD_TYPE/Fallout 1 Rebirth.app"
EXECUTABLE="$APP_PATH/Contents/MacOS/fallout1-rebirth"

if [[ -d "$APP_PATH" && -x "$EXECUTABLE" ]]; then
    echo ""
    log_ok "Build successful!"
    echo ""
    echo "  App bundle: $APP_PATH"
    echo "  Executable: $EXECUTABLE"
    echo "  Size:       $(du -sh "$APP_PATH" | cut -f1)"
    echo ""
    # Show architecture info
    log_info "Binary architecture:"
    file "$EXECUTABLE" | sed 's/.*: /    /'
    echo ""
    echo "To run (requires game data in same directory or configured path):"
    echo "  open \"$APP_PATH\""
    echo ""
    echo "To create DMG for distribution:"
    echo "  cd $BUILD_DIR && cpack -C $BUILD_TYPE"
else
    echo ""
    log_error "Build verification failed!"
    if [[ ! -d "$APP_PATH" ]]; then
        log_error "App bundle not found: $APP_PATH"
    elif [[ ! -x "$EXECUTABLE" ]]; then
        log_error "Executable not found or not executable: $EXECUTABLE"
    fi
    exit 1
fi
