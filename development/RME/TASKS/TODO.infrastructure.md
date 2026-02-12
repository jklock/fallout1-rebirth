# TODO: Infrastructure — Build, Patch, Install, Validate

> **Purpose**: Establish a clean, verified build with patched RME data installed into the app bundle.
> All commands run from the repo root: `cd /Volumes/Storage/GitHub/fallout1-rebirth`

---

## Prerequisites (Task I-0)

Before starting, verify these tools and data are available.

- [ ] **Xcode + CLI tools installed**
  ```bash
  xcode-select -p
  # Expected: /Applications/Xcode.app/Contents/Developer (or similar)
  # If missing: xcode-select --install
  ```

- [ ] **xdelta3 installed** (required for DAT patching)
  ```bash
  which xdelta3
  # Expected: /opt/homebrew/bin/xdelta3 (or /usr/local/bin/xdelta3)
  # If missing:
  brew install xdelta
  ```

- [ ] **python3 available**
  ```bash
  python3 --version
  # Expected: Python 3.x.x
  # If missing: brew install python3
  ```

- [ ] **GOG Fallout 1 data in place**
  ```bash
  ls GOG/unpatchedfiles/master.dat GOG/unpatchedfiles/critter.dat
  ls GOG/unpatchedfiles/data/ | head -5
  # Expected: Both .dat files exist, data/ has subdirectories
  # If missing: Copy your GOG Fallout 1 installation data to GOG/unpatchedfiles/
  ```

- [ ] **RME payload present**
  ```bash
  ls third_party/rme/source/
  # Expected: critter.dat.xdelta, master.dat.xdelta, data/ (with overlay files)
  # If missing: git submodule update --init (or check third_party/rme/)
  ```

---

## Task I-1: Clean Build macOS

Remove all build artifacts and perform a clean build.

- [ ] **Clean all build directories**
  ```bash
  ./scripts/dev/dev-clean.sh
  ```
  **Expected output**: Removes `build/`, `build-macos/`, `build-ios/`, and other build dirs. Exit code 0.

- [ ] **Build macOS (Xcode generator)**
  ```bash
  ./scripts/build/build-macos.sh
  ```
  **Expected output**: CMake configure + build succeeds with exit code 0. Build output in `build-macos/`.

- [ ] **Verify binary exists**
  ```bash
  ls -la "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"
  ```
  **Expected output**: Binary file, ~5-15 MB, recent timestamp.

- [ ] **Verify app bundle structure**
  ```bash
  ls "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/"
  ```
  **Expected output**: `Info.plist`, `MacOS/`, `Resources/` directories present.

**If build fails**:
1. Check Xcode is installed: `xcode-select -p`
2. Check CMake version: `cmake --version` (need 3.20+)
3. Read the error output — most common issue is missing Xcode or SDK path problems.
4. Try `./scripts/dev/dev-clean.sh` then rebuild.

---

## Task I-2: Patch Fresh Game Data (macOS)

Generate a fully-patched set of game data by applying RME deltas + overlays to GOG base data.

- [ ] **Remove any prior patched output**
  ```bash
  rm -rf GOG/patchedfiles
  ```
  **Expected**: Directory removed (or didn't exist). Exit code 0.

- [ ] **Run the patch script**
  ```bash
  ./scripts/patch/rebirth-patch-app.sh \
    --base GOG/unpatchedfiles \
    --out GOG/patchedfiles \
    --force
  ```
  **Expected output**:
  - xdelta3 applies `master.dat.xdelta` and `critter.dat.xdelta` successfully
  - RME overlay data files copied into `data/`
  - macOS config files (`fallout.cfg`, `f1_res.ini`) written
  - Exit code 0

- [ ] **Verify DAT files exist**
  ```bash
  ls -la GOG/patchedfiles/master.dat GOG/patchedfiles/critter.dat
  ```
  **Expected**: Both files present. `master.dat` ~20-50 MB, `critter.dat` ~30-60 MB (sizes vary based on patch).

- [ ] **Verify data overlay directory**
  ```bash
  ls GOG/patchedfiles/data/ | head -20
  find GOG/patchedfiles/data/ -type f | wc -l
  ```
  **Expected**: Subdirectories like `art/`, `maps/`, `proto/`, `text/`. File count should be 1000+ (full RME payload is ~1,126 files across DATs and overlay).

- [ ] **Verify config files**
  ```bash
  ls GOG/patchedfiles/fallout.cfg GOG/patchedfiles/f1_res.ini
  ```
  **Expected**: Both config files present.

**If patching fails**:
1. `xdelta3: not found` → Install: `brew install xdelta`
2. `base master.dat checksum mismatch` → Your GOG data may be a different version. Try `--skip-checksums` flag.
3. `output directory already exists` → Add `--force` flag or manually `rm -rf GOG/patchedfiles`.
4. Missing base files → Ensure `GOG/unpatchedfiles/` has `master.dat`, `critter.dat`, and `data/`.

---

## Task I-3: Validate Patches (Static)

Run the validation script to confirm the patched data is complete and correct.

- [ ] **Run static validation**
  ```bash
  ./scripts/patch/rebirth-validate-data.sh \
    --patched GOG/patchedfiles \
    --base GOG/unpatchedfiles
  ```
  **Expected output**:
  ```
  [OK] master.dat verified
  [OK] critter.dat verified
  [OK] Data files validated: missing=0, mismatched=0
  ```
  Exit code: **0**

- [ ] **Verify no warnings or errors in output**
  ```bash
  ./scripts/patch/rebirth-validate-data.sh \
    --patched GOG/patchedfiles \
    --base GOG/unpatchedfiles 2>&1 | grep -E "WARN|ERROR|FAIL"
  ```
  **Expected**: No output (no warnings or errors).

**If validation fails**:
1. `missing > 0`: Some RME overlay files weren't copied. Re-run Task I-2 with `--force`.
2. `mismatched > 0`: DAT files don't match expected output. Re-run patching from scratch.
3. Missing `--base` data: Ensure GOG/unpatchedfiles/ has original master.dat + critter.dat.
4. If checksum mismatches on DATs, the xdelta patches may not match your GOG version. Check `GOG/unpatchedfiles/` source.

---

## Task I-4: Refresh Validation Evidence

Regenerate canonical validation artifacts used for audit trails.

- [ ] **Run the refresh script**
  ```bash
  ./scripts/patch/rebirth-refresh-validation.sh \
    --unpatched GOG/unpatchedfiles \
    --patched GOG/patchedfiles \
    --rme third_party/rme/source \
    --out development/RME/ARTIFACTS/evidence
  ```
  **Expected output**: Script generates SHA256 checksums, file lists, diff reports. Exit code 0.

- [ ] **Verify evidence artifacts were created**
  ```bash
  ls development/RME/ARTIFACTS/evidence/
  ```
  **Expected files** (some or all of):
  - `master_patched.sha256`, `master_unpatched.sha256`
  - `critter_patched.sha256`, `critter_unpatched.sha256`
  - `patched_master_files.txt`, `patched_critter_files.txt`
  - `master_added_files.txt`, `critter_added_files.txt`
  - `master_added_ext_counts.txt`, `critter_added_ext_counts.txt`

- [ ] **Verify raw evidence directory**
  ```bash
  ls development/RME/ARTIFACTS/evidence/raw/ 2>/dev/null || echo "No raw/ directory"
  ```
  **Expected**: May contain detailed diff outputs, per-file checksums.

**If refresh fails**:
1. Missing patched data → Complete Task I-2 first.
2. `shasum: command not found` → Should be built into macOS. Check `which shasum`.
3. Permission errors → Check `development/RME/ARTIFACTS/evidence/` is writable.

---

## Task I-5: Install Patched Data into App Bundle

Copy verified patched data into the built app's Resources directory so the game can find it at runtime.

- [ ] **Define paths (for reference)**
  ```bash
  APP_RESOURCES="build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources"
  PATCHED="GOG/patchedfiles"
  ```

- [ ] **Copy DAT files**
  ```bash
  cp "GOG/patchedfiles/master.dat" \
     "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/master.dat"

  cp "GOG/patchedfiles/critter.dat" \
     "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/critter.dat"
  ```
  **Verify**:
  ```bash
  ls -la "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/master.dat"
  ls -la "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/critter.dat"
  ```
  **Expected**: Both files present with matching sizes to `GOG/patchedfiles/` originals.

- [ ] **Copy data overlay directory**
  ```bash
  rsync -av "GOG/patchedfiles/data/" \
    "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/data/"
  ```
  **Verify**:
  ```bash
  find "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/data/" -type f | wc -l
  ```
  **Expected**: File count matches `find GOG/patchedfiles/data/ -type f | wc -l`.

- [ ] **Copy config files**
  ```bash
  cp gameconfig/macos/fallout.cfg \
     "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/fallout.cfg"

  cp gameconfig/macos/f1_res.ini \
     "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/f1_res.ini"
  ```
  **Verify**:
  ```bash
  ls -la "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/fallout.cfg"
  ls -la "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/f1_res.ini"
  ```
  **Expected**: Both config files present.

- [ ] **Final verification — full Resources listing**
  ```bash
  ls "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources/"
  ```
  **Expected**: `master.dat`, `critter.dat`, `data/`, `fallout.cfg`, `f1_res.ini` all present.

- [ ] **Quick smoke test — launch the game**
  ```bash
  open "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
  ```
  **Expected**: Game launches, main menu appears. Close manually.

**If launch fails**:
1. Black screen / crash → Check Console.app for crash logs under `fallout1-rebirth`.
2. "master.dat not found" → Verify DATs are in Resources/, check `fallout.cfg` paths.
3. Missing data files → Re-run rsync for data/ overlay.
4. Wrong config → Ensure `fallout.cfg` has `master_dat=master.dat` and `critter_dat=critter.dat` (relative paths).

---

## Completion Checklist

| Step | Task | Status |
|------|------|--------|
| I-0 | Prerequisites verified | [ ] |
| I-1 | Clean macOS build succeeded | [ ] |
| I-2 | Fresh patched data generated | [ ] |
| I-3 | Static validation passed (missing=0, mismatched=0) | [ ] |
| I-4 | Validation evidence refreshed | [ ] |
| I-5 | Patched data installed in app bundle | [ ] |
| I-5 | Smoke test: game launches | [ ] |

**All tasks must pass before proceeding to map, art, or prototype validation.**
