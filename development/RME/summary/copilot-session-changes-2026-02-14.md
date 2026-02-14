# RME Session Changes - 2026-02-14

## Canonical data enforcement
- Added `scripts/test/rme-ensure-patched-data.sh`.
- Wired canonical `GOG/patchedfiles` usage into test/post-build flows.

## Script/path cleanup
- Kept `scripts/patch/*` patch-only and `scripts/test/*` test-only.
- Updated default RME payload path to `third_party/rme` (with legacy fallback to `third_party/rme/source`).

## Domain document split
Top-level docs are now index hubs, and tracking is split per domain.

- Plan domain docs: `development/RME/PLAN/domains/*.md`
- TODO domain docs: `development/RME/TODO/domains/*.md`
- Outcome domain docs: `development/RME/OUTCOME/domains/*.md`
- Validation domain docs: `development/RME/VALIDATE/domains/*.md`

## Domain list
- patch-integrity
- maps-runtime
- critters-proto
- scripts-dialog
- audio
- art-ui-fonts
- text-localization
- platform-macos
- platform-ios
- release-packaging
