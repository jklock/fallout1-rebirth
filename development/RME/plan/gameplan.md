# RME Data Integration Plan (Game Files)

## Goal
Patch the user's Fallout 1 data in place (master.dat, critter.dat, data/) so the first launch works immediately after copying into the `.app` / `.ipa`.

## Assumptions
- Fresh installs only (no save migration).
- Users source their own base game data.
- We provide scripts to apply the full RME stack.

## Chosen Data Strategy
- Apply xdelta patches to `master.dat` and `critter.dat`.
- Overlay all RME `DATA/*` files directly into `data/` (overwrite).
- Use NPC Mod 3.5 + Fix (No Armor is excluded).

## Inputs (User)
- Base Fallout 1 data folder with:
  - `master.dat`
  - `critter.dat`
  - `data/`

## Inputs (Repo)
- RME payload stored in:
  - `third_party/rme/source/`
  - `third_party/rme/checksums.txt`
  - `third_party/rme/manifest.json`

## Output (Patched Data Folder)
The script outputs a fully patched folder the user can copy into the `.app` / `.ipa`:
```
Fallout1-RME/
  master.dat
  critter.dat
  data/
  fallout.cfg
  f1_res.ini
```

## End-to-End User Flow

### macOS
1. Build or download the `.app` / `.dmg` as usual.
2. Run:
   - `scripts/patch/rebirth-patch-app.sh --base <game-data> --out <patched>`
3. Copy the patched output into:
   - `/Applications/Fallout 1 Rebirth.app/Contents/Resources/`
4. Launch the game.

### iOS/iPadOS
1. Build or download the `.ipa` as usual.
2. Run:
   - `scripts/patch/rebirth-patch-ipa.sh --base <game-data> --out <patched>`
3. Use Finder to copy patched output into:
   - `Files > Fallout 1 Rebirth > Documents/`
4. Launch the game.

## Script Implementation
We provide two user-facing scripts plus a shared core:

### 1) `scripts/patch/rebirth-patch-data.sh` (core)
Inputs:
- `--base PATH` (base game data)
- `--rme PATH` (defaults to `third_party/rme/source`)
- `--out PATH` (output folder)

Steps:
1. Validate base files exist (`master.dat`, `critter.dat`, `data/`).
2. Validate base DAT checksums against `third_party/rme/checksums.txt`.
3. Copy base data into `out/`.
4. Apply xdelta patches:
   - `master.xdelta` -> `master.dat`
   - `critter.xdelta` -> `critter.dat`
5. Overlay RME `DATA/*` into `out/data/` (overwrite existing files).
6. Normalize case to lowercase inside `out/data/`.
7. Optionally copy config templates into `out/` when `--config-dir` is provided:
   - `gameconfig/<platform>/fallout.cfg`
   - `gameconfig/<platform>/f1_res.ini`
8. Emit summary (file counts, checksums, size).

### 2) `scripts/patch/rebirth-patch-app.sh`
Wrapper for macOS:
- Calls `rebirth-patch-data.sh` with `--config-dir gameconfig/macos`.
- Prints the exact `.app` path and copy instructions.

### 3) `scripts/patch/rebirth-patch-ipa.sh`
Wrapper for iOS:
- Calls `rebirth-patch-data.sh` with `--config-dir gameconfig/ios`.
- Prints Finder copy instructions.

## Required Tools
- `xdelta3` (apply xdelta patches)
- `rsync` or `cp` for data copy
- `python3` for lowercase normalization

## Config Requirements
Config templates must remain set to patch-in-place behavior:
- `master_patches=data`
- `critter_patches=data`

## Validation Targets
Confirm these are present and loaded from `data/`:
- `text/english/game/proto.msg`
- `text/english/dialog/razor.msg`
- `scripts/killian.int`
- `scripts/tandi.int`
- `scripts/master1.int`
- `font3.aaf`, `font4.aaf`
- `sound/sfx/wae1xxx1.acm`, `sound/sfx/wae1xxx2.acm`

## Data-Side Definition of Done
- Script produces patched data folder with xdelta-applied DATs and RME DATA overlay.
- User can copy the output into the `.app` / `.ipa` and launch immediately.
- NPC Mod 3.5 + Fix behavior is active.
