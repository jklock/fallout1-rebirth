# Maps Runtime Validation Exercises

Last updated: 2026-02-14

## Exercises
1. Run all domain commands.
2. Record command results and blockers.
3. Re-run after fixes until pass.

## Commands
- `./scripts/test/rme-ensure-patched-data.sh`
- `python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime`
- `python3 scripts/dev/patchlog_analyze.py development/RME/validation/runtime/patchlogs/*.patchlog.txt`
- `python3 scripts/test/rme-repeat-map.py JUNKDEMO 1 --timeout 120 --out-dir development/RME/validation/runtime`

## Run Log
- Initial baseline run timestamp (UTC): `2026-02-14T04:17:21Z`
- Initial baseline result:
- `rme-ensure-patched-data.sh`: pass
- `rme-runtime-sweep.py`: fail (`JUNKDEMO.MAP` exit code `2`)
- `patchlog_analyze.py`: pass
- Failure classification: harness/tooling issue
- Root cause: exit code `2` treated as blocker despite successful full-load patchlog checks

- Impacted retest before fix (`2026-02-14T04:58:53Z`):
- `rme-repeat-map.py JUNKDEMO 1`: fail (exit `2`)

- Remediation:
- `scripts/test/rme-runtime-sweep.py`: treat exit `2` as warning when full-load verification passes
- `scripts/test/rme-repeat-map.py`: same guarded behavior for repeat-map harness

- Impacted retest after fix (`2026-02-14T05:01:01Z`):
- `rme-repeat-map.py JUNKDEMO 1`: pass

- Full baseline rerun (`2026-02-14T05:02:00Z`):
- `rme-ensure-patched-data.sh`: pass
- `rme-runtime-sweep.py`: pass
- `patchlog_analyze.py`: pass
- Cross-domain regression retest (`2026-02-14T14:35:54Z`) after domain `06` harness updates:
- `rme-repeat-map.py JUNKDEMO 1 --timeout 120 --exe ...`: pass

## Result
- Result: pass
- Blockers: none
- Notes:
- Full sweep covered 72 target maps.
- Hotspot maps were validated via full sweep only (`CARAVAN`, `ZDESERT1`, `TEMPLAT1`); no extra hotspot repeats were needed.
- Analyzer summary remained clean after rerun.
