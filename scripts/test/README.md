# scripts/test

Last updated (UTC): 2026-02-15

All test and validation scripts live in this directory and follow `test-*` naming.

## Core Platform Tests
- `test-macos.sh`, `test-macos-headless.sh`
- `test-ios-simulator.sh`, `test-ios-headless.sh`
- `test-shutdown-sanity.sh`

## Rebirth Data Validation Tests
- `test-rebirth-refresh-validation.sh`
- `test-rebirth-validate-data.sh`
- `test-rebirth-toggle-logging.sh`

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
- `test-rme-config-surface.py`
- `test-rme-config-compat.py`, `test-rme-config-compat.sh` (per-key parse/apply/runtime-effect gate for baseline config keys)
- `test-rme-config-packaging.py`, `test-rme-config-packaging.sh` (template + packaged artifact config alignment gate)
- `test-verify-checksums.py`

## RME Suite
- `rme/suite.py` is the primary user-facing RME entrypoint.
- Use `python3 scripts/test/rme/suite.py all` for the full default suite flow.

Fixture-driven integration scripts accept override paths via env/args (for example `DATA_DIR` or `RME_FIXTURE_DIR`).

## Fixtures
- `rme-fixtures/`: controlled fixture payloads.
- `rme-fixture-tools/`: helper binaries/scripts for integration testing.
- `rme-sample-workdir/`: retained sample workdir snapshot used by autofix-path tests.

## Path Configuration
- Do not assume repo-local gamefiles.
- Provide data via `GAME_DATA`/flags or `FALLOUT_GAMEFILES_ROOT`.
- Output paths are configurable through script flags and env vars.
- Scratch/test roots are configurable (`RME_RUN_ROOT`, `RME_STATE_DIR`, `OUT_DIR`, `LOG_DIR`).

## Build Policy
- Test scripts in `scripts/test/` validate existing artifacts only.
- Build required artifacts with `scripts/build/*.sh` before running tests.
