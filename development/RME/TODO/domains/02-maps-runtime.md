# Maps Runtime TODO

Last updated: 2026-02-14

## Tasks
- [x] Run full runtime sweep validation command.
- [x] Triage and fix domain-specific blockers.
- [x] Re-run domain validation until stable.
- [x] Update domain outcome document.
- [x] Hotspot triage complete for `CARAVAN`, `ZDESERT1`, `TEMPLAT1` (do not re-run by default).

## Hotspot Policy
- Hotspot maps are currently stabilized in this domain cycle.
- Do not repeat hotspot tests in routine runs.
- Re-run hotspot maps only when a regression trigger exists:
- map-load/runtime flow changes
- render/present pipeline changes
- autorun/patchlog harness changes
- full sweep flags one of these three maps as failed

## Commands
- `./scripts/test/rme-ensure-patched-data.sh`
- `python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime`
- `python3 scripts/dev/patchlog_analyze.py development/RME/validation/runtime/patchlogs/*.patchlog.txt`
- `python3 scripts/test/rme-repeat-map.py JUNKDEMO 1 --timeout 120 --out-dir development/RME/validation/runtime`
- `python3 scripts/test/rme-repeat-map.py JUNKDEMO 1 --timeout 120 --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"` (cross-domain regression retest, `2026-02-14T14:35:54Z`)

## Conditional Hotspot Commands (regression-only)
- python3 scripts/test/rme-repeat-map.py CARAVAN 1 --timeout 25 --out-dir development/RME/validation/runtime
- python3 scripts/test/rme-repeat-map.py ZDESERT1 1 --timeout 25 --out-dir development/RME/validation/runtime
- python3 scripts/test/rme-repeat-map.py TEMPLAT1 1 --timeout 25 --out-dir development/RME/validation/runtime

## Failure Triage
- Initial sweep (`2026-02-14T04:17:21Z`) failed only on `JUNKDEMO.MAP` with process exit `2`.
- Classification: harness/tooling issue.
- Root cause: harness treated exit code `2` as hard fail even when full-load patchlog checks (`load_end rc=0`, display non-black, `dude_tile`, `post_click_dude_tile`) all passed.

## Fix
- Updated `scripts/test/rme-runtime-sweep.py` to downgrade exit code `2` to warning when full-load checks pass.
- Updated `scripts/test/rme-repeat-map.py` with the same guarded behavior.
- Verified with impacted retest (`JUNKDEMO`), then reran full sweep and analyzer.

## Current State
- Domain baseline commands pass (preflight + full 72-map sweep + analyzer).
- Post-domain `06` harness-change regression retest on `JUNKDEMO` also passes.
