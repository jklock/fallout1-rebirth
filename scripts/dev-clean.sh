#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - Clean Build Artifacts
# =============================================================================
# Removes all CMake build directories and generated files.
#
# USAGE:
#   ./scripts/clean.sh           # Remove all build directories
#   VERBOSE=1 ./scripts/clean.sh # Show detailed output
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=== Cleaning Build Artifacts ==="
echo ""

DIRS=(
    "build"
    "build-macos"
    "build-ios"
    "build-ios-sim"
    "build-macos-signed"
    "_deps"
)

removed=0
for dir in "${DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo -e "${YELLOW}Removing${NC} $dir/"
        rm -rf "$dir"
        ((removed++))
    fi
done

if [[ $removed -eq 0 ]]; then
    echo "No build directories found."
else
    echo ""
    echo -e "${GREEN}Removed $removed directory(s).${NC}"
fi

echo ""
