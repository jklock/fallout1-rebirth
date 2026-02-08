# LLM Fix Mapping — Fallout 1 Rebirth (Patch Fix Work)
**Context story:** See `GOG/validation/NARRATIVE.md` for a cohesive narrative that explains the problem, investigations, and recommended fixes.
Purpose: provide a compact, actionable mapping document that another LLM (or human) can use to perform and verify fixes to the patched files. This document maps observed issues to concrete steps, helper scripts, verification commands, and PR guidance.

---

## Repository context
- Local repo: this fork (`/Volumes/Storage/GitHub/fallout1-rebirth`).
- Relevant directories:
  - `GOG/unpatchedfiles/` — original GOG data baseline
  - `GOG/patchedfiles/` — patched package to be analyzed/fixed
  - `GOG/validation/` — validation artifacts. Helper files are archived at `GOG/validation/scripts_archive/` and preserved as non-executable references (do not run them directly).
  - `third_party/rme/source` — RME reference data used for cross-referencing
- Important validation artifacts:
  - `GOG/unpatched_vs_patched.diff` (full unified diff)
  - `GOG/rme_xref_patched/rme-crossref.csv` and `GOG/rme_xref_unpatched/rme-crossref.csv`
  - `GOG/validation/raw/*` — raw per-command outputs (use these when uncertain)

---

## Priority issue list (canonical action map)

Issue IDs below are suggested labels for PRs and commit messages. Each entry includes: symptom, root cause, recommended fix plan, verification steps, scripts/resources to use, and estimated effort.

### ISSUE-CASE-001 — Case-only renames (HIGH)
- Symptom: Files/dirs exist only with different case between patched and unpatched sets (20 pairs). Causes runtime missing assets on case-sensitive systems.
- Root cause: Packager normalized some filenames to lower-case while LSTs or code still reference original case.
- Fix Plan (preferred): For each pair:
  1. Determine canonical case by checking references (LSTs, src references). Command: `grep -Ri "<FILENAME_BASENAME>" -n GOG/patchedfiles/ GOG/unpatchedfiles/`.
  2. If LSTs or scripts reference the uppercase variant, ensure the uppercase file exists in the package; else keep patched case and update references.
  3. Implement fix as an overlay: copy the existing file to the canonical-name variant under `GOG/validation/overlay_casefix/data/...` so both cases are available for testing and review.
- Reference files: `GOG/validation/scripts_archive/propose_case_fixes.sh` (archived; creates the overlay copies logic, reference-only), `GOG/validation/scripts_archive/run_case_test.py` (archived run logic; reference-only).
- Verification:
  - Run `python3 GOG/validation/run_case_test.py` and inspect `GOG/validation/case_test_results.txt` to confirm the overlay provides the missing case variant.
  - Add a small unit: `find GOG/validation/overlay_casefix -iname "<BASENAME>"` should show both variants if you decided to keep both.
- Estimated effort: 30–90 minutes depending on resolution strategy per pair.

### ISSUE-LST-002 — Missing LST references (HIGH)
- Symptom: LST files reference assets not present in overlay or DATs (117 reported items).
- Root cause: Packager omitted some assets or renamed them (possibly case-only); or LSTs point to removed/outdated names.
- Fix Plan:
  1. Run `python3 GOG/validation/scripts_archive/find_lst_candidates.py` (archived, reference-only) or perform the same case-insensitive searches manually (this will:
     - parse `GOG/rme_xref_patched/rme-lst-report.md` and
     - perform case-insensitive searches for candidate matches in `GOG/patchedfiles` and `GOG/unpatchedfiles`) 
  2. For each missing reference, if a candidate exists, propose either: (A) rename/copy the existing candidate to the exact name referenced by the LST, or (B) update the LST to point to the existing candidate (lower risk: prefer copying to preserve compatibility with other RME references).
  3. For assets that do not exist anywhere, obtain the asset from upstream or recreate it if possible (human check required).
- Verification: rerun `python3 scripts/patch/rme-crossref.py --rme third_party/rme/source --base-dir GOG/patchedfiles --out-dir GOG/rme_xref_patched` and confirm reduced missing count.
- Reference file: `GOG/validation/scripts_archive/find_lst_candidates.py` (archived; produces `GOG/validation/raw/lst_candidates.csv`)
- Estimated effort: 1–3 hours depending on candidate matches and whether assets must be recreated.

### ISSUE-DAT-005 — DAT promotions vs data-only packaging (HIGH)
- Symptom: RME payload is embedded into patched `master.dat` and `critter.dat`. This is not a simple data-only drop-in, and can surprise consumers.
- Root cause: The packager opted to integrate files into DATs instead of shipping them as loose files.
- Fix Plan (two options):
  - Option A (Preferred; non-invasive): Convert patch into a **data-only overlay**.
    1. Use the reference helper file `GOG/validation/scripts_archive/generate_overlay_from_rows.sh` (archived, reference-only) to copy promoted files from `GOG/patchedfiles/data` into `GOG/validation/overlay_data/`, or copy files manually from `master_added_rows.csv`/`critter_added_rows.csv`.
    2. Test overlay-only by running the validation and by manually launching the engine with the overlay directory in the data path.
    3. Create PR adding `overlay_data/` (or a canonical trimmed subset) as the patch files.
  - Option B (Accept DAT replacement): Document the patched DAT checksums and treat DATs as authoritative (less flexible).
- Verification: `./scripts/patch/rebirth-validate-data.sh --patched GOG/validation/overlay_data --base GOG/unpatchedfiles --rme third_party/rme/source` should pass or demonstrate parity with the full patched set.
- Estimated effort: 1–4 hours depending on how many files require special handling (scripts/prototypes may reference internal DAT offsets).

### ISSUE-CONFIG-003 — Risky config defaults & docs (MEDIUM)
- Symptom: `f1_res.ini` defaults to 1280x960 windowed (safe), but contains warning about logical resolution limits.
- Root cause: Unclear documentation and risk of user misconfiguration.
- Fix Plan: Document the change explicitly in `docs/` and add comments in `f1_res.ini`; if feasible add simple engine clamping to prevent unsupported resolutions.
- Verification: `grep -n 'WINDOWED' GOG/patchedfiles/f1_res.ini` and run a quick engine start to ensure no crash.
- Estimated effort: 30–90 minutes.

### ISSUE-MAP-004 — Map endianness flags (LOW)
- Symptom: 9 maps explicitly flagged `map_endian=big`.
- Recommendation: No immediate change if engine handles big-endian maps; add parsing test to ensure correct geometry.
- Verification: unit test that reads map header integers successfully.
- Estimated effort: 30–60 minutes.

### ISSUE-CI-006 — Add validation tests to PR checks (LOW)
- Symptom: Local validation was manual; we should gate PRs.
- Fix Plan: Add a GitHub Actions job that runs `GOG/validation/run_full_audit.sh` and `./scripts/patch/rebirth-validate-data.sh` on push/PR.
- Verification: New job executes and returns green on PRs.
- Estimated effort: 1–2 hours.

---

## Helper files (archived for reference)
The following helper files are preserved as archived reference files in `GOG/validation/scripts_archive/`. They are intended as code references only; do not run them directly from the repository. Instead, use them to guide manual, reviewed fixes or to re-implement the necessary logic in your own tooling.
- `GOG/validation/scripts_archive/generate_overlay_from_rows.sh` — copies rows from `*_added_rows.csv` into `GOG/validation/overlay_data/` preserving relative path (reference only).
- `GOG/validation/scripts_archive/propose_case_fixes.sh` — builds `GOG/validation/overlay_casefix/` adding missing case variants by copying existing variant into the missing name (reference only).
- `GOG/validation/scripts_archive/find_lst_candidates.py` — heuristically matches missing LST references to candidates in patched/unpatched files and outputs `GOG/validation/raw/lst_candidates.csv` (reference only).
- `GOG/validation/scripts_archive/generate_patch_mapping.py` — consolidates `rme-crossref` CSV into `GOG/validation/patch_mapping.csv` with fields: `path,ext,size,sha256,base_source,patched_found,patched_path,recommended_action,priority` (reference only).

---

## PR & Branch guidelines for an LLM
- Branch naming: `fix/<issue-id>-short-description` (e.g., `fix/ISSUE-CASE-001-casefix-intrface`)
- Commit style: one logical change per commit, good messages like `ISSUE-CASE-001: add uppercase copies for hr_alltlk.frm to satisfy LST references`.
- Pre-commit checks: run `./scripts/dev/dev-check.sh` then `./scripts/dev/dev-verify.sh` locally.
- PR message: include: problem description, files changed, verification steps run, and a link to artifacts (`GOG/validation/*`).

---

## Example LLM workflow (concrete)
1. Checkout `main` or a working branch and create `fix/ISSUE-CASE-001`.
2. Run `GOG/validation/run_full_audit.sh` to ensure baseline.
3. Use the archived reference `GOG/validation/scripts_archive/propose_case_fixes.sh` as guidance to build `GOG/validation/overlay_casefix/` manually; prefer manual review and curated overlays.
4. Review the overlay files; commit only the minimal fixes that match LST/code usage.
5. Run `./scripts/patch/rebirth-validate-data.sh` against new `GOG/validation/overlay_casefix` and `GOG/unpatchedfiles` to confirm no regressions.
6. Run `./scripts/dev/dev-check.sh` and `./scripts/dev/dev-verify.sh`.
7. Push and open PR with clear verification evidence.

---

If you want, I can start implementing ISSUE-CASE-001 as a trial PR (I will generate the overlay, run verification, and open the PR). Which issue should I take first? (Recommended: ISSUE-LST-002 or ISSUE-CASE-001.)
