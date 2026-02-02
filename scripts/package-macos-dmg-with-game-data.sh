#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "ℹ️  This script is deprecated. Use ./scripts/build-macos-dmg.sh --bundle instead."
"$ROOT_DIR/scripts/build-macos-dmg.sh" --bundle
