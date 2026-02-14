# Platform macOS Plan

Last updated: 2026-02-14

## Objective
Pass macOS platform validation with canonical data installation and no-crash startup checks.

## Coverage Target
- Domain-specific blockers are reduced to zero.
- Domain validation commands complete cleanly.

## Primary Commands
- `./scripts/test/rme-ensure-patched-data.sh --target-app "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"`
- `./scripts/test/test-macos-headless.sh`
- `./scripts/test/test-macos.sh`

## Execution Summary
- Baseline run (`2026-02-14T06:06:31Z`) passed.
- Confirmation rerun (`2026-02-14T14:32:18Z`) passed.
- Preflight confirmed canonical patched data is installed in app resources.
- Headless gate passed including brief launch no-crash check.
- macOS app bundle gate passed dependency/signature/execution checks.
- Under the active acceptance criteria, these automated startup/load checks are sufficient for domain completion.

## Status
- Domain status: complete
- Blocker-level defects: none

## Evidence
- `development/RME/validation/macos/08-preflight-20260214T143218Z.log`
- `development/RME/validation/macos/08-test-macos-headless-20260214T143218Z.log`
- `development/RME/validation/macos/08-test-macos-20260214T143218Z.log`
- `development/RME/validation/macos/08-preflight-20260214T060631Z.log`
- `development/RME/validation/macos/08-test-macos-headless-20260214T060631Z.log`
- `development/RME/validation/macos/08-test-macos-20260214T060631Z.log`
