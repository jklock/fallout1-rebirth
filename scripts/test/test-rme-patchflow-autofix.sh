#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
GOG_DIR="$REPO_ROOT/scripts/test/data/failing_run"

# 1) Dry-run: expect proposed.diff exists
echo "== Dry-run auto-fix (no apply) =="
export TEST_FALLBACK_BINARY="$REPO_ROOT/scripts/test/tools/fake_fallout_runner"
if "$REPO_ROOT/scripts/test/test-rme-patchflow.sh" --auto-fix --auto-fix-iterations 1 --skip-build "$GOG_DIR"; then
    echo "Expected failure but run succeeded (dry-run)" >&2
    exit 2
fi

# Look for latest tmp/rme-run-* directory created under repo tmp
RUNDIR=$(ls -td "$REPO_ROOT/tmp/rme-run-"* 2>/dev/null | head -n1 || true)
if [ -z "$RUNDIR" ]; then
    echo "Could not find run dir" >&2
    exit 2
fi

if [ ! -f "$RUNDIR/work/fixes/iter-1/proposed.diff" ]; then
    echo "Dry-run: proposed.diff not found at $RUNDIR/work/fixes/iter-1/proposed.diff" >&2
    ls -la "$RUNDIR/work/fixes" || true
    exit 2
fi

echo "Dry-run: proposed.diff present as expected"

# 2) Apply mode: expect final run to pass after autofix applied
echo "== Apply auto-fix (apply mode) =="
if ! "$REPO_ROOT/scripts/test/test-rme-patchflow.sh" --auto-fix --auto-fix-iterations 2 --auto-fix-apply --skip-build "$GOG_DIR"; then
    echo "Auto-fix apply run failed" >&2
    # Locate last run dir and show artifacts
    LDIR=$(ls -td "$REPO_ROOT/tmp/rme-run-"* 2>/dev/null | head -n1 || true)
    echo "Last run dir: $LDIR"
    ls -la "$LDIR/artifacts" || true
    exit 2
fi

# Verify that the last run produced passing summary
LDIR=$(ls -td "$REPO_ROOT/tmp/rme-run-"* 2>/dev/null | head -n1 || true)
if [ -f "$LDIR/rme-run-summary.json" ]; then
    if jq -e '.pass == true' "$LDIR/rme-run-summary.json" > /dev/null 2>&1; then
        echo "Apply mode: run passed after autofix"
    else
        echo "Apply mode: run did not pass; inspect $LDIR" >&2
        exit 2
    fi
else
    echo "Apply mode: missing rme-run-summary.json in $LDIR" >&2
    exit 2
fi

echo "Integration test test-rme-patchflow-autofix: OK"
