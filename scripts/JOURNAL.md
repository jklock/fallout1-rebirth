# JOURNAL: scripts

Last updated (UTC): 2026-02-14

## 2026-02-14
- Consolidated RME validation tooling under `scripts/test`.
- Enforced `test-*` naming for test scripts.
- Added per-directory `README.md` and `JOURNAL.md` files in scripts subdirectories.
- Removed script-level assumptions about repo-local `GOG/` paths.
- Added external game-data path support through `GAME_DATA` and `FALLOUT_GAMEFILES_ROOT`.
- Added `scripts/test/test-rme-end-to-end.sh` for one-shot full-domain validation with max logging.
- Added `scripts/test/test-rme-asset-sweep.py` for full asset-domain readability audits.
- Added `scripts/patch/rebirth-toggle-logging.sh` and `.f1r-build.env` build-hook support for compile-time logging disable/enable.
- Moved root `scripts/hideall.sh` to `scripts/dev/dev-toggle-dev-files.sh`.
- Added baseline docs to remaining nested fixture/support directories so every `scripts/*` directory now has `README.md` and `JOURNAL.md`.
- Consolidated build flows into single-mode scripts:
  - `scripts/build/build-ios.sh` now handles `-test` / `-prod` and device/simulator targets.
  - `scripts/build/build-macos.sh` now handles `-test` / `-prod`.
- Removed separate packaging/release wrappers (`build-ios-ipa.sh`, `build-ios-simulator.sh`, `build-macos-dmg.sh`, `build-releases.sh`).
- Moved dev ignore toggle back to `scripts/hideall.sh`.
- Renamed patch scripts to `patch-rebirth-*`.
- Reclassified Rebirth validation scripts as tests under `scripts/test/test-rebirth-*`.
- Added Python master runner `scripts/test/rme/suite.py` for end-user RME workflows.
- Renamed RME fixture/support directories for clarity:
  - `rme-data` -> `rme-fixtures`
  - `rme-tools` -> `rme-fixture-tools`
  - `tmp_wd` -> `rme-sample-workdir`
