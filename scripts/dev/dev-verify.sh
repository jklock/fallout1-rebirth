#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - Build Verification
# =============================================================================
# Verifies an existing build artifact and optional runtime startup.
# This script does NOT configure or build.
#
# USAGE:
#   ./scripts/dev/dev-verify.sh
#   ./scripts/dev/dev-verify.sh --build-dir build-macos
#   ./scripts/dev/dev-verify.sh --app "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
#   ./scripts/dev/dev-verify.sh --binary "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
#   ./scripts/dev/dev-verify.sh --game-data /path/to/patchedfiles
# =============================================================================
set -euo pipefail

START_DIR="$(pwd)"
cd "$(dirname "$0")/../.."

ERRORS=0
SKIPPED=0
BUILD_DIR="${BUILD_DIR:-build-macos}"
GAME_DATA="${GAME_DATA:-}"
APP_OVERRIDE=""
BINARY_OVERRIDE=""
APP_BUNDLE=""
BINARY=""
PLIST_PATH=""
TIMEOUT_BIN=""

pick_timeout() {
    if command -v gtimeout >/dev/null 2>&1; then
        TIMEOUT_BIN="gtimeout"
    elif command -v timeout >/dev/null 2>&1; then
        TIMEOUT_BIN="timeout"
    else
        TIMEOUT_BIN=""
    fi
}

show_help() {
    cat <<'USAGE'
Fallout 1 Rebirth - Build Verification

USAGE:
    ./scripts/dev/dev-verify.sh [OPTIONS]

OPTIONS:
    --build-dir PATH   Build output directory to inspect (default: build-macos)
    --app PATH         App bundle path to verify
    --binary PATH      Executable path to verify
    --game-data PATH   Game data path for startup smoke test
    --help             Show this help text

NOTES:
    - This script validates existing artifacts only.
    - It does not run cmake configure/build.
USAGE
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --app)
            APP_OVERRIDE="$2"
            shift 2
            ;;
        --binary)
            BINARY_OVERRIDE="$2"
            shift 2
            ;;
        --game-data)
            GAME_DATA="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help
            ;;
    esac
done

resolve_optional_dir() {
    local path="$1"
    if [[ -z "$path" ]]; then
        printf "\n"
        return 0
    fi
    if [[ "$path" != /* ]]; then
        path="$START_DIR/$path"
    fi
    if [[ -d "$path" ]]; then
        (cd "$path" && pwd)
        return 0
    fi
    printf "\n"
    return 1
}

find_app_bundle_candidate() {
    local candidates=(
        "$BUILD_DIR/RelWithDebInfo/Fallout 1 Rebirth.app"
        "$BUILD_DIR/Debug/Fallout 1 Rebirth.app"
        "$BUILD_DIR/Release/Fallout 1 Rebirth.app"
        "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
        "build-macos/Debug/Fallout 1 Rebirth.app"
        "build-macos/Release/Fallout 1 Rebirth.app"
        "$BUILD_DIR/RelWithDebInfo-iphonesimulator/fallout1-rebirth.app"
        "$BUILD_DIR/Debug-iphonesimulator/fallout1-rebirth.app"
        "$BUILD_DIR/Release-iphonesimulator/fallout1-rebirth.app"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -d "$candidate" ]]; then
            printf "%s\n" "$candidate"
            return 0
        fi
    done

    find "$BUILD_DIR" -maxdepth 4 -type d -name "*.app" -print -quit 2>/dev/null || true
}

find_binary_candidate() {
    local candidates=(
        "$BUILD_DIR/fallout1-rebirth"
        "$BUILD_DIR/RelWithDebInfo/fallout1-rebirth"
        "$BUILD_DIR/Debug/fallout1-rebirth"
        "$BUILD_DIR/Release/fallout1-rebirth"
        "$BUILD_DIR/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
        "$BUILD_DIR/Debug/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
        "$BUILD_DIR/Release/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
        "$BUILD_DIR/RelWithDebInfo-iphonesimulator/fallout1-rebirth.app/fallout1-rebirth"
        "$BUILD_DIR/Debug-iphonesimulator/fallout1-rebirth.app/fallout1-rebirth"
        "$BUILD_DIR/Release-iphonesimulator/fallout1-rebirth.app/fallout1-rebirth"
        "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
        "build-macos/Debug/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
        "build-macos/Release/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -x "$candidate" ]]; then
            printf "%s\n" "$candidate"
            return 0
        fi
    done

    find "$BUILD_DIR" -type f -name "fallout1-rebirth" -perm -111 -print -quit 2>/dev/null || true
}

extract_executable_name() {
    local plist="$1"
    if [[ -f "$plist" ]]; then
        /usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist" 2>/dev/null || true
    fi
}

resolve_from_app_bundle() {
    local app="$1"
    local plist_mac="$app/Contents/Info.plist"
    local plist_ios="$app/Info.plist"
    local exe_name=""

    if [[ -f "$plist_mac" ]]; then
        PLIST_PATH="$plist_mac"
        exe_name="$(extract_executable_name "$plist_mac")"
        local mac_candidates=(
            "$app/Contents/MacOS/${exe_name:-fallout1-rebirth}"
            "$app/Contents/MacOS/fallout1-rebirth"
            "$app/Contents/MacOS/Fallout 1 Rebirth"
        )
        local c
        for c in "${mac_candidates[@]}"; do
            if [[ -x "$c" ]]; then
                BINARY="$c"
                return 0
            fi
        done
    elif [[ -f "$plist_ios" ]]; then
        PLIST_PATH="$plist_ios"
        exe_name="$(extract_executable_name "$plist_ios")"
        local ios_candidates=(
            "$app/${exe_name:-fallout1-rebirth}"
            "$app/fallout1-rebirth"
        )
        local c
        for c in "${ios_candidates[@]}"; do
            if [[ -x "$c" ]]; then
                BINARY="$c"
                return 0
            fi
        done
    fi

    return 1
}

GAME_DATA_INVALID=0
GAME_DATA_RAW="$GAME_DATA"
if [[ -n "$GAME_DATA" ]]; then
    GAME_DATA_RESOLVED="$(resolve_optional_dir "$GAME_DATA" || true)"
    if [[ -z "$GAME_DATA_RESOLVED" ]]; then
        GAME_DATA_INVALID=1
    else
        GAME_DATA="$GAME_DATA_RESOLVED"
    fi
fi

if [[ -n "$APP_OVERRIDE" ]]; then
    APP_BUNDLE="$APP_OVERRIDE"
elif [[ -d "$BUILD_DIR" ]]; then
    APP_BUNDLE="$(find_app_bundle_candidate || true)"
fi

if [[ -n "$BINARY_OVERRIDE" ]]; then
    BINARY="$BINARY_OVERRIDE"
fi

if [[ -n "$APP_BUNDLE" && -d "$APP_BUNDLE" ]]; then
    resolve_from_app_bundle "$APP_BUNDLE" || true
fi

if [[ -z "$BINARY" && -d "$BUILD_DIR" ]]; then
    BINARY="$(find_binary_candidate || true)"
fi

if [[ -z "$APP_BUNDLE" && -n "$BINARY" && "$BINARY" == *".app/"* ]]; then
    APP_BUNDLE="${BINARY%%.app/*}.app"
fi

if [[ -z "$PLIST_PATH" && -n "$APP_BUNDLE" ]]; then
    if [[ -f "$APP_BUNDLE/Contents/Info.plist" ]]; then
        PLIST_PATH="$APP_BUNDLE/Contents/Info.plist"
    elif [[ -f "$APP_BUNDLE/Info.plist" ]]; then
        PLIST_PATH="$APP_BUNDLE/Info.plist"
    fi
fi

echo ""
echo "=== Fallout 1 Rebirth Build Verification ==="
echo "Build directory: $BUILD_DIR"
echo "App bundle:      ${APP_BUNDLE:-<not found>}"
echo "Binary:          ${BINARY:-<not found>}"
if [[ -n "$GAME_DATA" ]]; then
    echo "Game data:       $GAME_DATA"
else
    echo "Game data:       (not set)"
fi
echo ""

echo ">>> Test 1: Build artifact presence"
if [[ -n "$BINARY" && -x "$BINARY" ]]; then
    echo "PASS: executable exists and is executable"
else
    echo "FAIL: executable not found. Build first, then rerun dev-verify."
    echo "      Expected under $BUILD_DIR or via --binary"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo ">>> Test 2: Executable format"
if [[ -n "$BINARY" && -f "$BINARY" ]]; then
    file_info="$(file "$BINARY" 2>/dev/null || true)"
    if [[ "$file_info" == *"Mach-O"* ]]; then
        echo "PASS: Mach-O executable"
        echo "      $file_info"
    else
        echo "FAIL: executable is not a Mach-O binary"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "SKIP: no executable path available"
    SKIPPED=$((SKIPPED + 1))
fi

echo ""
echo ">>> Test 3: Bundle metadata"
if [[ -n "$APP_BUNDLE" && -d "$APP_BUNDLE" ]]; then
    if [[ -n "$PLIST_PATH" && -f "$PLIST_PATH" ]]; then
        if plutil -lint "$PLIST_PATH" >/dev/null 2>&1; then
            echo "PASS: Info.plist syntax valid"
            bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST_PATH" 2>/dev/null || echo "")
            bundle_ver=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST_PATH" 2>/dev/null || echo "")
            echo "      CFBundleIdentifier=${bundle_id:-<missing>}"
            echo "      CFBundleShortVersionString=${bundle_ver:-<missing>}"
        else
            echo "FAIL: Info.plist syntax invalid"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "FAIL: Info.plist not found in app bundle"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "SKIP: app bundle not found"
    SKIPPED=$((SKIPPED + 1))
fi

echo ""
echo ">>> Test 4: Dynamic library linkage"
if [[ -n "$BINARY" && -x "$BINARY" ]]; then
    if otool -L "$BINARY" >/dev/null 2>&1; then
        echo "PASS: otool dependency listing succeeded"
        otool -L "$BINARY" 2>/dev/null | head -10 | sed 's/^/      /'
    else
        echo "FAIL: unable to read binary dynamic libraries via otool"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "SKIP: no executable path available"
    SKIPPED=$((SKIPPED + 1))
fi

echo ""
echo ">>> Test 5: Startup smoke"
pick_timeout
if [[ -z "$TIMEOUT_BIN" ]]; then
    echo "SKIP: timeout command not available"
    SKIPPED=$((SKIPPED + 1))
elif [[ -z "$BINARY" || ! -x "$BINARY" ]]; then
    echo "SKIP: no executable path available"
    SKIPPED=$((SKIPPED + 1))
elif [[ "$GAME_DATA_INVALID" -eq 1 ]]; then
    echo "FAIL: game data path does not exist: $GAME_DATA_RAW"
    ERRORS=$((ERRORS + 1))
else
    smoke_dir="$(dirname "$BINARY")"
    if [[ -n "$GAME_DATA" ]]; then
        if [[ -f "$GAME_DATA/master.dat" && -f "$GAME_DATA/critter.dat" && -d "$GAME_DATA/data" ]]; then
            smoke_dir="$GAME_DATA"
        else
            echo "FAIL: game data is incomplete at $GAME_DATA"
            ERRORS=$((ERRORS + 1))
            smoke_dir=""
        fi
    fi

    if [[ -n "$smoke_dir" ]]; then
        tmp_log="$(mktemp -t dev-verify-smoke.XXXXXX.log)"
        set +e
        (
            cd "$smoke_dir"
            "$TIMEOUT_BIN" 5 "$BINARY"
        ) >"$tmp_log" 2>&1
        rc=$?
        set -e

        if rg -q "dyld|Library not loaded|image not found|Abort trap|Segmentation fault" "$tmp_log"; then
            echo "FAIL: startup output indicates linker/runtime failure"
            sed -n '1,20p' "$tmp_log" | sed 's/^/      /'
            ERRORS=$((ERRORS + 1))
        elif [[ "$rc" -eq 0 || "$rc" -eq 1 || "$rc" -eq 124 || "$rc" -eq 143 ]]; then
            echo "PASS: executable started (exit code $rc)"
        else
            echo "FAIL: unexpected startup exit code $rc"
            sed -n '1,20p' "$tmp_log" | sed 's/^/      /'
            ERRORS=$((ERRORS + 1))
        fi

        rm -f "$tmp_log"
    fi
fi

echo ""
echo "=== Summary ==="
echo "Errors:  $ERRORS"
echo "Skipped: $SKIPPED"

if [[ "$ERRORS" -eq 0 ]]; then
    echo "PASS: existing build verification succeeded"
    exit 0
fi

echo "FAIL: build verification failed"
exit 1
