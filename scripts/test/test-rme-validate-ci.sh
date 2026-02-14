#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
RME_STATE_DIR="${RME_STATE_DIR:-$REPO_ROOT/tmp/rme}"
RME_RUN_ROOT="${RME_RUN_ROOT:-$REPO_ROOT/tmp}"
RME_FIXTURE_DIR="${RME_FIXTURE_DIR:-$REPO_ROOT/scripts/test/rme-data/failing_run}"

if [[ $# -gt 0 ]]; then
    RME_FIXTURE_DIR="$1"
fi

echo "Building (fast)"
$REPO_ROOT/scripts/build/build-macos.sh --build-only

echo "Running quick headless RME dry-run using failing fixture"
export TEST_FALLBACK_BINARY="$REPO_ROOT/scripts/test/rme-tools/fake_fallout_runner"
$REPO_ROOT/scripts/test/test-rme-patchflow.sh --auto-fix --auto-fix-iterations 1 --skip-build "$RME_FIXTURE_DIR" || true

echo "Validation run complete; inspect artifacts under $RME_RUN_ROOT/rme-run-* and $RME_STATE_DIR/validation/"
