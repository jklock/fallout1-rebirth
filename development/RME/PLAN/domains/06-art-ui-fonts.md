# Art UI Fonts Plan

Last updated: 2026-02-14

## Objective
Validate render/UI/font assets load cleanly across runtime map coverage without crash.

## Coverage Target
- Domain-specific blockers are reduced to zero.
- Domain validation commands complete cleanly.

## Primary Commands
- `python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime`
- `python3 scripts/dev/patchlog_analyze.py development/RME/validation/runtime/patchlogs/*.patchlog.txt`

## Execution Summary
- Initial sweep rerun (`2026-02-14T13:19:55Z`) timed out on `BRODEAD.MAP`.
- Root-cause class: harness/tooling issue.
- Triage evidence showed startup/data-path failure (`DB_INIT_FAIL` for `master.dat`) when `RME_WORKING_DIR` was not pinned.
- Remediation:
- `scripts/test/rme-repeat-map.py` now sets canonical `RME_WORKING_DIR` to `GOG/patchedfiles` and validates source existence.
- `scripts/test/rme-runtime-sweep.py` now does the same.
- Impacted retest (`BRODEAD`, `2026-02-14T13:31:01Z`) passed.
- Full rerun (`2026-02-14T13:31:47Z`) passed and analyzer rerun passed.
- Current sweep artifact reports 72/72 maps with no analyzer failures.

## Status
- Domain status: complete
- Blocker-level defects: none

## Evidence
- `development/RME/validation/art-ui-fonts/06-runtime-sweep-20260214T131955Z.log`
- `development/RME/validation/art-ui-fonts/06-repeat-brodead-postfix2-20260214T133101Z.log`
- `development/RME/validation/art-ui-fonts/06-runtime-sweep-rerun-20260214T133147Z.log`
- `development/RME/validation/art-ui-fonts/06-patchlog-analyze-rerun-20260214T133147Z.log`
- `development/RME/validation/runtime/runtime_map_sweep.csv`
- `development/RME/validation/runtime/runtime_map_sweep.md`
- `development/RME/validation/runtime/runtime_map_sweep_run.log`
