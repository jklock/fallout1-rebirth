# Directory Journal: fallout1-rebirth (Root)

Last Updated: 2026-02-15

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
- Development ignore toggle helper is provided at `scripts/hideall.sh`.
- Updated agent instruction docs to require journal read/update discipline in directories that contain `JOURNAL.md`.

## 2026-02-15 Updates

- Completed baseline config compatibility for unpatched key manifests:
  - `fallout.cfg` `55/55 PASS`
  - `f1_res.ini` `6/6 PASS`
  - Combined: `61/61 PASS`
- Added per-key runtime-effect gate:
  - `scripts/test/test-rme-config-compat.py`
  - `scripts/test/test-rme-config-compat.sh`
- Added template/package alignment gate:
  - `scripts/test/test-rme-config-packaging.py`
  - `scripts/test/test-rme-config-packaging.sh`
- Updated unattended runner evidence to full green:
  - `dev/state/latest-summary.tsv`
  - `dev/state/history.tsv` latest `PASS` row: `2026-02-15T16:03:04Z`
- Produced fresh release artifacts and verified packaging alignment:
  - `releases/prod/macOS/Fallout 1 Rebirth.app`
  - `releases/prod/iOS/fallout1-rebirth.ipa`
- Updated docs/audit evidence set with new coverage, packaging, and proof snapshots.

## Notes for Agents

- If a directory has `JOURNAL.md`, read it before editing files there.
- After changing files in that directory, update that directory journal in the same change set.
- Keep `README.md` and `JOURNAL.md` aligned with current file layout and script names.
