#!/usr/bin/env bash
# Clean all build artifacts
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Cleaning Build Artifacts ==="

DIRS=(
    "build"
    "build-macos"
    "build-ios"
    "build-macos-signed"
    "_deps"
)

for dir in "${DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "Removing $dir/"
        rm -rf "$dir"
    fi
done

echo "✅ Clean complete"
