# Validation Todo (Post-2026-02-08 Audit)

## Regenerate Evidence (Keep Validation Folder Current)
- [x] Re-run the validation pipeline after the latest fixes (macOS `SCALE_2X=1`, `INTRFACE.LST` comment-outs) and refresh `development/RME/validation/` so it reflects the current shipped state.
- [x] Re-run the LST missing report and confirm the `INTRFACE.LST` "NO LONGER USED" set no longer appears as missing.
  - Current missing count: 74 total (INTRFACE: 8, SCRIPTS: 66) per `development/RME/validation/raw/08_lst_missing.md`.
  - Refresh command: `./scripts/patch/rebirth-refresh-validation.sh`

## LST and Script Reference Integrity (Highest Risk)
- [ ] Determine whether any "missing" entries in `development/RME/validation/raw/08_lst_missing.md` are actually required at runtime.
- [ ] For `SCRIPTS\\SCRIPTS.LST` missing `.int` entries, check whether any maps/protos reference the corresponding script IDs (script index is `sid & 0xFFFFFF`).
- [ ] Decide what to do with `.ssl` references in `SCRIPTS.LST`:
  - Option A: comment them out (preferred if we never ship `.ssl`).
  - Option B: ship the `.ssl` files (not typical for runtime).
- [x] Add a repeatable check: "Every filename token in shipped `*.lst` that looks like a file must exist in either `data/` or inside the patched DATs."
  - Implemented by `scripts/patch/rme-crossref.py` which produces `development/RME/validation/raw/08_lst_missing.md`.

## Case Sensitivity (Platform Correctness)
- [x] Add a repeatable check: detect case-insensitive collisions in the produced `data/` tree (for example `MAPS` vs `maps`, `HR_MAINMENU.frm` vs `hr_mainmenu.frm`).
  - Implemented in `scripts/patch/rebirth-patch-data.sh` (strict normalization + collision handling).
- [x] Decide the supported stance explicitly.
- [x] Option A: enforce all-lowercase output and fail the build if any mixed-case path remains.
- [ ] Option B: implement case-insensitive lookup fallback in the loader for macOS/Linux case-sensitive volumes (optional defense in depth).

## Archived Script Reliability
- [x] If we intend to rely on anything in `development/RME/validation/scripts_archive/`, fix path handling first.
- [x] Normalize `ART\\FOO\\BAR.BAZ` to `ART/FOO/BAR.BAZ` before computing basenames or joining paths.
  - Fixed in `development/RME/validation/scripts_archive/generate_overlay_from_rows.sh`
  - Fixed in `development/RME/validation/scripts_archive/generate_patch_mapping.py`
  - Fixed in `development/RME/validation/scripts_archive/generate_lst_actions.py`
- [ ] Reproduce `generate_overlay_from_rows.log` after that fix, otherwise treat its "MISSING" output as non-actionable.

## Map Endianness Signal
- [x] Validate the `map_endian=big` rows in `development/RME/validation/raw/07_map_endian.txt` by loading those maps in-game (or by writing a small parser that inspects the map headers) to confirm whether this is a real format divergence or a heuristic artifact.
  - `scripts/patch/rme-crossref.py` validates MAP header version (expects big-endian `19`) and annotates `map_endian=big`.
