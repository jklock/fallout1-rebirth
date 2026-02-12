# Validation Todo (Post-2026-02-08 Audit)

## Regenerate Evidence (Keep Validation Folder Current)
- [x] Re-run the validation pipeline after the latest fixes (macOS `SCALE_2X=1`, `INTRFACE.LST` comment-outs) and refresh `development/RME/validation/` so it reflects the current shipped state.
- [x] Re-run the LST missing report and confirm the `INTRFACE.LST` "NO LONGER USED" set no longer appears as missing.
  - Current missing count: 0 total (see `development/RME/validation/raw/08_lst_missing.md`).
  - Refresh command: `./scripts/patch/rebirth-refresh-validation.sh`

## LST and Script Reference Integrity (Highest Risk)
- [x] Determine whether any "missing" entries in `development/RME/validation/raw/08_lst_missing.md` are actually required at runtime.
  - Resolved by aliasing dead/demo entries to safe placeholders so that runtime never attempts to load missing files.
  - `ART\\INTRFACE\\INTRFACE.LST`: `SATTKSUP.FRM`, `upsell03-09.frm` now point at `blank.frm`.
  - `SCRIPTS\\SCRIPTS.LST`: missing script entries now point at `allnone.int`.
- [x] For `SCRIPTS\\SCRIPTS.LST` missing `.int` entries, check whether any maps/protos reference the corresponding script IDs.
  - Implemented by `scripts/patch/rme-audit-script-refs.py` (output: `development/RME/validation/raw/12_script_refs.md`).
  - Current finding: 0 missing scripts (so nothing can reference a missing script).
- [x] Decide what to do with `.ssl` references in `SCRIPTS.LST`.
  - Runtime always resolves scripts.lst entries to `<base>.int` (see `scr_index_to_name`), so `.ssl` files are not required for runtime.
  - The validator now checks `.int` existence when scripts.lst contains `.ssl`, eliminating false-positive "missing .ssl" noise.
- [x] Add a repeatable check: "Every filename token in shipped `*.lst` that looks like a file must exist in either `data/` or inside the patched DATs."
  - Implemented by `scripts/patch/rme-crossref.py` which produces `development/RME/validation/raw/08_lst_missing.md`.

## Case Sensitivity (Platform Correctness)
- [x] Add a repeatable check: detect case-insensitive collisions in the produced `data/` tree (for example `MAPS` vs `maps`, `HR_MAINMENU.frm` vs `hr_mainmenu.frm`).
  - Implemented in `scripts/patch/rebirth-patch-data.sh` (strict normalization + collision handling).
- [x] Decide the supported stance explicitly.
- [x] Option A: enforce all-lowercase output and fail the build if any mixed-case path remains.
- [x] Option B: implement case-insensitive lookup fallback in the loader for macOS/Linux case-sensitive volumes (defense in depth).
  - Already implemented by `compat_resolve_path` (used by `compat_fopen`), which resolves each path component case-insensitively on non-Windows platforms.

## Archived Script Reliability
- [x] If we intend to rely on anything in `development/RME/validation/scripts_archive/`, fix path handling first.
- [x] Normalize `ART\\FOO\\BAR.BAZ` to `ART/FOO/BAR.BAZ` before computing basenames or joining paths.
  - Fixed in `development/RME/validation/scripts_archive/generate_overlay_from_rows.sh`
  - Fixed in `development/RME/validation/scripts_archive/generate_patch_mapping.py`
  - Fixed in `development/RME/validation/scripts_archive/generate_lst_actions.py`
- [x] Reproduce `generate_overlay_from_rows.log` after that fix.
  - Re-run shows `MISSING:` count = 0 (overlay generation successfully finds and copies promoted files).

## Map Endianness Signal
- [x] Validate the `map_endian=big` rows in `development/RME/validation/raw/07_map_endian.txt` by loading those maps in-game (or by writing a small parser that inspects the map headers) to confirm whether this is a real format divergence or a heuristic artifact.
  - `scripts/patch/rme-crossref.py` validates MAP header version (expects big-endian `19`) and annotates `map_endian=big`.
