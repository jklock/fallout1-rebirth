# Validation artifacts & Fixer quick-start

**Cohesive narrative:** For the chronological story, evidence chain, and recommended path for fixes read `GOG/validation/NARRATIVE.md`.

This README helps a fixer (human or LLM) get started quickly with the artifacts in `GOG/validation/`.

1. Read the mapping doc: `GOG/validation/LLM_fix_mapping.md`
2. Inspect the baseline audit outputs at `GOG/validation/raw/` (a reproduction script is archived at `GOG/validation/scripts_archive/run_full_audit.sh` for reference only).
3. Re-run the RME crossref if needed: `python3 scripts/patch/rme-crossref.py --rme third_party/rme/source --base-dir GOG/patchedfiles --out-dir GOG/rme_xref_patched`
4. Reference helper files (archived) in `GOG/validation/scripts_archive/`:
   - `generate_overlay_from_rows.sh` — reference: build `GOG/validation/overlay_data` with promoted files (best-effort copy)
   - `propose_case_fixes.sh` — reference: create `GOG/validation/overlay_casefix` that contains case-variant copies
   - `find_lst_candidates.py` — reference: produce `GOG/validation/raw/lst_candidates.csv` with candidate matches to missing LST entries
   - `generate_patch_mapping.py` — reference: creates `GOG/validation/patch_mapping.csv` mapping RME paths to recommendations
5. For any change: create a branch `fix/<ISSUE-ID>-<short>` and a small PR. Run `./scripts/dev/dev-check.sh` and `./scripts/dev/dev-verify.sh` before pushing.

If you want assistance performing the change (creating the overlay and opening PRs), tell me which ISSUE to start with and I will implement a trial PR that includes tests and verification logs.
