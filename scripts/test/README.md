# scripts/test

Last updated (UTC): 2026-02-14

All test and validation scripts live in this directory and follow `test-*` naming.

## Core Platform Tests
- `test-macos.sh`, `test-macos-headless.sh`
- `test-ios-simulator.sh`, `test-ios-headless.sh`
- `test-install-game-data.sh`, `test-shutdown-sanity.sh`

## RME Validation Tests
- `test-rme-ensure-patched-data.sh`
- `test-rme-end-to-end.sh` (full final validation run, max logging)
- `test-rme-asset-sweep.py` (maps/audio/critters/proto/scripts/text/art sweep)
- `test-rme-runtime-sweep.py`, `test-rme-repeat-map.py`
- `test-rme-audit-script-refs.py`, `test-rme-crossref.py`, `test-rme-find-lst-candidates.py`
- `test-rme-extract-map.py`, `test-rme-patchlog-analyze.py`
- `test-rme-run-validation.sh`, `test-rme-full-coverage.sh`, `test-rme-validate-ci.sh`
- `test-rme-patchflow.sh`, `test-rme-patchflow-autofix.sh`, `test-rme-working-dir.sh`
- `test-rme-autofix.py`, `test-rme-autofix-rules.py`, `test-rme-autofix-unit.py`
- `test-rme-parse-log.py`, `test-rme-parse-log-unit.py`
- `test-rme-gui-drive.sh`, `test-rme-log-sweep.sh`
- `test-verify-checksums.py`

Fixture-driven integration scripts accept override paths via env/args (for example `DATA_DIR` or `RME_FIXTURE_DIR`).

## Fixtures
- `rme-data/`: controlled fixture payloads.
- `rme-tools/`: helper binaries/scripts for integration testing.
- `tmp_wd/`: retained sample workdir snapshot used by autofix-path tests.

## Path Configuration
- Do not assume repo-local gamefiles.
- Provide data via `GAME_DATA`/flags or `FALLOUT_GAMEFILES_ROOT`.
- Output paths are configurable through script flags and env vars.
- Scratch/test roots are configurable (`RME_RUN_ROOT`, `RME_STATE_DIR`, `OUT_DIR`, `LOG_DIR`).
