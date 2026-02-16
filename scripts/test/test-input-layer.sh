#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"

cmake -B "$BUILD_DIR" \
    -G Xcode \
    -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''

cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --target input_layer_tests

TEST_BIN="$BUILD_DIR/$BUILD_TYPE/input_layer_tests"
if [[ ! -x "$TEST_BIN" ]]; then
    echo "FAIL: input layer test binary missing: $TEST_BIN" >&2
    exit 1
fi

"$TEST_BIN"
