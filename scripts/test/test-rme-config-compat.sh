#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXE="${EXE:-$ROOT_DIR/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/tmp/rme/config-compat}"
MATRIX_TSV="${MATRIX_TSV:-$OUT_DIR/coverage-matrix.tsv}"
MATRIX_MD="${MATRIX_MD:-$ROOT_DIR/docs/audit/config-key-coverage-matrix-2026-02-15.md}"

args=(
  --exe "$EXE"
  --out-dir "$OUT_DIR"
  --matrix-tsv "$MATRIX_TSV"
  --matrix-md "$MATRIX_MD"
)

if [[ -n "${BASELINE_FALLOUT:-}" ]]; then
  args+=(--baseline-fallout "$BASELINE_FALLOUT")
fi
if [[ -n "${BASELINE_F1:-}" ]]; then
  args+=(--baseline-f1 "$BASELINE_F1")
fi
if [[ -n "${GAMEFILES_ROOT:-}" ]]; then
  args+=(--gamefiles-root "$GAMEFILES_ROOT")
fi
if [[ -n "${FALLOUT_GAMEFILES_ROOT:-}" && -z "${GAMEFILES_ROOT:-}" ]]; then
  args+=(--gamefiles-root "$FALLOUT_GAMEFILES_ROOT")
fi

python3 "$ROOT_DIR/scripts/test/test-rme-config-compat.py" "${args[@]}"
