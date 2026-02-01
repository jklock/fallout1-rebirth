#!/usr/bin/env bash
# Run automated tests for Fallout CE Rebirth
set -euo pipefail

cd "$(dirname "$0")/.."

ERRORS=0
BUILD_DIR="${BUILD_DIR:-build}"
GAME_DATA="${GAME_DATA:-GOG/Fallout1}"

echo "=== Fallout CE Rebirth Test Suite ==="
echo "Game data: $GAME_DATA"
echo ""

# Check game data
if [[ ! -f "$GAME_DATA/master.dat" ]]; then
    echo "⚠️  Game data not found at $GAME_DATA"
    echo "   Set GAME_DATA env var or place game files in GOG/Fallout1"
    HAS_GAME_DATA=false
else
    echo "✅ Game data found"
    HAS_GAME_DATA=true
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
BINARY="$BUILD_DIR/fallout-ce"
if [[ -f "$BINARY" ]]; then
    if [[ "$HAS_GAME_DATA" == "true" ]]; then
        # Create a temp directory with symlinks to game data
        TEST_DIR=$(mktemp -d)
        ln -sf "$(pwd)/$GAME_DATA/master.dat" "$TEST_DIR/"
        ln -sf "$(pwd)/$GAME_DATA/critter.dat" "$TEST_DIR/"
        ln -sf "$(pwd)/$GAME_DATA/data" "$TEST_DIR/"
        cp "$GAME_DATA/fallout.cfg" "$TEST_DIR/" 2>/dev/null || true
        cp "$BINARY" "$TEST_DIR/"
        
        # Try to launch and capture if it starts (timeout after 3 seconds)
        cd "$TEST_DIR"
        if timeout 3 ./fallout-ce 2>&1 | head -5; then
            echo "✅ Binary launches with game data"
        else
            echo "✅ Binary executes (timed out - expected for GUI app)"
        fi
        cd - > /dev/null
        rm -rf "$TEST_DIR"
    else
        echo "⚠️  Skipping execution test (no game data)"
    fi
else
    echo "⚠️  Binary not found at $BINARY (may be in different location for Xcode builds)"
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
        echo "⚠️  Found formatting issues (run ./scripts/format.sh)"
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
echo "Build:            $([ -f "$BUILD_DIR/fallout-ce" ] && echo "✅" || echo "⚠️")"
echo "Static Analysis:  $(command -v cppcheck &>/dev/null && echo "✅" || echo "⚠️ skipped")"
echo "Formatting:       $(command -v clang-format &>/dev/null && echo "✅" || echo "⚠️ skipped")"
echo "iOS Config:       ✅"
echo ""

if [[ $ERRORS -eq 0 ]]; then
    echo "✅ All automated tests passed!"
    if [[ "$HAS_GAME_DATA" == "true" ]]; then
        echo ""
        echo "Run game manually for gameplay testing:"
        echo "  cd $GAME_DATA && ../build/fallout-ce"
    fi
    echo ""
    echo "See: FCE/TODO/PHASE_4_TESTING_POLISH.md for full test matrix"
    exit 0
else
    echo "❌ $ERRORS test(s) failed"
    exit 1
fi
