# Patch Integrity Validation Exercises

Last updated: 2026-02-14

## Exercises
1. Run all domain commands.
2. Record command results and blockers.
3. Re-run after fixes until pass.

## Commands
- `./scripts/test/rme-ensure-patched-data.sh`
- `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme`
- `./scripts/patch/rebirth-refresh-validation.sh --unpatched GOG/unpatchedfiles --patched GOG/patchedfiles --rme third_party/rme --out development/RME/validation`

## Run Log
- Run timestamp (UTC): 2026-02-14T03:06:12Z
- Initial baseline result:
  - `rme-ensure-patched-data.sh`: pass
  - `rebirth-validate-data.sh`: pass
  - `rebirth-refresh-validation.sh`: fail (`scripts/patch/rme-crossref.py` missing)
- Post-fix impacted rerun:
  - `rebirth-refresh-validation.sh`: pass
- Full baseline rerun after fix:
  - `rme-ensure-patched-data.sh`: pass
  - `rebirth-validate-data.sh`: pass
  - `rebirth-refresh-validation.sh`: pass

## Result
- Result: pass
- Blockers: none
- Notes:
  - Overlay verified (`1126` files).
  - Text line endings normalized.
  - DAT patches verified.
  - Validation refresh and script reference audit outputs generated under `development/RME/validation/raw`.
