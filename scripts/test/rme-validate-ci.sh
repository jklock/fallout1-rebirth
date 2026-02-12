#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"

echo "Building (fast)"
$REPO_ROOT/scripts/build/build-macos.sh --build-only

echo "Running quick headless RME dry-run using failing fixture"
export TEST_FALLBACK_BINARY="$REPO_ROOT/scripts/test/tools/fake_fallout_runner"
$REPO_ROOT/scripts/test/test-rme-patchflow.sh --auto-fix --auto-fix-iterations 1 --skip-build "$REPO_ROOT/scripts/test/data/failing_run" || true

echo "Validation run complete; inspect artifacts under tmp/rme-run-* and development/RME/validation/"
