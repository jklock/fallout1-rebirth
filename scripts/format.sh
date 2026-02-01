#!/usr/bin/env bash
# Format all C++ source files
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== Formatting C++ Source Files ==="

if ! command -v clang-format &> /dev/null; then
    echo "❌ clang-format not found"
    echo "   Install with: brew install clang-format"
    exit 1
fi

find src -type f \( -name "*.cc" -o -name "*.h" \) -exec clang-format -i {} \;

echo "✅ Formatting complete"
