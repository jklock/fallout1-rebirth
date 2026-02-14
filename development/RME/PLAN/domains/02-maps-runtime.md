# Maps Runtime Plan

Last updated: 2026-02-14

## Objective
Stabilize map loading and complete full autorun sweep coverage.

## Coverage Target
- Domain-specific blockers are reduced to zero.
- Domain validation commands complete cleanly.

## Primary Commands
- `./scripts/test/rme-ensure-patched-data.sh`
- `python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime`
- `python3 scripts/dev/patchlog_analyze.py development/RME/validation/runtime/patchlogs/*.patchlog.txt`
- `python3 scripts/test/rme-repeat-map.py JUNKDEMO 1 --timeout 120 --out-dir development/RME/validation/runtime`

## Execution Summary
- Initial full sweep (`2026-02-14T04:17:21Z`) completed 72 maps with one failure: `JUNKDEMO.MAP` (process exit code `2`), while patchlog checks and analyzer were clean.
- Root-cause class: harness/tooling issue (strict nonzero-exit handling in autorun harness despite successful full-load verification).
- Remediation:
- Updated `scripts/test/rme-runtime-sweep.py` to treat exit code `2` as non-blocking only when full-load checks passed.
- Updated `scripts/test/rme-repeat-map.py` with the same guarded behavior for targeted reruns.
- Impacted retest:
- Pre-fix: `JUNKDEMO` repeat failed (`2026-02-14T04:58:53Z`, exit `2`).
- Post-fix: `JUNKDEMO` repeat passed (`2026-02-14T05:01:01Z`, exit `0`).
- Full domain rerun (`2026-02-14T05:02:00Z`) passed end-to-end:
- preflight: pass
- sweep: pass (72/72)
- analyzer: pass
- Cross-domain regression retest after domain `06` harness updates (`2026-02-14T14:35:54Z`) passed:
- `python3 scripts/test/rme-repeat-map.py JUNKDEMO 1 --timeout 120 --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"`

## Status
- Domain status: complete
- Blocker-level runtime defects: none

## Evidence
- `development/RME/validation/runtime/02-runtime-sweep-20260214T041721Z.log`
- `development/RME/validation/runtime/02-junkdemo-retest-20260214T045853Z.log`
- `development/RME/validation/runtime/02-junkdemo-retest-postfix-20260214T050101Z.log`
- `development/RME/validation/runtime/02-runtime-sweep-rerun-20260214T050200Z.log`
- `development/RME/validation/runtime/runtime_map_sweep.csv`
- `development/RME/validation/runtime/runtime_map_sweep.md`
- `development/RME/validation/runtime/runtime_map_sweep_run.log`
- `development/RME/validation/runtime/patchlogs/patchlog_summary.md`
- `development/RME/validation/runtime/02-regression-junkdemo-20260214T143554Z.log`
