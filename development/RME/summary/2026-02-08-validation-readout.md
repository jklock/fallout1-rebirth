# RME Validation Readout (2026-02-08)

## Scope
- Reviewed all files under `development/RME/validation/` (including `raw/` and `scripts_archive/`).

## Update (2026-02-09)
- Regenerated `GOG/patchedfiles` using the fixed macOS templates and strict case-normalization.
- Refreshed the full evidence bundle in `development/RME/validation/` using `scripts/patch/rebirth-refresh-validation.sh`.
- Implemented missing tooling:
  - `scripts/patch/rme-crossref.py` (was referenced by docs but missing from the repo)
  - `scripts/patch/rme-find-lst-candidates.py` (keeps `development/RME/validation/raw/lst_candidates.csv` current)
- Implemented script-reference auditing:
  - `scripts/patch/rme-audit-script-refs.py` (produces `development/RME/validation/raw/12_script_refs.*`)
- Fixed validator noise for `SCRIPTS\\SCRIPTS.LST` `.ssl` entries:
  - Runtime always resolves scripts.lst entries to `<base>.int` (see `scr_index_to_name`), so the LST validator now checks `.int` for `.ssl`.
- Eliminated all LST missing references by replacing demo-only/dead entries with safe placeholders:
  - `ART\\INTRFACE\\INTRFACE.LST`: missing FRMs now point at `blank.frm`.
  - `SCRIPTS\\SCRIPTS.LST`: missing scripts now point at `allnone.int`.
- Current LST missing count: **0** (see `development/RME/validation/raw/08_lst_missing.md`).

## Build Outputs Generated (Scripts Only)
- macOS `.app`: `build-macos/RelWithDebInfo/Fallout 1 Rebirth.app`
- iOS `.app`: `build-ios/RelWithDebInfo-iphoneos/fallout1-rebirth.app`
- iOS `.ipa`: `build-outputs/iOS/fallout1-rebirth.ipa`

## Executive Summary
- The validation set is a useful evidence bundle and is now refreshed to match current patch outputs (`GOG/patchedfiles`) and config templates.
- The "hard" validation (`rebirth_validate.log`) passed, including overlay integrity, CRLF normalization, and DAT patch verification.
- Platform correctness is addressed by strict lowercasing + collision detection in `scripts/patch/rebirth-patch-data.sh`.
- Platform correctness is also protected by case-insensitive path resolution on non-Windows via `compat_resolve_path` (used by `compat_fopen`).
- The validation now shows **0** missing LST references, so the "missing files from LST" risk is eliminated for shipped data.

If we want to treat this directory as the canonical validation record going forward, keep regenerating it after any data/template changes with `./scripts/patch/rebirth-refresh-validation.sh`.

## High-Confidence Findings

### 1) Patched DATs Are Verified and Match the Expected Hashes
Evidence:
- `development/RME/validation/master_patched.sha256`
- `development/RME/validation/critter_patched.sha256`
- `development/RME/validation/raw/04_dat_shasums.txt`

### 2) The Historical Config Diff Captured a Real macOS Scaling Footgun
Evidence:
- `development/RME/validation/raw/03_configs_diff.txt`

Historically this diff showed patched windowed settings with `SCALE_2X=0`. In the Fallout renderer, that results in a 1280x960 logical resolution (scale=1), which is a known path to "UI/actor renders but the world stays black" after map load.

This is now fixed: current patched output shows `SCALE_2X=1` (the regenerated `development/RME/validation/raw/03_configs_diff.txt` reflects this).

### 3) Case-Only Duplicates Exist and Were Measured on Case-Sensitive Media
Evidence:
- `development/RME/validation/case_renames.txt` (20 pairs)
- `development/RME/validation/raw/case_test_results.txt`
- `development/RME/validation/case_test.log`

Notes:
- For the FRM duplicates tested, the pairs were identical content (matching sha256).
- Directory pairs like `MAPS <-> maps`, `SCRIPTS <-> scripts`, `TEXT <-> text` are still important because:
  - On case-insensitive filesystems they collapse into one directory (implicit merge).
  - On case-sensitive filesystems they can coexist, and any case-sensitive lookup in tooling/runtime can miss assets.

### 4) LST Reference Integrity Is the Biggest Data-Side Risk
Evidence:
- `development/RME/validation/raw/08_lst_missing.md`
- `development/RME/validation/raw/lst_candidates.csv`

Observed patterns:
- Previously, `ART\\INTRFACE\\INTRFACE.LST` and `SCRIPTS\\SCRIPTS.LST` referenced assets/scripts that were not present in either the RME overlay or the base DATs.
- These have been intentionally silenced by aliasing the dead/demo entries to safe placeholders, bringing the missing count to **0**.

This is not automatically fatal, but it is the kind of issue that becomes intermittent and platform-dependent:
- If missing tokens are truly unused, no symptoms.
- If any missing token is referenced by a proto, map, or UI path in actual play, you get missing art/scripts at runtime.

Script usage audit evidence:
- `development/RME/validation/raw/12_script_refs.md`
Current finding: `development/RME/validation/raw/12_script_refs.md` reports **0** missing scripts, and therefore no shipped MAP/PRO content can reference a missing script.

The `INTRFACE.LST` backup in this directory shows those "NO LONGER USED" entries were historically still active lines:
- `development/RME/validation/raw/INTRFACE.LST.bak`

Those specific entries have since been commented out in the source `INTRFACE.LST` to avoid chasing assets that do not exist.

## Notes on Specific Validation Outputs

### Top-Level Inventory
- `development/RME/validation/unpatched_vs_patched.diff`
  - Full unified diff of the extracted unpatched vs patched trees (large).
  - Contains useful point evidence like `intrface.lst` and `scripts.lst` additions.
- `development/RME/validation/*_added_files.txt`
  - Lists of "promoted" files added to `master.dat` and `critter.dat`.
- `development/RME/validation/patched_*_files.txt`, `development/RME/validation/unpatched_*_files.txt`
  - File lists associated with the DAT and/or patch delta sets (counts align with crossref stats).

### Raw Folder
- `development/RME/validation/raw/rme-crossref-*.csv`
  - Canonical mapping of file -> base source (`master.dat`, `critter.dat`, `none`) plus hashes and sizes.
- `development/RME/validation/raw/12_script_refs.md`, `development/RME/validation/raw/12_script_refs.csv`
  - Which missing scripts are actually referenced by shipped MAP/PRO content.
- `development/RME/validation/raw/07_map_endian.txt`
  - Lists `map_endian=big` rows extracted from the patched crossref.
  - `scripts/patch/rme-crossref.py` validates MAP header version (expects big-endian `19`) and annotates these rows.
- `development/RME/validation/raw/03_configs_diff.txt`
  - Shows the patched config now uses `SCALE_2X=1` (and documents prior behavior in the diff).
- `development/RME/validation/raw/run_full_audit.log`
  - Empty (no evidence captured there).

### Archived Helper Scripts (Caveat Emptor)
Evidence:
- `development/RME/validation/scripts_archive/*`
- `development/RME/validation/raw/generate_overlay_from_rows.log`

The archived scripts were useful to generate artifacts, but some had Windows-path handling bugs on macOS (backslashes treated as normal characters by POSIX basename/pathlib).
- These path normalization bugs have been fixed in the archived scripts so they can be re-run reliably if needed.
- After re-running `generate_overlay_from_rows.sh` with the fixed path handling, the overlay-generation log contains **no** `MISSING:` entries (it successfully locates and copies all promoted files from `GOG/patchedfiles` into the overlay staging directory).

## Where Next Steps Live
- Actionable follow-ups are recorded in: `development/RME/todo/validation_todo.md`
