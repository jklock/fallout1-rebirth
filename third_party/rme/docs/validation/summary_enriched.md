# Validation Summary — Enriched

**Purpose:** Quick actionable summary of validation results and instructions for fixers & reviewers.

**Where to look:** `GOG/validation/` (artifacts) and `GOG/validation/raw/` (per-command raw outputs).

## Key Findings (one-liners)
- Configs changed: `f1_res.ini` and `fallout.cfg` (windowing, resolution, patch directories).
- DATs replaced: Patched `master.dat` and `critter.dat` were verified and contain many RME files.
- Promotions: 114 files added to `master.dat`, 289 to `critter.dat`.
- Missing LST references: 117 entries need review.
- Case-only name changes: 20 pairs, must be reconciled for case-sensitive platforms.
- Map endianness: 9 maps flagged `map_endian=big` (engine-consistent).

## How a fixer LLM should use these artifacts
1. Read `GOG/validation/LLM_fix_mapping.md` (mapping doc) — it contains prioritized action items and reference helper files archived at `GOG/validation/scripts_archive/`.
2. Inspect the baseline audit outputs in `GOG/validation/raw/` (a reproduction script is archived at `GOG/validation/scripts_archive/run_full_audit.sh` for reference only); then run `./scripts/patch/rebirth-validate-data.sh` to confirm DAT baseline.
3. For data-only changes, prefer creating `GOG/validation/overlay_data/` and test the game by replacing only `data/` rather than DATs.
4. For case fixes, inspect `third_party/rme/docs/validation/case_test_results.txt` or use `GOG/validation/scripts_archive/propose_case_fixes.sh` as a reference to build an overlay copy that contains both cases for review.

## Quick verification commands
- Full audit: `GOG/validation/run_full_audit.sh` (writes raw outputs to `GOG/validation/raw/`)
- LST checks: `python3 scripts/patch/rme-crossref.py --rme third_party/rme/source --base-dir GOG/patchedfiles --out-dir GOG/rme_xref_patched`
- DAT validation: `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme/source`

## Suggested priority roadmap (short)
1. Fix LST missing references and case-only renames (High) — these cause runtime missing assets.
2. Decide DAT vs data-only packaging strategy and implement data overlay if needed (High).
3. Confirm configs are safe and do not enable unsupported engine states (Medium).
4. Add CI gate to run `GOG/validation/run_full_audit.sh` on PRs to prevent regressions (Low).

## Notes & assumptions
- This validation was run on macOS (case-insensitive by default) — some errors will only surface on case-sensitive systems; I tested case-sensitivity using a case-sensitive sparseimage.
- Fix proposals favor non-invasive changes (overlay files) over DAT replacement when possible.

---

If you want, I can now: (A) produce a per-RME JSON audit for precise PASS/FAIL, or (B) apply a candidate data-only overlay and run the game to verify behavior.
