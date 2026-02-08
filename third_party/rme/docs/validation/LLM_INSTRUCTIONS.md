# LLM Instructions for Fixing (Strict & Reproducible)

**Important:** Read `GOG/validation/NARRATIVE.md` before acting; it contains the evidence trail and command timeline that informed these instructions.

Use this file as a concise instruction set for an automated LLM agent performing fixes. Follow the rules and step-by-step flow exactly to maintain reproducibility and reviewability.

Rules (must follow):
- Make only one *logical* change per branch/PR. Keep commits small and focused.
- Do not modify original game assets beyond making overlay copies. If an asset is missing and must be restored, prefer to add it to `GOG/validation/overlay_data/` rather than changing `master.dat` or `critter.dat` directly.
- Always run `./scripts/dev/dev-check.sh` and `./scripts/dev/dev-verify.sh` and include their output in the PR.
- For every automated change (copy/rename/patch), include a short human-readable justification in the commit message (e.g., "ISSUE-LST-002: add missing actionh.frm referenced by ART/INTRFACE/INTRFACE.LST")
- Prefer non-destructive fixes: add overlay files or symlinks rather than deleting or overwriting files unless the overwrite is explicitly approved by a human reviewer.
- If an automated change is uncertain (e.g., multiple candidate files match a missing LST token), produce a review note with the candidates and do not commit without human confirmation.

Reference helper files (archived for reference only):
1. `GOG/validation/scripts_archive/generate_patch_mapping.py` → `GOG/validation/patch_mapping.csv` (start here to find recommended actions; archived reference)
2. `GOG/validation/scripts_archive/find_lst_candidates.py` → `GOG/validation/raw/lst_candidates.csv` (missing LST mapping; archived reference)
3. `GOG/validation/scripts_archive/propose_case_fixes.sh` → `GOG/validation/overlay_casefix` (build case-variant overlay logic; archived reference)
4. `GOG/validation/scripts_archive/generate_overlay_from_rows.sh` → `GOG/validation/overlay_data` (collect promoted files if loose copies exist; archived reference)
5. `GOG/validation/scripts_archive/apply_patch_proposal.sh ISSUE-ID OVERLAY_DIR` → scaffolds a branch and commit for review (archived reference)

**Note:** These files are preserved for reference; prefer manual review and curated overlay generation rather than executing archived scripts.

Standard workflow (atomic & reviewable):
- Step 0: Inspect `GOG/validation/raw/` to review baseline audit outputs; a reproduction script is archived at `GOG/validation/scripts_archive/run_full_audit.sh` (archived; reference-only).
- Step 1: Run `python3 GOG/validation/scripts_archive/generate_patch_mapping.py` (archived; reference-only) and open `GOG/validation/patch_mapping.csv` — or regenerate mapping using `python3 scripts/patch/rme-crossref.py` followed by `GOG/validation/scripts_archive/generate_patch_mapping.py` (reference guidance).
- Step 2: Choose a top-priority ISSUE (recommendation: `ISSUE-LST-002` or `ISSUE-CASE-001`).
- Step 3: Use the archived reference helper(s) for that issue as guidance and carefully inspect `GOG/validation/raw/` outputs.
- Step 4: Create an overlay with the minimal set of files to fix the issue and run the validation script.
  - `./scripts/patch/rebirth-validate-data.sh --patched GOG/validation/overlay_data --base GOG/unpatchedfiles --rme third_party/rme/source`
- Step 5: Run `./scripts/dev/dev-check.sh` and `./scripts/dev/dev-verify.sh`.
- Step 6: Use `GOG/validation/scripts_archive/apply_patch_proposal.sh` as a reference to scaffold branch/commit operations; prefer manual or human-supervised commit creation instead of running archived scripts automatically.

Stop conditions (ask for human review):
- If more than one candidate file matches a missing LST token.
- If a fix requires changing engine code (only allow trivial, well-justified changes with tests).
- If a fix requires creating new assets (human must provide or approve content).

Reporting:
- For every PR, include a short `validation/` subfolder that contains the specific raw logs used to validate the change, e.g., `GOG/validation/raw/PR-ISSUE-CASE-001/`.

---

This page is intentionally prescriptive to make automated LLM work auditable and review-friendly. If you want, I can implement ISSUE-CASE-001 as an example PR (create overlay, run checks, prepare PR outline). Approve or pick the issue to start with.
