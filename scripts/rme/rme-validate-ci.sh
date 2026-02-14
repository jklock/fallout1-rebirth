#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
RME_STATE_DIR="${RME_STATE_DIR:-$REPO_ROOT/tmp/rme}"

echo "Building (fast)"
$REPO_ROOT/scripts/build/build-macos.sh --build-only

echo "Running quick headless RME dry-run using failing fixture"
export TEST_FALLBACK_BINARY="$REPO_ROOT/scripts/rme/tools/fake_fallout_runner"
$REPO_ROOT/scripts/rme/test-rme-patchflow.sh --auto-fix --auto-fix-iterations 1 --skip-build "$REPO_ROOT/scripts/rme/data/failing_run" || true

echo "Validation run complete; inspect artifacts under tmp/rme-run-* and $RME_STATE_DIR/validation/"
