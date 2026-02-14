# Release Packaging Validation Exercises

Last updated: 2026-02-14

## Exercises
1. Run all domain commands.
2. Record command results and blockers.
3. Re-run after fixes until pass.

## Commands
- `./scripts/build/build-releases.sh`
- `./scripts/dev/dev-format.sh` (remediation)

## Run Log
- Initial baseline timestamp (UTC): `2026-02-14T06:12:59Z`
- Initial baseline result: fail (pre-commit formatting gate)
- Remediation timestamp (UTC): `2026-02-14T06:14:29Z`
- Remediation command result: pass
- Full rerun timestamp (UTC): `2026-02-14T06:14:37Z`
- Full rerun result: pass (`EC=0`)
- Artifact checks:
- iOS IPA found: `build-outputs/iOS/fallout1-rebirth.ipa`
- macOS DMG found: `build-outputs/macOS/Fallout 1 Rebirth.dmg`
- release copy found:
- `releases/iOS/V1/fallout1-rebirth.ipa`
- `releases/macos/V1/Fallout 1 Rebirth.dmg`
- `releases/macos/V1/Fallout 1 Rebirth.app`

## Result
- Result: pass
- Blockers:
- None.
- Next action:
- None; domain is complete.
