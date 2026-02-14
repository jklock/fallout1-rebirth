#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - macOS Build Script
# =============================================================================
# Single macOS build entrypoint with explicit build intent.
#
# MODES:
#   -prod   Build release-style app (no embedded game data/config)
#   -test   Build app and embed patched data/config for immediate testing
#
# USAGE:
#   ./scripts/build/build-macos.sh -prod
#   ./scripts/build/build-macos.sh -test --game-data /path/to/patchedfiles
#
# ENVIRONMENT:
#   BUILD_DIR, BUILD_TYPE, JOBS, CLEAN
#   F1R_DISABLE_RME_LOGGING, GAME_DATA, FALLOUT_GAMEFILES_ROOT
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ -f ".f1r-build.env" ]]; then
    # shellcheck disable=SC1091
    source ".f1r-build.env"
fi

MODE="prod"
BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"
CLEAN="${CLEAN:-0}"
GAME_DATA="${GAME_DATA:-}"
GAMEFILES_ROOT="${FALLOUT_GAMEFILES_ROOT:-${GAMEFILES_ROOT:-}}"

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

usage() {
    cat <<USAGE
Fallout 1 Rebirth - macOS Build

USAGE:
  ./scripts/build/build-macos.sh MODE [OPTIONS]

MODE:
  -prod                Build release-style app with no embedded game data
  -test                Build app and embed patched data/config in Resources

OPTIONS:
  --game-data PATH     Patched data source (master.dat, critter.dat, data/)
                       Required in -test mode unless GAME_DATA or FALLOUT_GAMEFILES_ROOT is set.
  --help               Show this help

EXAMPLES:
  ./scripts/build/build-macos.sh -prod
  ./scripts/build/build-macos.sh -test --game-data /path/to/patchedfiles
USAGE
}

log_info()  { echo ">>> $1"; }
log_ok()    { echo "PASS: $1"; }
log_warn()  { echo "WARN: $1"; }
log_error() { echo "FAIL: $1"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -prod|--prod)
            MODE="prod"
            shift
            ;;
        -test|--test)
            MODE="test"
            shift
            ;;
        --game-data)
            GAME_DATA="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage >&2
            exit 2
            ;;
    esac
done

resolve_game_data() {
    if [[ -z "$GAME_DATA" && -n "$GAMEFILES_ROOT" ]]; then
        GAME_DATA="$GAMEFILES_ROOT/patchedfiles"
    fi

    if [[ -z "$GAME_DATA" ]]; then
        log_error "-test mode requires --game-data or GAME_DATA/FALLOUT_GAMEFILES_ROOT"
        exit 2
    fi

    if [[ "$GAME_DATA" != /* ]]; then
        GAME_DATA="$ROOT_DIR/$GAME_DATA"
    fi
    GAME_DATA="$(cd "$GAME_DATA" 2>/dev/null && pwd)" || {
        log_error "Invalid game data path: $GAME_DATA"
        exit 2
    }

    if [[ ! -f "$GAME_DATA/master.dat" || ! -f "$GAME_DATA/critter.dat" || ! -d "$GAME_DATA/data" ]]; then
        log_error "Game data is incomplete at $GAME_DATA (need master.dat, critter.dat, data/)"
        exit 2
    fi
}

if [[ "$CLEAN" == "1" && -d "$BUILD_DIR" ]]; then
    log_warn "CLEAN=1 set, removing $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

NEEDS_CONFIG=0
if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
    NEEDS_CONFIG=1
else
    cached_flag="$(grep '^F1R_DISABLE_RME_LOGGING:BOOL=' "$BUILD_DIR/CMakeCache.txt" | head -n1 | cut -d'=' -f2 || true)"
    if [[ "${cached_flag^^}" != "${RME_LOGGING_CMAKE^^}" ]]; then
        NEEDS_CONFIG=1
    fi
fi

if [[ "$NEEDS_CONFIG" == "1" ]]; then
    log_info "Configuring macOS build"
    cmake -B "$BUILD_DIR" \
        -G Xcode \
        -D F1R_DISABLE_RME_LOGGING="$RME_LOGGING_CMAKE" \
        -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
else
    log_info "Using existing macOS CMake configuration"
fi

log_info "Building macOS target ($BUILD_TYPE)"
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j "$JOBS"

APP_PATH="$BUILD_DIR/$BUILD_TYPE/Fallout 1 Rebirth.app"
EXECUTABLE="$APP_PATH/Contents/MacOS/fallout1-rebirth"

if [[ ! -d "$APP_PATH" || ! -x "$EXECUTABLE" ]]; then
    log_error "Build output missing or invalid: $APP_PATH"
    exit 1
fi

if [[ "$MODE" == "test" ]]; then
    resolve_game_data
    log_info "Embedding test payload from $GAME_DATA"
    "$ROOT_DIR/scripts/build/build-install-game-data.sh" --source "$GAME_DATA" --target "$APP_PATH"
fi

echo ""
echo "=============================================="
echo " Fallout 1 Rebirth - macOS Build"
echo "=============================================="
echo " Mode:       $MODE"
echo " Build dir:  $BUILD_DIR"
echo " Build type: $BUILD_TYPE"
echo " App:        $APP_PATH"
echo " Size:       $(du -sh "$APP_PATH" | cut -f1)"
if [[ "$MODE" == "test" ]]; then
    echo " Test data:  $GAME_DATA"
fi
echo "=============================================="

log_ok "macOS build completed"
