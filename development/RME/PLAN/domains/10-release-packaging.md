# Release Packaging Plan

Last updated: 2026-02-14

## Objective
Validate release pipeline confidence after domain gates pass.

## Coverage Target
- Domain-specific blockers are reduced to zero.
- Domain validation commands complete cleanly.

## Primary Commands
- `./scripts/build/build-releases.sh`

## Execution Summary
- Initial baseline (`2026-02-14T06:12:59Z`) failed pre-commit formatting gate (`1 check(s) failed`).
- Root-cause class: harness/tooling issue (release gate enforcing formatter with outstanding format deltas).
- Remediation (`2026-02-14T06:14:29Z`): `./scripts/dev/dev-format.sh` completed successfully.
- Full rerun (`2026-02-14T06:14:37Z`) passed end-to-end (`EC=0`), including:
- pre-commit checks
- test/build stages (macOS + iOS)
- artifact collection
- copy to release folders
- Non-blocking warnings remained in logs (Windows-reference warning, early binary-path warning), but final pipeline status is pass.

## Status
- Domain status: complete
- Blocker-level packaging defects: none

## Evidence
- `development/RME/validation/release/10-build-releases-20260214T061259Z.log`
- `development/RME/validation/release/10-dev-format-20260214T061429Z.log`
- `development/RME/validation/release/10-build-releases-rerun-20260214T061437Z.log`
- `build-outputs/iOS/fallout1-rebirth.ipa`
- `build-outputs/macOS/Fallout 1 Rebirth.dmg`
- `releases/iOS/V1/fallout1-rebirth.ipa`
- `releases/macos/V1/Fallout 1 Rebirth.dmg`
- `releases/macos/V1/Fallout 1 Rebirth.app`
