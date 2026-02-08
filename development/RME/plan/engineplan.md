# RME Engine Integration Plan (Backend / src)

## Goal
Make the engine load RME-patched data that lives directly in the user's `data/` folder, with no special runtime patch directory.

## Scope
Engine and config behavior only. No new runtime patch layer. No save-path changes. Fresh installs only.

## Chosen Technical Approach
- Patch in place: user-patched `master.dat`, `critter.dat`, and `data/` are copied into the `.app` / `.ipa`.
- Keep existing config behavior:
  - `master_patches=data`
  - `critter_patches=data`
- Saves remain where they are today (no change to save path logic).

## Engine Changes (Required)
None. The engine already supports `master_patches=data` and loads loose files from the `data/` folder.

## Engine Changes (Not Required)
- No `save_path` changes.
- No patch DAT support.
- No DB layer changes.

## Config Validation (Required)
Verify the templates already reflect patch-in-place behavior:
- `gameconfig/macos/fallout.cfg` contains:
  - `master_patches=data`
  - `critter_patches=data`
- `gameconfig/ios/fallout.cfg` contains:
  - `master_patches=data`
  - `critter_patches=data`

## Build + Script Plan (End Users)
End-user flow is defined in `development/RME/plan/gameplan.md` and uses:
- `scripts/patch/rebirth-patch-app.sh`
- `scripts/patch/rebirth-patch-ipa.sh`

Concrete install paths:
- macOS app bundle data root:
  - `/Applications/Fallout 1 Rebirth.app/Contents/Resources/`
- iOS app data root (Finder):
  - `Files > Fallout 1 Rebirth > Documents/`

## Third-Party Storage Strategy (Repo)
We store the RME payload in-repo so the scripts can run deterministically.

Proposed location:
```
third_party/rme/
  README.md
  manifest.json
  checksums.txt
  source/
    DATA/...
    master.xdelta
    critter.xdelta
```

Rules:
- Scripts must use `third_party/rme/source/` as the source of truth.
- `checksums.txt` stores SHA256 for:
  - base `master.dat` / `critter.dat` (pre-patch)
  - RME payload files
- `manifest.json` stores expected counts and version metadata.

## Engine Validation
1. Copy patched data into the `.app` / `.ipa`.
2. Confirm the game boots and loads assets from `data/`.
3. Confirm saves land in the same location as today.

## Engine-Side Definition of Done
- No engine code changes required.
- Config templates remain aligned with patch-in-place (`master_patches=data`).
- RME patches load correctly from the `data/` folder.
