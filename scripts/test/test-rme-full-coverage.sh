#!/usr/bin/env bash
# Backward-compatible alias for the final full-domain end-to-end validator.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT/scripts/test/test-rme-end-to-end.sh" "$@"
