#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - iOS Build Script
# =============================================================================
# Single iOS build entrypoint with explicit build intent.
#
# MODES:
#   -prod   Build release-style artifacts (no embedded game data/config)
#   -test   Build test artifacts with patched game data/config embedded
#
# TARGETS:
#   --device      Build device app + IPA
#   --simulator   Build simulator app
#   --both        Build device and simulator artifacts
#
# USAGE:
#   ./scripts/build/build-ios.sh -prod
#   ./scripts/build/build-ios.sh -test --both --game-data /path/to/patchedfiles
#
# ENVIRONMENT:
#   BUILD_TYPE, JOBS, CLEAN, BUILD_DIR_DEVICE, BUILD_DIR_SIM
#   F1R_DISABLE_RME_LOGGING, FALLOUT_GAMEFILES_ROOT, GAME_DATA
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ -f ".f1r-build.env" ]]; then
    # shellcheck disable=SC1091
    source ".f1r-build.env"
fi

MODE="prod"
TARGET="device"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"
CLEAN="${CLEAN:-0}"
BUILD_DIR_DEVICE="${BUILD_DIR_DEVICE:-build-ios}"
BUILD_DIR_SIM="${BUILD_DIR_SIM:-build-ios-sim}"
TOOLCHAIN="cmake/toolchain/ios.toolchain.cmake"
DEPLOYMENT_TARGET_DEVICE="${DEPLOYMENT_TARGET_DEVICE:-26.0}"
DEPLOYMENT_TARGET_SIM="${DEPLOYMENT_TARGET_SIM:-26.0}"
OUTPUT_DIR="$ROOT_DIR/build-outputs/iOS"
GAME_DATA="${GAME_DATA:-}"
GAMEFILES_ROOT="${FALLOUT_GAMEFILES_ROOT:-${GAMEFILES_ROOT:-}}"
APP_NAME="fallout1-rebirth"
IOS_CONFIG_DIR="$ROOT_DIR/gameconfig/ios"

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
RME_LOGGING_CMAKE_UPPER="$(printf '%s' "$RME_LOGGING_CMAKE" | tr '[:lower:]' '[:upper:]')"

usage() {
    cat <<USAGE
Fallout 1 Rebirth - iOS Build

USAGE:
  ./scripts/build/build-ios.sh MODE [TARGET] [OPTIONS]

MODE:
  -prod                Build release artifact(s) with no embedded game data/config
  -test                Build test artifact(s) with patched data/config embedded

TARGET:
  --device             Build device app + IPA (default)
  --simulator          Build simulator app only
  --both               Build both device + simulator artifacts

OPTIONS:
  --game-data PATH     Patched data source (master.dat, critter.dat, data/)
                       Required in -test mode unless GAME_DATA or FALLOUT_GAMEFILES_ROOT is set.
  --help               Show this help

EXAMPLES:
  ./scripts/build/build-ios.sh -prod
  ./scripts/build/build-ios.sh -test --device --game-data /path/to/patchedfiles
  ./scripts/build/build-ios.sh -test --both
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
        --device)
            TARGET="device"
            shift
            ;;
        --simulator)
            TARGET="simulator"
            shift
            ;;
        --both)
            TARGET="both"
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

if [[ ! -f "$TOOLCHAIN" ]]; then
    log_error "iOS toolchain not found: $TOOLCHAIN"
    exit 1
fi

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

stage_test_payload_ios() {
    local app_path="$1"

    if [[ ! -d "$app_path" ]]; then
        log_error "Cannot stage test payload; app not found: $app_path"
        exit 1
    fi

    log_info "Staging test payload into $app_path"

    cp -f "$GAME_DATA/master.dat" "$app_path/"
    cp -f "$GAME_DATA/critter.dat" "$app_path/"
    rm -rf "$app_path/data"
    cp -R "$GAME_DATA/data" "$app_path/"
    stage_ios_configs "$app_path"

    log_ok "Embedded patched data/config into app payload"
}

stage_ios_configs() {
    local app_path="$1"

    if [[ ! -d "$app_path" ]]; then
        log_error "Cannot stage configs; app not found: $app_path"
        exit 1
    fi

    if [[ -f "$IOS_CONFIG_DIR/fallout.cfg" ]]; then
        cp -f "$IOS_CONFIG_DIR/fallout.cfg" "$app_path/fallout.cfg"
    elif [[ -n "$GAME_DATA" && -f "$GAME_DATA/fallout.cfg" ]]; then
        cp -f "$GAME_DATA/fallout.cfg" "$app_path/fallout.cfg"
    else
        cat > "$app_path/fallout.cfg" <<'CFG'
[system]
master_dat=master.dat
master_patches=data
critter_dat=critter.dat
critter_patches=data
CFG
    fi

    if [[ -f "$IOS_CONFIG_DIR/f1_res.ini" ]]; then
        cp -f "$IOS_CONFIG_DIR/f1_res.ini" "$app_path/f1_res.ini"
    elif [[ -n "$GAME_DATA" && -f "$GAME_DATA/f1_res.ini" ]]; then
        cp -f "$GAME_DATA/f1_res.ini" "$app_path/f1_res.ini"
    fi
}

configure_and_build_device() {
    local build_dir="$BUILD_DIR_DEVICE"

    if [[ "$CLEAN" == "1" && -d "$build_dir" ]]; then
        log_warn "CLEAN=1 set, removing $build_dir"
        rm -rf "$build_dir"
    fi

    local needs_config=0
    if [[ ! -f "$build_dir/CMakeCache.txt" ]]; then
        needs_config=1
    else
        cached_flag="$(grep '^F1R_DISABLE_RME_LOGGING:BOOL=' "$build_dir/CMakeCache.txt" | head -n1 | cut -d'=' -f2 || true)"
        cached_platform="$(grep '^PLATFORM:STRING=' "$build_dir/CMakeCache.txt" | head -n1 | cut -d'=' -f2 || true)"
        cached_flag_upper="$(printf '%s' "$cached_flag" | tr '[:lower:]' '[:upper:]')"
        if [[ "$cached_flag_upper" != "$RME_LOGGING_CMAKE_UPPER" || "$cached_platform" != "OS64" ]]; then
            needs_config=1
        fi
    fi

    if [[ "$needs_config" == "1" ]]; then
        log_info "Configuring iOS device build"
        cmake -B "$build_dir" \
            -D CMAKE_BUILD_TYPE="$BUILD_TYPE" \
            -D CMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
            -D F1R_DISABLE_RME_LOGGING="$RME_LOGGING_CMAKE" \
            -D ENABLE_BITCODE=0 \
            -D PLATFORM=OS64 \
            -D DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET_DEVICE" \
            -G Xcode \
            -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY='' \
            -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO
    else
        log_info "Using existing iOS device CMake configuration"
    fi

    log_info "Building iOS device target ($BUILD_TYPE)"
    cmake --build "$build_dir" --config "$BUILD_TYPE" -j "$JOBS"

    local app_path="$build_dir/$BUILD_TYPE-iphoneos/$APP_NAME.app"
    local exe_path="$app_path/$APP_NAME"

    if [[ ! -d "$app_path" || ! -x "$exe_path" ]]; then
        log_error "Device app build output missing: $app_path"
        exit 1
    fi

    if [[ "$MODE" == "test" ]]; then
        stage_test_payload_ios "$app_path"
    else
        stage_ios_configs "$app_path"
    fi

    log_info "Packaging IPA with CPack"
    (
        cd "$build_dir"
        cpack -C "$BUILD_TYPE"
    )

    ipa_path="$(ls -t "$build_dir"/*.ipa 2>/dev/null | head -1 || true)"
    if [[ -z "$ipa_path" ]]; then
        log_error "No IPA produced in $build_dir"
        exit 1
    fi

    mkdir -p "$OUTPUT_DIR"
    local ipa_name
    ipa_name="$(basename "$ipa_path")"
    if [[ "$MODE" == "test" && "$ipa_name" != *"-test.ipa" ]]; then
        ipa_name="${ipa_name%.ipa}-test.ipa"
    fi
    cp -f "$ipa_path" "$OUTPUT_DIR/$ipa_name"

    log_ok "Device IPA ready: $OUTPUT_DIR/$ipa_name"
}

configure_and_build_simulator() {
    local build_dir="$BUILD_DIR_SIM"
    local sim_platform
    if [[ "$(uname -m)" == "x86_64" ]]; then
        sim_platform="SIMULATOR64"
    else
        sim_platform="SIMULATORARM64"
    fi

    if [[ "$CLEAN" == "1" && -d "$build_dir" ]]; then
        log_warn "CLEAN=1 set, removing $build_dir"
        rm -rf "$build_dir"
    fi

    local needs_config=0
    if [[ ! -f "$build_dir/CMakeCache.txt" ]]; then
        needs_config=1
    else
        cached_platform="$(grep '^PLATFORM:STRING=' "$build_dir/CMakeCache.txt" | head -n1 | cut -d'=' -f2 || true)"
        cached_flag="$(grep '^F1R_DISABLE_RME_LOGGING:BOOL=' "$build_dir/CMakeCache.txt" | head -n1 | cut -d'=' -f2 || true)"
        cached_flag_upper="$(printf '%s' "$cached_flag" | tr '[:lower:]' '[:upper:]')"
        if [[ "$cached_platform" != "$sim_platform" || "$cached_flag_upper" != "$RME_LOGGING_CMAKE_UPPER" ]]; then
            needs_config=1
        fi
    fi

    if [[ "$needs_config" == "1" ]]; then
        log_info "Configuring iOS simulator build ($sim_platform)"
        cmake -B "$build_dir" \
            -D CMAKE_BUILD_TYPE="$BUILD_TYPE" \
            -D CMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
            -D F1R_DISABLE_RME_LOGGING="$RME_LOGGING_CMAKE" \
            -D ENABLE_BITCODE=0 \
            -D PLATFORM="$sim_platform" \
            -D DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET_SIM" \
            -G Xcode \
            -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY='' \
            -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO
    else
        log_info "Using existing iOS simulator CMake configuration"
    fi

    log_info "Building iOS simulator target ($BUILD_TYPE)"
    cmake --build "$build_dir" --config "$BUILD_TYPE" -j "$JOBS" -- EXCLUDED_ARCHS=""

    local app_path="$build_dir/$BUILD_TYPE-iphonesimulator/$APP_NAME.app"
    local exe_path="$app_path/$APP_NAME"
    if [[ ! -d "$app_path" || ! -x "$exe_path" ]]; then
        log_error "Simulator app build output missing: $app_path"
        exit 1
    fi

    if [[ "$MODE" == "test" ]]; then
        stage_test_payload_ios "$app_path"
    else
        stage_ios_configs "$app_path"
    fi

    log_ok "Simulator app ready: $app_path"
}

echo ""
echo "=============================================="
echo " Fallout 1 Rebirth - iOS Build"
echo "=============================================="
echo " Mode:            $MODE"
echo " Target:          $TARGET"
echo " Build type:      $BUILD_TYPE"
echo " Device build:    $BUILD_DIR_DEVICE"
echo " Simulator build: $BUILD_DIR_SIM"
echo "=============================================="

if [[ "$MODE" == "test" ]]; then
    resolve_game_data
    echo " Test data:       $GAME_DATA"
fi

echo ""

case "$TARGET" in
    device)
        configure_and_build_device
        ;;
    simulator)
        configure_and_build_simulator
        ;;
    both)
        configure_and_build_device
        configure_and_build_simulator
        ;;
    *)
        log_error "Invalid target: $TARGET"
        exit 2
        ;;
esac

echo ""
log_ok "iOS build completed"
