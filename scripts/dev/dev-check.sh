#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - Pre-Commit Checks
# =============================================================================
# Runs code quality checks before committing. Should pass before pushing.
#
# USAGE:
#   ./scripts/dev/dev-check.sh         # Run all checks
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

cd "$(dirname "$0")/../.."

ERRORS=0

echo ""
echo "=== Running Pre-Commit Checks ==="
echo ""

# Enforce branch policy: automated checks must run on RME-DEV to avoid accidental
# branch creation or commits on feature branches. This prevents agents from
# creating or committing to other branches without explicit authorization.
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ "$current_branch" != "RME-DEV" ]]; then
        echo "❌ Branch policy violation: current branch is '$current_branch' — switch to 'RME-DEV' before running dev-check.sh" >&2
        exit 1
    fi
fi

# 1. Check clang-format
echo ">>> Checking code formatting..."
if command -v clang-format &> /dev/null; then
    FORMAT_ISSUES=$(find src -type f \( -name "*.cc" -o -name "*.h" \) -exec clang-format --dry-run --Werror {} \; 2>&1 || true)
    if [[ -n "$FORMAT_ISSUES" ]]; then
        echo "❌ Formatting issues found. Run: ./scripts/dev/dev-format.sh"
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
TMP_CHECK_DIR="$PWD/tmp/fallout1-rebirth-check"
if cmake -B "$TMP_CHECK_DIR" -D CMAKE_BUILD_TYPE=Debug > /dev/null 2>&1; then
    echo "✅ CMake configuration OK"
    rm -rf "$TMP_CHECK_DIR"
else
    echo "❌ CMake configuration failed"
    ERRORS=$((ERRORS + 1))
fi

# 4. Check for common issues
echo ""
echo ">>> Checking for common issues..."

# Check for Windows-only code accidentally added
# Allowlist known false positives from game window APIs and platform_compat.
WIN_REFS=$(grep -rn "WIN32\|_WIN32\|Windows" src/ --include="*.cc" --include="*.h" 2>/dev/null \
    | grep -v "// " \
    | grep -vE "updateWindows\(|src/platform_compat\.cc:" \
    | head -5 || true)
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
