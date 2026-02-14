# Directory Journal: fallout1-rebirth (Root)

Last Updated: 2026-02-14

## Purpose

Root of the Apple-only Fallout 1 Rebirth repository (macOS + iOS/iPadOS).

## Current State Snapshot

- SDL3-based engine fork with active RME patch/validation tooling.
- Canonical script layout enforced:
  - `scripts/build` (`build-*`)
  - `scripts/dev` (`dev-*`)
  - `scripts/patch` (`rebirth-*`)
  - `scripts/test` (`test-*`)
- External game-data policy is active:
  - patched: `$FALLOUT_GAMEFILES_ROOT/patchedfiles`
  - unpatched: `$FALLOUT_GAMEFILES_ROOT/unpatchedfiles`

## 2026-02-14 Updates

- Audited and updated RME patch traceability in `third_party/rme/patchvalidation.md`.
- Removed repo-local `GOG/` assumptions from active instructions and ignore rules.
- Added end-to-end final validation flow: `scripts/test/test-rme-end-to-end.sh`.
- Added full asset-domain sweep: `scripts/test/test-rme-asset-sweep.py`.
- Added compile-time logging toggle mechanism: `scripts/patch/rebirth-toggle-logging.sh`.
- Added compile option wiring for logging disable mode (`F1R_DISABLE_RME_LOGGING`) in build scripts/CMake.
- Moved `scripts/hideall.sh` to `scripts/dev/dev-toggle-dev-files.sh`.
- Updated agent instruction docs to require journal read/update discipline in directories that contain `JOURNAL.md`.

## Notes for Agents

- If a directory has `JOURNAL.md`, read it before editing files there.
- After changing files in that directory, update that directory journal in the same change set.
- Keep `README.md` and `JOURNAL.md` aligned with current file layout and script names.
