# Promotions — Enriched

**What changed:** Files from the RME payload were *integrated into the patched DATs* rather than remaining as loose `data/` files. This file elaborates counts, extension breakdowns, and recommended actions for fixers.

## Counts (validated)
- Files added to `master.dat`: **114**
  - Extension breakdown (from `GOG/master_added_ext_counts.txt`):
    - 92 `*.pro`
    - 8 `*.gam`
    - 5 `*.int`
    - 5 `*.frm`
    - 2 `*.msg`
    - 1 `*.pal`
    - 1 `*.acm`
- Files added to `critter.dat`: **289**
  - Extension breakdown (from `GOG/critter_added_ext_counts.txt`):
    - 133 `*.frm` (frames)
    - 26 `*.fr5`
    - 26 `*.fr4`
    - 26 `*.fr3`
    - 26 `*.fr2`
    - 26 `*.fr1`
    - 26 `*.fr0`

## Why this matters
- Packaging approach changed: instead of a pure overlay, the patched package updates the binary DATs. This affects users and installers that expect a "drop-in data overlay" behavior (they will not see the same behavior if only `data/` is updated).

## Recommended actions for fixers
1. Decide the project's intended packaging model:
   - If DAT replacement is acceptable: keep patched DATs and document their provenance and checksums (`GOG/validation/*.sha256`).
   - If you want a data-only patch: extract the promoted files from the patched `data/` tree (or DATs), and create `GOG/validation/overlay_data/` that contains only those files. A reference helper file is preserved at `GOG/validation/scripts_archive/generate_overlay_from_rows.sh` (archived; reference-only).
2. For each promoted `*.pro/*.int` file (high impact): verify references in LSTs/INTs and ensure no surprising side-effects (scripts that expect those prototypes to be in DAT may behave differently if left in DAT vs overlay).
3. For `critter` frames (`*.frm`): ensure the game reads the frames the same way when they are in overlay vs DAT by running game load tests; check for missing animations.

## Verification (example)
- Build overlay directory: use `GOG/validation/scripts_archive/generate_overlay_from_rows.sh --dest GOG/validation/overlay_data` (archived; reference-only) or copy files manually from `GOG/patchedfiles/data` into `GOG/validation/overlay_data`.
- Run validation across overlay-only mode (prefer a test runner or the engine with overlay configured): run `./scripts/patch/rebirth-validate-data.sh --patched GOG/validation/overlay_data --base GOG/unpatchedfiles --rme third_party/rme/source` and inspect results.

## Artifacts to look at
- `GOG/master_added_files.txt`
- `GOG/critter_added_files.txt`
- `GOG/validation/raw/master_added_rows.csv` (detailed rows)
- `GOG/validation/raw/critter_added_rows.csv`

---

If you want, I can build `GOG/validation/overlay_data/` for you, test it in overlay-only mode, and attach a suggested PR with the overlay files (small-ish canonical set). Which approach do you prefer (DAT replace vs overlay)?
