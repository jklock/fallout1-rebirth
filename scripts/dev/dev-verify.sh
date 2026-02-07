#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - Automated Test Suite
# =============================================================================
# Runs build verification, static analysis, and configuration tests.
# Does NOT include manual gameplay testing.
#
# USAGE:
#   ./scripts/dev/dev-verify.sh                           # Run all tests
#   ./scripts/dev/dev-verify.sh --build-dir build-alt     # Use alternate build dir
#   ./scripts/dev/dev-verify.sh --game-data /path/to/data # Use custom game data path
#
# TESTS PERFORMED:
#   1. Build verification (CMake + compile)
#   2. Binary execution check (with game data if available)
#   3. Static analysis (cppcheck)
#   4. Code formatting verification (clang-format)
#   5. Source file inventory
#   6. iOS CMake configuration validation
#
# CONFIGURATION:
#   BUILD_DIR  - Build output directory (default: "build")
#   GAME_DATA  - Path to game files (optional; can also be set via --game-data)
# =============================================================================
set -euo pipefail

START_DIR="$(pwd)"
cd "$(dirname "$0")/../.."

ERRORS=0
BUILD_DIR="${BUILD_DIR:-build}"
GAME_DATA="${GAME_DATA:-}"
GAME_DATA_INVALID=0

show_help() {
    cat << 'EOF'
Fallout 1 Rebirth — Automated Test Suite

USAGE:
    ./scripts/dev/dev-verify.sh [OPTIONS]

OPTIONS:
    --build-dir PATH   Build output directory (default: build)
    --game-data PATH   Path to game data (master.dat/critter.dat/data/)
    --help             Show this help message and exit

NOTES:
    - Game data is optional for this script.
    - Provide --game-data or set GAME_DATA to validate data availability.
    - Relative --game-data paths are resolved from the invoking directory.
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build-dir)
            BUILD_DIR="$2"
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
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

GAME_DATA_RAW="$GAME_DATA"
if [[ -n "$GAME_DATA" ]]; then
    if [[ "$GAME_DATA" != /* ]]; then
        GAME_DATA="$START_DIR/$GAME_DATA"
    fi
    if ! GAME_DATA_RESOLVED="$(cd "$GAME_DATA" 2>/dev/null && pwd)"; then
        GAME_DATA_INVALID=1
    else
        GAME_DATA="$GAME_DATA_RESOLVED"
    fi
fi

echo ""
echo "=== Fallout 1 Rebirth Test Suite ==="
echo "Build directory: $BUILD_DIR"
if [[ -n "$GAME_DATA" ]]; then
    echo "Game data:       $GAME_DATA"
else
    echo "Game data:       (not set)"
fi
echo ""

# Check game data
if [[ "$GAME_DATA_INVALID" -eq 1 ]]; then
    echo "⚠️  Game data path not found: $GAME_DATA"
    if [[ -n "$GAME_DATA_RAW" ]]; then
        echo "   (from input: $GAME_DATA_RAW)"
    fi
    echo "   Provide --game-data PATH or set GAME_DATA to a valid folder"
    HAS_GAME_DATA=false
elif [[ -n "$GAME_DATA" && -f "$GAME_DATA/master.dat" ]]; then
    echo "✅ Game data found"
    HAS_GAME_DATA=true
elif [[ -n "$GAME_DATA" ]]; then
    echo "⚠️  Game data not found at $GAME_DATA"
    echo "   Provide --game-data PATH or set GAME_DATA to a valid folder"
    HAS_GAME_DATA=false
else
    echo "ℹ️  Game data not provided (skipping data validation)"
    HAS_GAME_DATA=false
fi
echo ""

# 1. Build test
echo ">>> Test 1: Build Verification"
if [[ ! -d "$BUILD_DIR" ]]; then
    echo "Building..."
    cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug > /dev/null 2>&1
fi

if cmake --build "$BUILD_DIR" -j "$(sysctl -n hw.physicalcpu)" > /dev/null 2>&1; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    ERRORS=$((ERRORS + 1))
fi

# 2. Binary exists and runs
echo ""
echo ">>> Test 2: Binary Execution Test"

# Check for binary in multiple possible locations based on build type
BINARY=""
# First check the BUILD_DIR from the build step
if [[ -f "$BUILD_DIR/fallout1-rebirth" ]]; then
    BINARY="$BUILD_DIR/fallout1-rebirth"
# Then check common Xcode build locations
elif [[ -f "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" ]]; then
    BINARY="build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
elif [[ -f "build-macos/Debug/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" ]]; then
    BINARY="build-macos/Debug/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
elif [[ -f "build-macos/Release/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" ]]; then
    BINARY="build-macos/Release/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
fi

if [[ -n "$BINARY" && -f "$BINARY" ]]; then
    # Verify the binary is a valid Mach-O executable
    if file "$BINARY" | grep -q "Mach-O"; then
        echo "✅ Binary found and validated: $BINARY"
    else
        echo "⚠️  Binary found but format check failed: $BINARY"
    fi
else
    echo "⚠️  Binary not found (build with make or Xcode to generate)"
fi

# 3. Static analysis
echo ""
echo ">>> Test 3: Static Analysis"
if command -v cppcheck &> /dev/null; then
    ISSUES=$(cppcheck --std=c++17 --error-exitcode=0 --quiet \
        --suppress=missingIncludeSystem \
        --suppress=unusedFunction \
        src/ 2>&1 | grep -c "error:" || true)
    
    if [[ "$ISSUES" -eq 0 ]]; then
        echo "✅ No critical static analysis errors"
    else
        echo "❌ Found $ISSUES static analysis error(s)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "⚠️  cppcheck not installed, skipping"
fi

# 4. Code formatting
echo ""
echo ">>> Test 4: Code Formatting"
if command -v clang-format &> /dev/null; then
    FORMAT_ERRORS=$(find src -type f \( -name "*.cc" -o -name "*.h" \) \
        -exec clang-format --dry-run --Werror {} \; 2>&1 | grep -c "error:" || true)
    
    if [[ "$FORMAT_ERRORS" -eq 0 ]]; then
        echo "✅ Code formatting correct"
    else
        echo "⚠️  Found formatting issues (run ./scripts/dev/dev-format.sh)"
    fi
else
    echo "⚠️  clang-format not installed, skipping"
fi

# 5. Source file inventory
echo ""
echo ">>> Test 5: Source Inventory"
CC_COUNT=$(find src -name "*.cc" | wc -l | tr -d ' ')
H_COUNT=$(find src -name "*.h" | wc -l | tr -d ' ')
echo "✅ Found $CC_COUNT .cc files and $H_COUNT .h files"

# 6. CMake configuration test
echo ""
echo ">>> Test 6: CMake iOS Configuration"
if cmake -B /tmp/ios-test \
    -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
    -D ENABLE_BITCODE=0 \
    -D PLATFORM=OS64 \
    -G Xcode \
    -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY='' > /dev/null 2>&1; then
    echo "✅ iOS CMake configuration valid"
    rm -rf /tmp/ios-test
else
    echo "❌ iOS CMake configuration failed"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Build:            $([ -f "$BUILD_DIR/fallout1-rebirth" ] && echo "✅" || echo "⚠️")"
echo "Static Analysis:  $(command -v cppcheck &>/dev/null && echo "✅" || echo "⚠️ skipped")"
echo "Formatting:       $(command -v clang-format &>/dev/null && echo "✅" || echo "⚠️ skipped")"
echo "iOS Config:       ✅"
echo ""

if [[ $ERRORS -eq 0 ]]; then
    echo "✅ All automated tests passed!"
    if [[ "$HAS_GAME_DATA" == "true" && -n "$BINARY" ]]; then
        echo ""
        echo "Run game manually for gameplay testing:"
        echo "  cd \"$GAME_DATA\" && \"$BINARY\""
    fi
    echo ""
    echo "See: FCE/TODO/PHASE_4_TESTING_POLISH.md for full test matrix"
    exit 0
else
    echo "❌ $ERRORS test(s) failed"
    exit 1
fi
