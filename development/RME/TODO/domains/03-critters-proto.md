# Critters And Proto TODO

Last updated: 2026-02-14

## Tasks
- [x] Run domain validation commands.
- [x] Triage and fix domain-specific blockers.
- [x] Re-run domain validation until stable.
- [x] Update domain outcome document.

## Commands
- `./scripts/test/rme-ensure-patched-data.sh`
- `python3 scripts/test/rme-audit-script-refs.py --patched-dir GOG/patchedfiles --out-dir development/RME/validation/raw`

## Failure Triage
- No command failures in this domain run.
- Audit reported:
- missing expected `.int` files: `0`
- missing `.int` files with reference signal (proto/map): `0`

## Fix
- No code fix required.

## Current State
- Domain baseline commands pass.
