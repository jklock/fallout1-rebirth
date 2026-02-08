# Patch Validation Narrative — GOG `unpatchedfiles` → `patchedfiles`

**Date:** 2026-02-08
**Author:** GitHub Copilot (Raptor mini (Preview))

This document tells the full, chronological story of what we found comparing `GOG/unpatchedfiles` to `GOG/patchedfiles`, the analysis steps taken, the evidence produced, and a clear, prioritized roadmap for fixes. It's written to be shareable with humans and automated agents (LLMs) doing the fixing work.

---

## Executive summary ✅
- The patched package is not a pure "data-only" drop-in: it **replaces `master.dat` and `critter.dat`** and also provides a larger `data/` overlay. This is the fundamental cause of many observed differences. (Evidence: `GOG/validation/*.sha256`, `GOG/validation/promotions.md`)
- Promotions: **114** files were added to `master.dat`; **289** were added to `critter.dat`. Many are `*.pro` (prototypes) and `*.frm` frames. (Evidence: `GOG/master_added_files.txt`, `GOG/critter_added_files.txt`)
- LSTs: heuristic scanning found **117** LST references that did not resolve to present assets. This can cause missing UI and script behaviors in-game. (Evidence: `GOG/rme_xref_patched/rme-lst-report.md`, `GOG/validation/raw/lst_candidates.csv`)
- Case-only renames: **20** pairs exist where the same basename differs only by case — these are problematic on case-sensitive filesystems. (Evidence: `GOG/case_renames.txt`, `GOG/validation/case_test_results.txt`)
- Map endianness: 9 `.MAP` files flagged `map_endian=big`. Engine reads maps big-endian — these files match expectation. (Evidence: `GOG/validation/map_endian.md`)

---

## How this investigation proceeded (chronology & core commands)
1. Quick tree scan
   - Command: `diff -qr GOG/unpatchedfiles GOG/patchedfiles`
   - Purpose: find which files differ and which are unique. (Saved: `GOG/validation/raw/01_diff_qr.txt`)

2. Inspect config diffs
   - Commands: `diff -u GOG/unpatchedfiles/f1_res.ini GOG/patchedfiles/f1_res.ini` and `diff -u GOG/unpatchedfiles/fallout.cfg GOG/patchedfiles/fallout.cfg`
   - Findings: resolution defaults, windowed mode, `IFACE`/`CLICK_OFFSET` options, and `master_patches/critter_patches` keys changed. (Saved: `GOG/validation/configs.md`)

3. Full unified diff (archival)
   - Command: `diff -ruN GOG/unpatchedfiles GOG/patchedfiles > GOG/unpatched_vs_patched.diff`
   - Note: Very large (16 MB, 371,523 lines). Use offline review or a pager. (File: `GOG/unpatched_vs_patched.diff`)

4. Cross-reference RME payload to DAT contents
   - Command: `python3 scripts/patch/rme-crossref.py --base-dir <dir> --rme third_party/rme/source --out-dir <out>` (run for both unpatched and patched)
   - Purpose: determine which RME files are present in DATs vs loose files and produce the LST report and flags (map endianness). (Files: `GOG/rme_xref_patched/rme-crossref.csv`, `GOG/rme_xref_patched/rme-lst-report.md`)

5. Validate the RME + DAT updates
   - Command: `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme/source`
   - Result: **Validation passed** (DAT xdelta checksums, CRLF normalization). (File: `GOG/validation/rebirth_validate.log`)

6. Produce enumerations and helper artifacts
   - Files produced: `GOG/master_added_files.txt` (114), `GOG/critter_added_files.txt` (289), `GOG/case_renames.txt`, `GOG/validation/patch_mapping.csv` (consolidated mapping and recommendations), and raw logs under `GOG/validation/raw/`.

7. Case-sensitivity test
   - Method: created a case-sensitive sparseimage mount and copied paired case files to show co-existence vs case-insensitive overwrite.
   - Evidence: `GOG/validation/case_test_results.txt` demonstrates both variants coexist on a case-sensitive volume but only one variant appears on case-insensitive `/tmp` (macOS default). This proves case-only renames are real runtime issues on certain platforms.

---

## Findings (detailed) — what, why it matters, evidence, and action

### 1) Patched DAT replacement (master.dat & critter.dat)
- What: The patched package replaces `master.dat` and `critter.dat` with versions that include many RME files (xdelta application verified).
- Why it matters: Consumers that expect a simple data overlay will not get the same behavior if they only copy loose `data/` files — many assets are now inside DATs and not available as loose files.
- Evidence: `GOG/validation/master_patched.sha256`, `GOG/validation/master_unpatched.sha256`, `GOG/validation/critter_patched.sha256`, `GOG/validation/critter_unpatched.sha256` and `GOG/validation/rebirth_validate.log`.
- Action: Decide policy — accept DAT replacement (document checksums) or provide a data-only overlay by extracting promoted files into `GOG/validation/overlay_data/` (reference helper `GOG/validation/scripts_archive/generate_overlay_from_rows.sh` archived for guidance; prefer manual extraction or curated overlays).
- Verification: Re-run `./scripts/patch/rebirth-validate-data.sh` with chosen overlay or DATs.


### 2) Promotions into DATs (114 master / 289 critter)
- What: Several prototype and frame files are integrated into DATs. Master additions are dominated by `*.pro` (92 of 114); critter additions dominated by `*.frm`/`FR0..FR5` sets.
- Why it matters: Prototypes typically change game logic; frames affect animations. Packaging choice affects how to deliver fixes.
- Evidence: `GOG/validation/raw/master_added_rows.csv`, `GOG/validation/raw/critter_added_rows.csv`, `GOG/validation/promotions_enriched.md`.
- Action: Extract these files into a data overlay if prefer non-DAT changes; otherwise document DAT usage and checksum provenance.


### 3) LST missing references (117 heuristic misses)
- What: LST entries point to filenames that were not found in either the patched overlay or the DAT crossref results.
- Why it matters: Missing UI and script assets will manifest as runtime missing assets or script failures.
- Evidence: `GOG/rme_xref_patched/rme-lst-report.md`, `GOG/validation/raw/lst_candidates.csv` (candidate matches where available).
- Action: For each missing LST token, either add the asset (overlay) or update the LST/INT references to match existing assets. Use the archived reference `GOG/validation/scripts_archive/find_lst_candidates.py` (archived; reference-only) or perform manual case-insensitive searches to find potential candidates. Keep ambiguous cases for human review.
- Verification: Re-run `python3 scripts/patch/rme-crossref.py --rme third_party/rme/source --base-dir GOG/patchedfiles --out-dir GOG/rme_xref_patched` and confirm the missing count decreases.


### 4) Case-only renames (20 pairs)
- What: Pairs like `HR_ALLTLK.FRM` <-> `hr_alltlk.frm` exist; directories like `MAPS` <-> `maps` differ by case.
- Why it matters: On case-sensitive filesystems, lookups with the wrong case will fail. On macOS default case-insensitive volumes issues may be hidden until deployed to case-sensitive environments.
- Evidence: `GOG/case_renames.txt`, `GOG/validation/case_test_results.txt` (case mount test showing co-existence vs overwrite).
- Action: Normalize to canonical case (review LSTs and code to determine canonical), or include both case variants in an overlay for compatibility and simplicity (reference helper: `GOG/validation/scripts_archive/propose_case_fixes.sh` — archived for reference).


### 5) Map endianness (9 maps flagged `map_endian=big`)
- What: A small number of `.MAP` files were flagged as big-endian by the crossref script.
- Why it matters: Engine expects big-endian reads for maps; if maps were little-endian it'd cause corruption. These flagged files are consistent with engine expectations.
- Evidence: `GOG/validation/map_endian.md` (list of map files).
- Action: Add a lightweight parse test or engine load test to confirm maps render correctly.


### 6) Config changes (`f1_res.ini`, `fallout.cfg`)
- What: Defaults changed to prefer `WINDOWED=1`, `SCR_WIDTH=1280`, `SCR_HEIGHT=960`; `master_patches` and `critter_patches` are pointed to `data`; additional `IFACE` and `CLICK_OFFSET` options added.
- Why it matters: Changes affect runtime behavior (windowing, input calibration, search paths). Some settings include warnings about logical resolution limits (engine expects logical 640×480).
- Evidence: `GOG/validation/configs.md` and excerpt files.
- Action: Document config changes and add engine-side guards or notes in docs; verify tests run with new defaults.

---

## Actionable roadmap (prioritized)
1. ISSUE-LST-002 — Fix missing LST references (High priority)
   - Run: `python3 GOG/validation/scripts_archive/find_lst_candidates.py` (archived; reference-only) and inspect `GOG/validation/raw/lst_candidates.csv`.
   - For each candidate: copy (overlay) or update LSTs; if multiple candidates, ask for human review.
   - Verify: run `scripts/patch/rme-crossref.py` and confirm fewer missing references.

2. ISSUE-CASE-001 — Resolve case-only renames (High priority)
   - Use the archived reference `GOG/validation/scripts_archive/propose_case_fixes.sh` as guidance to generate an overlay at `GOG/validation/overlay_casefix` (archived; reference-only); prefer manual review before committing.
   - Verify: test the overlay on a case-sensitive mount and run `./scripts/patch/rebirth-validate-data.sh`.

3. ISSUE-DAT-005 — Decide DAT vs data-only strategy (High priority)
   - Option A (preferred): Extract promoted files and create `GOG/validation/overlay_data` using the archived helper `GOG/validation/scripts_archive/generate_overlay_from_rows.sh` (archived; reference-only), or extract manually.
   - Option B: Accept DAT replacement and document checksums.
   - Verify: run validation script and playtest critical flows.

4. ISSUE-CONFIG-003 — Document and guard config defaults (Medium)
   - Add docs and engine clamping as needed.

5. ISSUE-MAP-004 & ISSUE-CI-006 — Add map parsing tests and CI gates (Low)

---

## How another LLM should use this story (concrete workflow)
1. Read `GOG/validation/NARRATIVE.md` (this file) and `GOG/validation/LLM_INSTRUCTIONS.md` (strict rules).
2. Run `GOG/validation/run_full_audit.sh` to reproduce the baseline raw outputs under `GOG/validation/raw/`.
3. Inspect `GOG/validation/patch_mapping.csv` and `GOG/validation/raw/lst_candidates.csv` to identify urgent, automatable fixes.
4. Use the archived references `GOG/validation/scripts_archive/propose_case_fixes.sh` and `GOG/validation/scripts_archive/generate_overlay_from_rows.sh` (archived; reference-only) as guidance to build overlays for case renames and promoted files with loose candidates; prefer manual or reviewed overlay construction.
5. Use `GOG/validation/scripts_archive/apply_patch_proposal.sh ISSUE-ID OVERLAY_DIR` as a reference to scaffold branch/commit actions (archived; reference-only). Add verification logs under `GOG/validation/raw/PR-<ISSUE-ID>/` before opening PR.

---

## Evidence & key artifacts (index)
- `GOG/unpatched_vs_patched.diff` — full unified diff (16 MB). Use for manual review.
- `GOG/rme_xref_patched/rme-crossref.csv` — crossref mapping for patched set.
- `GOG/rme_xref_patched/rme-lst-report.md` — missing LST report.
- `GOG/master_added_files.txt`, `GOG/critter_added_files.txt` — raw lists of promoted files.
- `GOG/case_renames.txt` — case-only rename pairs.
- `GOG/validation/*` and `GOG/validation/raw/*` — raw logs and verification artifacts (`*.sha256`, `rebirth_validate.log`, `case_test_results.txt`, `lst_candidates.csv`, `patch_mapping.csv`).

---

## Appendices
- Appendix A — quick commands (copy/paste):
```bash
# baseline audits
GOG/validation/run_full_audit.sh
# rme crossref (recompute)
python3 scripts/patch/rme-crossref.py --rme third_party/rme/source --base-dir GOG/patchedfiles --out-dir GOG/rme_xref_patched
# validation script
./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme/source
# prepare overlay from promoted rows
GOG/validation/scripts_archive/generate_overlay_from_rows.sh GOG/validation/overlay_data  # archived reference
# propose case fixes
GOG/validation/scripts_archive/propose_case_fixes.sh GOG/validation/overlay_casefix  # archived reference
# generate lst candidates
python3 GOG/validation/scripts_archive/find_lst_candidates.py  # archived reference
``` 

- Appendix B — sample PR details (use in `apply_patch_proposal.sh`):
  - Branch: `fix/ISSUE-LST-002-fix-intrface-lst`
  - Commit message: `ISSUE-LST-002: add missing actionh.frm referenced by ART/INTRFACE/INTRFACE.LST` 
  - PR body: include `GOG/validation/raw/` logs and `GOG/validation/` verification artifacts.

---

If you want, I can: (A) start `ISSUE-LST-002` and prepare an overlay PR with candidate fixes, or (B) start `ISSUE-CASE-001` and open a PR with case-variant overlays and verification logs. Which should I start? (Recommendation: ISSUE-LST-002.)
