# Critters And Proto Validation Exercises

Last updated: 2026-02-14

## Exercises
1. Run all domain commands.
2. Record command results and blockers.
3. Re-run after fixes until pass.

## Commands
- `./scripts/test/rme-ensure-patched-data.sh`
- `python3 scripts/test/rme-audit-script-refs.py --patched-dir GOG/patchedfiles --out-dir development/RME/validation/raw`

## Run Log
- Run timestamp (UTC): `2026-02-14T05:53:57Z`
- Command results:
- `rme-ensure-patched-data.sh`: pass
- `rme-audit-script-refs.py`: pass
- Audit summary:
- missing expected `.int` files: `0`
- missing `.int` files with proto/map reference signal: `0`

## Result
- Result: pass
- Blockers: none
- Next action: proceed to domain `04-scripts-dialog`
