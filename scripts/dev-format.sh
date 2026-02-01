#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - Format Source Code
# =============================================================================
# Applies clang-format to all C++ source and header files in src/.
# Uses the .clang-format configuration file at the repository root.
#
# USAGE:
#   ./scripts/format.sh              # Format all source files
#   ./scripts/format.sh --check      # Check formatting only (no changes)
#
# REQUIREMENTS:
#   - clang-format (brew install clang-format)
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "=== Formatting C++ Source Files ==="
echo ""

if ! command -v clang-format &> /dev/null; then
    echo -e "${RED}clang-format not found${NC}"
    echo "   Install with: brew install clang-format"
    exit 1
fi

# Count files to process
file_count=$(find src -type f \( -name "*.cc" -o -name "*.h" \) | wc -l | tr -d ' ')
echo -e "${BLUE}>>>${NC} Processing $file_count files..."

if [[ "${1:-}" == "--check" ]]; then
    # Check mode - report issues without modifying
    errors=$(find src -type f \( -name "*.cc" -o -name "*.h" \) \
        -exec clang-format --dry-run --Werror {} \; 2>&1 || true)
    if [[ -n "$errors" ]]; then
        echo -e "${RED}Formatting issues found:${NC}"
        echo "$errors"
        echo ""
        echo "Run ./scripts/format.sh to fix."
        exit 1
    else
        echo -e "${GREEN}All files correctly formatted.${NC}"
    fi
else
    # Format mode - apply formatting
    find src -type f \( -name "*.cc" -o -name "*.h" \) -exec clang-format -i {} \;
    echo -e "${GREEN}Formatting complete.${NC}"
fi

echo ""
