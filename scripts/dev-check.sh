#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - Pre-Commit Checks
# =============================================================================
# Runs code quality checks before committing. Should pass before pushing.
#
# USAGE:
#   ./scripts/check.sh         # Run all checks
#
# CHECKS PERFORMED:
#   1. Code formatting (clang-format)
#   2. Static analysis (cppcheck)
#   3. CMake configuration validation
#   4. Platform-specific code audit
#
# REQUIREMENTS:
#   - clang-format (brew install clang-format)
#   - cppcheck (brew install cppcheck)
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

ERRORS=0

echo ""
echo "=== Running Pre-Commit Checks ==="
echo ""

# 1. Check clang-format
echo ">>> Checking code formatting..."
if command -v clang-format &> /dev/null; then
    FORMAT_ISSUES=$(find src -type f \( -name "*.cc" -o -name "*.h" \) -exec clang-format --dry-run --Werror {} \; 2>&1 || true)
    if [[ -n "$FORMAT_ISSUES" ]]; then
        echo "❌ Formatting issues found. Run: ./scripts/dev-format.sh"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ Code formatting OK"
    fi
else
    echo "⚠️  clang-format not found, skipping format check"
fi

# 2. Check cppcheck
echo ""
echo ">>> Running static analysis..."
if command -v cppcheck &> /dev/null; then
    CPPCHECK_OUT=$(cppcheck --std=c++17 --error-exitcode=1 --quiet src/ 2>&1 || true)
    if [[ -n "$CPPCHECK_OUT" ]]; then
        echo "❌ Static analysis found issues:"
        echo "$CPPCHECK_OUT"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ Static analysis OK"
    fi
else
    echo "⚠️  cppcheck not found, skipping static analysis"
    echo "   Install with: brew install cppcheck"
fi

# 3. Check CMakeLists.txt syntax
echo ""
echo ">>> Checking CMake configuration..."
if cmake -B /tmp/fallout1-rebirth-check -D CMAKE_BUILD_TYPE=Debug > /dev/null 2>&1; then
    echo "✅ CMake configuration OK"
    rm -rf /tmp/fallout1-rebirth-check
else
    echo "❌ CMake configuration failed"
    ERRORS=$((ERRORS + 1))
fi

# 4. Check for common issues
echo ""
echo ">>> Checking for common issues..."

# Check for Windows-only code accidentally added
WIN_REFS=$(grep -rn "WIN32\|_WIN32\|Windows" src/ --include="*.cc" --include="*.h" 2>/dev/null | grep -v "// " | head -5 || true)
if [[ -n "$WIN_REFS" ]]; then
    echo "⚠️  Found Windows references (this is Apple-only fork):"
    echo "$WIN_REFS"
fi

# Check for Android references
ANDROID_REFS=$(grep -rn "ANDROID\|android" src/ --include="*.cc" --include="*.h" 2>/dev/null | head -5 || true)
if [[ -n "$ANDROID_REFS" ]]; then
    echo "⚠️  Found Android references (this is Apple-only fork):"
    echo "$ANDROID_REFS"
fi

echo "✅ Common issues check complete"

# Summary
echo ""
echo "=== Summary ==="
if [[ $ERRORS -eq 0 ]]; then
    echo "✅ All checks passed!"
    exit 0
else
    echo "❌ $ERRORS check(s) failed"
    exit 1
fi
