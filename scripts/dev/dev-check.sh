#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - Pre-Build Developer Checks
# =============================================================================
# Runs source checks required before creating a build.
# This script does NOT configure or build project artifacts.
#
# USAGE:
#   ./scripts/dev/dev-check.sh
#
# CHECKS PERFORMED:
#   1. Apply code formatting (dev-format)
#   2. Verify formatting is clean
#   3. Static analysis (cppcheck)
#   4. Project file sanity checks (no configure/build)
#   5. Platform-specific code audit
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/../.."

ERRORS=0

printf "\n=== Running Pre-Build Developer Checks ===\n\n"

# Enforce branch policy: automated checks must run on RME-DEV to avoid accidental
# branch creation or commits on feature branches.
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ "$current_branch" != "RME-DEV" ]]; then
        echo "❌ Branch policy violation: current branch is '$current_branch' — switch to 'RME-DEV' before running dev-check.sh" >&2
        exit 1
    fi
fi

# 1. Format source code.
echo ">>> Running dev-format..."
if ./scripts/dev/dev-format.sh; then
    echo "✅ dev-format completed"
else
    echo "❌ dev-format failed"
    ERRORS=$((ERRORS + 1))
fi

# 2. Verify formatting after apply.
echo ""
echo ">>> Verifying formatting..."
if ./scripts/dev/dev-format.sh --check >/dev/null 2>&1; then
    echo "✅ Code formatting OK"
else
    echo "❌ Formatting verification failed"
    ERRORS=$((ERRORS + 1))
fi

# 3. Check cppcheck.
echo ""
echo ">>> Running static analysis..."
if command -v cppcheck >/dev/null 2>&1; then
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

# 4. Project file sanity (no configure/build).
echo ""
echo ">>> Checking project file sanity..."
if [[ ! -f "CMakeLists.txt" ]]; then
    echo "❌ Missing CMakeLists.txt"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ CMakeLists.txt present"
fi

if [[ ! -f "cmake/toolchain/ios.toolchain.cmake" ]]; then
    echo "❌ Missing iOS toolchain file: cmake/toolchain/ios.toolchain.cmake"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ iOS toolchain file present"
fi

# 5. Check for common issues.
echo ""
echo ">>> Checking for common issues..."

# Check for Windows-only code accidentally added.
# Allowlist known false positives from game window APIs and platform_compat.
WIN_REFS=$(rg -n "WIN32|_WIN32|Windows" src --glob "*.cc" --glob "*.h" 2>/dev/null \
    | rg -v "// " \
    | rg -v "updateWindows\(|src/platform_compat\.cc:" \
    | head -5 || true)
if [[ -n "$WIN_REFS" ]]; then
    echo "⚠️  Found Windows references (this is Apple-only fork):"
    echo "$WIN_REFS"
fi

# Check for Android references.
ANDROID_REFS=$(rg -n "ANDROID|android" src --glob "*.cc" --glob "*.h" 2>/dev/null | head -5 || true)
if [[ -n "$ANDROID_REFS" ]]; then
    echo "⚠️  Found Android references (this is Apple-only fork):"
    echo "$ANDROID_REFS"
fi

echo "✅ Common issues check complete"

# Summary.
echo ""
echo "=== Summary ==="
if [[ $ERRORS -eq 0 ]]; then
    echo "✅ All checks passed!"
    exit 0
else
    echo "❌ $ERRORS check(s) failed"
    exit 1
fi
