# Art UI Fonts Validation Exercises

Last updated: 2026-02-14

## Exercises
1. Run all domain commands.
2. Record command results and blockers.
3. Re-run after fixes until pass.

## Commands
- `python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime`
- `python3 scripts/dev/patchlog_analyze.py development/RME/validation/runtime/patchlogs/*.patchlog.txt`
- `python3 scripts/test/rme-repeat-map.py BRODEAD 1 --timeout 120 --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"`

## Run Log
- Initial rerun timestamp (UTC): `2026-02-14T13:19:55Z`
- Initial rerun result: fail (`BRODEAD.MAP` timeout)
- Failure classification: harness/tooling issue
- Root cause: missing canonical working-dir caused startup data lookup failure (`master.dat` init fail)
- Remediation: enforce `RME_WORKING_DIR=GOG/patchedfiles` in sweep/repeat harness scripts
- Impacted retest timestamp (UTC): `2026-02-14T13:31:01Z`
- Impacted retest result (`BRODEAD`): pass
- Full rerun timestamp (UTC): `2026-02-14T13:31:47Z`
- Full rerun result:
- `rme-runtime-sweep.py`: pass
- `patchlog_analyze.py`: pass
- Sweep artifact summary: 72/72 maps, 0 failures

## Result
- Result: pass
- Blockers:
- None.
- Next action:
- None; domain is complete.
