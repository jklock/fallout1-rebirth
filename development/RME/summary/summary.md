# RME Execution Summary

## Plan Updates
- Updated plan documents in `development/RME/plan/` with concrete install paths:
  - macOS: `/Applications/Fallout 1 Rebirth.app/Contents/Resources/`
  - iOS: `Files > Fallout 1 Rebirth > Documents/`
- Confirmed patch-in-place strategy (no runtime patch directory, no save-path changes).

## Implementation Completed
- Added RME payload storage:
  - `third_party/rme/source/` (copied from `GOG/rme_1`, without .DS_Store)
  - `third_party/rme/manifest.json`
  - `third_party/rme/checksums.txt`
  - `third_party/rme/README.md`
- Added patch scripts:
  - `scripts/patch/rebirth_patch_data.sh`
  - `scripts/patch/rebirth_patch_app.sh`
  - `scripts/patch/rebirth_patch_ipa.sh`
- Standardized patch script log markers to ASCII for portability.
- Removed Windows-only executables from the RME payload (`falloutw.exe`, `TOOLS/*.exe`) and updated the manifest/checksums.
- Updated script path references across docs and scripts to match new structure:
  - `scripts/build/`, `scripts/dev/`, `scripts/test/`
- Fixed moved script working directories and root resolution.
- Updated `docs/scripts.md` and `scripts/README.md` to document new paths and RME patch scripts.
- Normalized script headers for patch/build tooling and clarified usage.
- Updated `scripts/test/test-install-game-data.sh` to remove hardcoded source paths and prompt for input (supports `GAME_DATA`).

## Todo Execution Status
- Engine todo: verified no engine changes required and documented exact install paths.
- Game data todo: third_party payload + checksums + manifest created.
- Scripts todo: patch scripts implemented and documented.

## Tests Run
- `bash -n scripts/patch/rebirth_patch_data.sh scripts/patch/rebirth_patch_app.sh scripts/patch/rebirth_patch_ipa.sh scripts/test/test-install-game-data.sh scripts/build/build-ios-ipa.sh`
- `./scripts/patch/rebirth_patch_data.sh --help`
- `./scripts/patch/rebirth_patch_app.sh --help`
- `./scripts/patch/rebirth_patch_ipa.sh --help`
- `./scripts/test/test-install-game-data.sh --help`
