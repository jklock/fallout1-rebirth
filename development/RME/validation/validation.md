# RME Execution Validation

## Validation Scope
Confirm tasks in the plan/todo documents are implemented and verify the current patch pipeline produces a macOS-ready bundle with normalized text files.

## Plan References
- `development/RME/plan/engineplan.md`
- `development/RME/plan/gameplan.md`
- `development/RME/plan/RISKS.md`

## Todo References
- `development/RME/todo/engine_todo.md`
- `development/RME/todo/game_data_todo.md`
- `development/RME/todo/scripts_todo.md`

## Checks Performed (Current)
1. **Cross-reference mapping generated**:
   - `development/RME/summary/rme-crossref.csv`
   - `development/RME/summary/rme-crossref.md`
   - `development/RME/summary/rme-lst-report.md`
2. **CRLF normalization added**:
   - `scripts/patch/rebirth-patch-data.sh` normalizes `.lst/.msg/.txt` to LF.
3. **Validation updated for text files**:
   - `scripts/patch/rebirth-validate-data.sh` normalizes text hashes and asserts no CRLF remains.
4. **Patch pipeline exercised**:
   - Patched output produced at `GOG/patchedfiles`.
5. **macOS build and app install tested**:
   - Build succeeded.
   - Patched data installed into `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`.

## Tests Run
- `./scripts/patch/rebirth-patch-data.sh --base GOG/unpatchedfiles --out GOG/patchedfiles --config-dir gameconfig/macos --rme third_party/rme/source --force`
- `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme/source`
- `./scripts/build/build-macos.sh`
- `./scripts/test/test-install-game-data.sh --source GOG/patchedfiles --target "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"`
- `./scripts/test/test-macos-headless.sh`
- `./scripts/test/test-macos.sh --verify`
- `F1R_PATCHLOG=1 F1R_PATCHLOG_VERBOSE=1 F1R_PATCHLOG_PATH=/tmp/f1r-patchlog.txt .../Contents/MacOS/fallout1-rebirth`

## Results
Data-level validation and macOS bundle tests pass. Headless and verify tests pass. In-game visual verification remains pending (headed run).

## Outstanding Validation (Planned)
1. **In-game visual confirmation** (map/world render).
2. **Patch logging diagnostics** (only if visual issues persist):
   - Enable `F1R_PATCHLOG=1` for a run.
   - Review `patchlog.txt` for missing assets or failed opens.
