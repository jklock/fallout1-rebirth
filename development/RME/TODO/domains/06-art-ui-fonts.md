# Art UI Fonts TODO

Last updated: 2026-02-14

## Tasks
- [x] Run domain validation commands.
- [x] Triage and classify failures.
- [x] Apply remediation and rerun smallest impacted command.
- [x] Rerun full domain command set after fix.
- [x] Update domain outcome document.

## Commands
- `python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime`
- `python3 scripts/dev/patchlog_analyze.py development/RME/validation/runtime/patchlogs/*.patchlog.txt`
- `python3 scripts/test/rme-repeat-map.py BRODEAD 1 --timeout 120 --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"`

## Failure Triage
- Initial sweep rerun timed out on `BRODEAD.MAP`.
- Patchlog triage indicated data-path startup failure (`DB_INIT_FAIL` for `master.dat`).
- Classification: harness/tooling issue.

## Fix
- Updated `scripts/test/rme-repeat-map.py` and `scripts/test/rme-runtime-sweep.py` to force canonical `RME_WORKING_DIR` and validate `GOG/patchedfiles` availability.
- Re-ran impacted `BRODEAD` repeat first, then full sweep and analyzer.

## Current State
- Domain complete.
- Runtime sweep and analyzer are green with canonical data-path enforcement.
