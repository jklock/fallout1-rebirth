# Platform macOS Validation Exercises

Last updated: 2026-02-14

## Exercises
1. Run all domain commands.
2. Record command results and blockers.
3. Re-run after fixes until pass.

## Commands
- `./scripts/test/rme-ensure-patched-data.sh --target-app "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"`
- `./scripts/test/test-macos-headless.sh`
- `./scripts/test/test-macos.sh`

## Run Log
- Baseline run timestamp (UTC): `2026-02-14T06:06:31Z`
- Baseline result: pass
- Confirmation run timestamp (UTC): `2026-02-14T14:32:18Z`
- Confirmation results:
- preflight canonical data check: pass
- `test-macos-headless.sh`: pass
- `test-macos.sh`: pass
- Brief-launch no-crash check (headless): pass

## Result
- Result: pass
- Blockers:
- None.
- Next action:
- None; domain is complete.
