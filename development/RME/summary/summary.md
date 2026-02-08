# RME Execution Summary

## Current Status (2026-02-08)
Patch pipeline is implemented and verified at the data/script level. A cross-reference mapping has been generated and line-ending normalization has been added to avoid macOS proto lookup failures. Headless and verify tests pass on the macOS build. In-game visual verification remains pending on your machine after re-installing patched data.

## Fixes Applied (Tracked in Repo)
1. **CRLF normalization for `.lst/.msg/.txt`** (patch step):
   - Reason: `proto_list_str` strips `\n` but not `\r`, causing proto filenames to include `\r` on macOS and break map/object loads (black world).
   - Change: `scripts/patch/rebirth-patch-data.sh` now replaces CRLF with LF after overlay.
2. **Validation hardened for text files**:
   - Change: `scripts/patch/rebirth-validate-data.sh` hashes text files with normalized line endings and asserts no CRLF remains.
3. **Full RME mapping generation**:
   - New script: `scripts/patch/rme-crossref.py`
   - Outputs:
     - `development/RME/summary/rme-crossref.csv`
     - `development/RME/summary/rme-crossref.md`
     - `development/RME/summary/rme-lst-report.md`
   - Purpose: show overrides vs new files, and LST-reference heuristics.

4. **Patch logging + boot-path diagnostics**:
   - Added `src/plib/db/patchlog.{h,cc}` and instrumentation in `db_fopen` + `db_init`.
   - Added boot path logging in `src/plib/gnw/winmain.cc` to show base/working directory.
   - Added fallback base-path resolution using `argv[0]` if SDL base path is outside the app bundle.
5. **Config copy in test installer**:
   - `scripts/test/test-install-game-data.sh` now copies `fallout.cfg` and `f1_res.ini` when present.

## What Was Done (End-to-End Execution)
- Patched data output created in `GOG/patchedfiles` using:
  - `./scripts/patch/rebirth-patch-data.sh --base GOG/unpatchedfiles --out GOG/patchedfiles --config-dir gameconfig/macos --rme third_party/rme/source --force`
- Validation run:
  - `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme/source`
- macOS build:
  - `./scripts/build/build-macos.sh`
- Installed patched data into app bundle:
  - `./scripts/test/test-install-game-data.sh --source GOG/patchedfiles --target "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"`
- Tests:
  - `./scripts/test/test-macos-headless.sh` (pass)
  - `./scripts/test/test-macos.sh --verify` (pass)
  - Runtime diagnostics with `F1R_PATCHLOG=1` (log written to `/tmp/f1r-patchlog.txt`)

## Open Work (Remaining)
1. **In-game visual verification** (headed run on your machine):
   - Install patched data into `/Applications/Fallout 1 Rebirth.app`.
   - Launch and confirm world renders correctly (no black map).
2. **Crossref triage**:
   - Review `development/RME/summary/rme-lst-report.md` for missing references.
   - Confirm missing assets are expected or add them to the pipeline if required.

## Notes on Patch Coverage
We currently apply:
- `xdelta` patches for DATs
- RME `DATA` overlay
- Case normalization + CRLF normalization

## Patch Logging (Runtime Diagnostics)
Patch logging can be enabled for runs where missing assets or black screens appear.
- Enable: `F1R_PATCHLOG=1`
- Verbose (log successful opens): `F1R_PATCHLOG_VERBOSE=1`
- Log path override: `F1R_PATCHLOG_PATH=/absolute/path/to/patchlog.txt`
Categories:
- `DB_CONTEXT` (patch/data paths)
- `DB_OPEN_OK` (successful file opens)
- `DB_OPEN_MISS` (patch folder miss in verbose mode)
- `DB_OPEN_FAIL` (missing file, seek failure, etc.)
- `DB_INIT` / `DB_INIT_FAIL` (database init success/failure)
- `BOOT_PATH` (base path + selected working directory)
Removal:
- Delete `src/plib/db/patchlog.cc` and `src/plib/db/patchlog.h`
- Remove the include + calls in `src/plib/db/db.cc`
- Remove the two entries from `CMakeLists.txt`
