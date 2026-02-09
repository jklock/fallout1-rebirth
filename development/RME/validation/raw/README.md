# Raw validation artifacts

This folder contains the raw outputs produced when the audit scripts were run. These files are intended as evidence for each claim and may be imported into automated workflows.

Key files:
- `rme-crossref-patched.csv`, `rme-crossref-unpatched.csv` — full RME cross-reference CSVs (patched vs unpatched)
- `master_added_rows.csv`, `critter_added_rows.csv` — rows for promoted files (used by overlay generation)
- `lst_candidates.csv` — candidate matches for missing LST references
- `12_script_refs.md`, `12_script_refs.csv` — audit of missing scripts (scripts.lst) and whether any are referenced by MAP/PRO content
- `generate_patch_mapping.log` — output of `generate_patch_mapping.py`
- `generate_overlay_from_rows.log` — overlay generation log (shows missing items)
- `run_full_audit.log` — when the full audit script is executed
- `unpatched_vs_patched.diff` — full tree diff (huge; open with a pager)

Tips:
- For automation, read `patch_mapping.csv` in `GOG/validation/` (contains recommended_action & priority per RME file).
- Always review matches from `lst_candidates.csv` before blindly copying or renaming assets.
