# RME Full Coverage Runbook

This is the exhaustive handoff for the full-coverage test runner script:

- Script: `scripts/patch/rme-full-coverage.sh`
- Purpose: end-to-end coverage for patched Fallout 1 data (RME) including static evidence regeneration, data integrity validation, script/LST reference integrity, and runtime map sweep with screenshots.

---

## 1) What This Script Does (End-to-End)

### Step 1 — Build macOS app
- Command: `./scripts/build/build-macos.sh`
- Why: compiles the runtime hooks used by validation (autorun maps, patch logging, diagnostics).
- Output: `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`

### Step 2 — (Optional) Rebuild patched data
- Trigger: `REBUILD_PATCHED=1` or missing `GOG/patchedfiles`.
- Command: `./scripts/patch/rebirth-patch-data.sh --base <unpatched> --out <patched> --config-dir gameconfig/macos --rme <rme>`
- Why: regenerates patched data to match current patch logic.

### Step 3 — Refresh validation evidence
- Command: `./scripts/patch/rebirth-refresh-validation.sh --unpatched <unpatched> --patched <patched> --rme <rme> --out <out>`
- Outputs (examples):
  - `development/RME/validation/unpatched_vs_patched.diff`
  - `development/RME/validation/raw/08_lst_missing.md`
  - `development/RME/validation/raw/*` (diffs, checksums, crossref CSVs)
- Why: keeps canonical validation artifacts current.

### Step 4 — Audit scripts referenced by MAP/PRO
- Command: `python3 scripts/patch/rme-audit-script-refs.py --patched-dir <patched> --out-dir <out/raw>`
- Outputs:
  - `development/RME/validation/raw/12_script_refs.md`
  - `development/RME/validation/raw/12_script_refs.csv`
- Why: ensures scripts referenced by maps/protos actually exist in DATs or overlay.

### Step 5 — Validate patched data overlay
- Command: `./scripts/patch/rebirth-validate-data.sh --patched <patched> --base <unpatched> --rme <rme>`
- Why: verifies RME payload completeness and DAT xdelta correctness.
- Failure here typically indicates missing files or bad DAT deltas.

### Step 6 — Install patched data into app bundle
- Command: `./scripts/test/test-install-game-data.sh --source <patched> --target <app bundle>`
- Why: preps runtime validation to use patched data.

### Step 7 — Headless macOS smoke test
- Command: `./scripts/test/test-macos-headless.sh`
- Why: quick launch/exit test to detect immediate runtime failures.

### Step 8 — Runtime map sweep
- Command: `python3 scripts/patch/rme-runtime-sweep.py --exe <app exe> --out-dir <runtime out> --timeout 60`
- Outputs:
  - `development/RME/validation/runtime/runtime_map_sweep.csv`
  - `development/RME/validation/runtime/runtime_map_sweep.md`
  - `development/RME/validation/runtime/runtime_map_sweep_run.log`
  - Screenshots for failures/suspicious cases: `development/RME/validation/runtime/screenshots/*.bmp`
- Why: loads every map and captures a screenshot to detect missing assets or black-map regressions.

### Step 9 — Patchlog analysis
- Command: `python3 scripts/dev/patchlog_analyze.py <patchlog.txt>`
- Why: Scans patchlogs for `GNW_SHOW_RECT` events where `surf_pre>0 && surf_post==0`, correlates with `WIN_FILL_RECT` and `MAP_SCROLL_MEMMOVE`, and prints context for nearest prior source & fill operations. Use `F1R_PATCHLOG=1` and `F1R_PATCHLOG_VERBOSE=1` during autorun to capture the required logs.

### Optional Steps — iOS
- If `RUN_IPA_PATCH=1`: `./scripts/patch/rebirth-patch-ipa.sh` (IPA payload patch)
- If `RUN_IOS=1`:
  - `./scripts/test/test-ios-headless.sh`
  - `./scripts/test/test-ios-simulator.sh`

---

## 2) Script Inputs and Configuration

### Default paths (can override via env vars)
- `BASE_DIR` = `GOG/unpatchedfiles`
- `PATCHED_DIR` = `GOG/patchedfiles`
- `RME_DIR` = `third_party/rme/source`
- `CONFIG_DIR` = `gameconfig/macos`
- `OUT_DIR` = `development/RME/validation`
- `RUNTIME_OUT` = `development/RME/validation/runtime`
- `APP` = `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`
- `EXE` = `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth`
- `TIMEOUT` = `60` seconds

### Control flags
- `REBUILD_PATCHED=1`: rebuild patched data even if `GOG/patchedfiles` exists.
- `FORCE_PATCH=1`: allow rebuild to overwrite output folder.
- `SKIP_CHECKSUMS=1`: skip base DAT checks in patching step.
- `RUN_IOS=1`: run iOS tests (headless + simulator).
- `RUN_IPA_PATCH=1`: patch IPA payload.

### Example usage
```bash
# Run full pipeline with defaults
scripts/patch/rme-full-coverage.sh

# Force rebuild patched data and increase timeout
REBUILD_PATCHED=1 FORCE_PATCH=1 TIMEOUT=90 scripts/patch/rme-full-coverage.sh

# Use custom data dirs
BASE_DIR=/path/to/base PATCHED_DIR=/path/to/patched scripts/patch/rme-full-coverage.sh
```

---

## 3) Runtime Sweep Details

The map sweep uses runtime hooks added to the engine:
- `F1R_AUTORUN_MAP`: loads a single map and exits.
- `F1R_AUTOSCREENSHOT=1`: captures a `dump_screen()` BMP after load.
- Map scripts are skipped during autorun to avoid long-running or interactive logic.

### Outputs
- `runtime_map_sweep.csv`: per-map exit code, duration, and screenshot brightness metrics.
- `runtime_map_sweep.md`: summary with counts of failures/suspicious screenshots.
- `runtime_map_sweep_run.log`: raw stdout/SDL logs for each map.
- `screenshots/`: only failing/suspicious maps.

### “Suspicious” screenshot heuristic
- Top-of-screen largely black while UI bottom is brighter (proxy for black-world bug).
- If it flags a map, inspect the BMP and cross-check map data + patchlog output.

---

## 4) Error Handling & What To Do

### A) Build fails
- Symptom: `build-macos.sh` returns non-zero.
- Fix:
  1. Check Xcode toolchain and SDK availability.
  2. Re-run with a clean build if needed: delete `build-macos` and retry.
  3. Confirm `cmake` and `xcodebuild` are accessible.

### B) Missing tools (`xdelta3`, `python3`)
- Symptom: script exits with “Missing required tool”.
- Fix: install required tool via system package manager.

### C) Patched data rebuild fails
- Symptom: `rebirth-patch-data.sh` error.
- Fix:
  1. Verify `BASE_DIR` has `master.dat`, `critter.dat`, and `data/`.
  2. Confirm `third_party/rme/source` exists and contains payload.
  3. If checksum mismatch and you trust the base data, use `SKIP_CHECKSUMS=1`.

### D) Validation refresh fails
- Symptom: `rebirth-refresh-validation.sh` fails to diff.
- Fix:
  1. Ensure `GOG/unpatchedfiles` and `GOG/patchedfiles` exist.
  2. Check for filesystem permissions issues.

### E) Script audit fails
- Symptom: `rme-audit-script-refs.py` exits with error about missing `scripts.lst`.
- Fix:
  1. Confirm patched directory has `data/scripts/scripts.lst`.
  2. Rebuild patched data or re-run patch install.

### F) Data overlay validation fails
- Symptom: `rebirth-validate-data.sh` reports missing or mismatched files.
- Fix:
  1. Rebuild patched data with `REBUILD_PATCHED=1`.
  2. Verify RME payload integrity under `third_party/rme/source`.
  3. If DAT delta verification fails, confirm base DATs match expected source.

### G) Runtime sweep timeouts
- Symptom: `runtime_map_sweep_run.log` shows `[TIMEOUT]` for some maps.
- Fix:
  1. Increase `TIMEOUT` (e.g., `TIMEOUT=90`).
  2. Ensure no stray `fallout1-rebirth` processes are running (`pkill -f fallout1-rebirth`).
  3. If a specific map repeatedly times out, run it manually:
     ```bash
     F1R_AUTORUN_MAP=MAPNAME.MAP F1R_AUTOSCREENSHOT=1 \
       build-macos/RelWithDebInfo/Fallout\ 1\ Rebirth.app/Contents/MacOS/fallout1-rebirth
     ```
  4. Use `F1R_PATCHLOG=1` and `F1R_PATCHLOG_PATH=/tmp/f1r-patchlog.txt` for deeper insight.

### H) Black-map or suspicious screenshots
- Symptom: `runtime_map_sweep.csv` top_mean≈0, top_black≈100%, UI bottom still bright.
- Fix:
  1. Inspect screenshot from `runtime/screenshots/`.
  2. Check `MAP_HEADER` and `SQUARE_STATS` in patchlog if enabled.
  3. Confirm map exists in DAT and is not corrupted.

### I) App can’t find `master.dat` or `critter.dat`
- Symptom: patchlog shows `DB_INIT_FAIL stage=open datafile="master.dat"`.
- Fix:
  1. Ensure the app CWD is the Resources folder or it contains `master.dat`.
  2. Re-run `test-install-game-data.sh` to reinstall data into the bundle.

---

## 5) Key Files to Inspect

### Validation output
- `development/RME/validation/unpatched_vs_patched.diff`
- `development/RME/validation/raw/08_lst_missing.md`
- `development/RME/validation/raw/12_script_refs.md`
- `development/RME/validation/runtime/runtime_map_sweep.csv`
- `development/RME/validation/runtime/runtime_map_sweep.md`

### Runtime map sweep outputs
- `development/RME/validation/runtime/runtime_map_sweep_run.log`
- `development/RME/validation/runtime/screenshots/*.bmp`

---

## 6) Known Behaviors / Notes
- Autorun map mode skips map-enter scripts to avoid hangs during automated sweeps.
- Map globals (`*.GAM`) and saved maps (`*.SAV`) are considered optional and do not count as failures.
- The sweep uses a screenshot brightness heuristic; it is a smoke test, not a correctness proof.

---

## 7) Where to Add Future Coverage
- Additional runtime hooks can be added in `src/game/main.cc` and `src/game/map.cc`.
- If you want stricter failure conditions (e.g., fail on any missing file), adjust `db_diag_is_soft_open_fail` in `src/plib/db/db.cc`.
- If you want per-map artifact capture beyond screenshots, extend `scripts/patch/rme-runtime-sweep.py` to emit patchlog excerpts.

---

## 8) Quick Commands Reference
```bash
# Full pipeline
scripts/patch/rme-full-coverage.sh

# Full pipeline with rebuild + longer timeout
REBUILD_PATCHED=1 FORCE_PATCH=1 TIMEOUT=90 scripts/patch/rme-full-coverage.sh

# Map sweep only
python3 scripts/patch/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --out-dir development/RME/validation/runtime --timeout 60

# Single map run + screenshot
F1R_AUTORUN_MAP=V13ENT.MAP F1R_AUTOSCREENSHOT=1 \
  build-macos/RelWithDebInfo/Fallout\ 1\ Rebirth.app/Contents/MacOS/fallout1-rebirth
```

---

## 9) If You Need to Hand Off Further
- Share this runbook and `development/RME/summary/2026-02-09-coverage-plan.md`.
- The primary orchestration entrypoint is `scripts/patch/rme-full-coverage.sh`.
- Runtime hooks are in `src/game/main.cc`, `src/game/map.cc`, `src/plib/db/db.cc`, `src/plib/db/patchlog.cc`.
