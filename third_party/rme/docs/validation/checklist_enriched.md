# Validation Checklist — Enriched

**Last updated:** 2026-02-08
**Author:** GitHub Copilot (Raptor mini (Preview) assistant; evidence produced locally)

This enriched checklist expands each validation claim with: exact reproduction commands, where raw evidence is stored, a short *Fixer Guidance* note, and a suggested verification command for any fix.

---

For each item below you'll find:
- Claim (what we observed)
- Reproduction commands (exact shell commands you can run locally)
- Evidence files (path to saved artifacts in this repo)
- Fixer Guidance (what a fixing agent should do if this claim is a problem)
- Verification (command + expected outcome after a fix)


## 1) Config: `f1_res.ini` changes
- Claim: `SCR_WIDTH`, `SCR_HEIGHT`, `WINDOWED` changed and new `IFACE` and `CLICK_OFFSET` options added.
- Reproduce: diff -u GOG/unpatchedfiles/f1_res.ini GOG/patchedfiles/f1_res.ini
- Evidence: `GOG/validation/configs.md` (section `f1_res.ini`), `GOG/validation/f1_res_excerpt.txt`
- Fixer Guidance: Ensure these changes are intentional and documented. If a config introduces an unsafe default (e.g., logical resolution > 640x480), either add engine-side input validation (preferred) or annotate config with an explicit guard & comment.
- Verification: `grep -nE 'SCR_WIDTH|WINDOWED' GOG/patchedfiles/f1_res.ini` should show the desired values (e.g., `SCR_WIDTH=1280`).
- Priority: Medium


## 2) Config: `fallout.cfg` patch keys & debug reorg
- Claim: `master_patches` and `critter_patches` now set to `data`; debug blocks rearranged.
- Reproduce: diff -u GOG/unpatchedfiles/fallout.cfg GOG/patchedfiles/fallout.cfg
- Evidence: `GOG/validation/configs.md` (section `fallout.cfg`), `GOG/validation/fallout_cfg_excerpt.txt`
- Fixer Guidance: Confirm that patch directory semantics are compatible with existing install scripts. If not, revert or add compatibility code that prefers `data/` but falls back to original locations.
- Verification: `grep -n 'master_patches' GOG/patchedfiles/fallout.cfg` returns `master_patches=data`.
- Priority: Medium


## 3) DAT checksums differ (master.dat / critter.dat)
- Claim: Patched DATs are different (expected — xdelta applied). Full checksums were recorded.
- Reproduce: shasum -a 256 GOG/unpatchedfiles/master.dat GOG/patchedfiles/master.dat GOG/unpatchedfiles/critter.dat GOG/patchedfiles/critter.dat
- Evidence: `GOG/validation/master_*.sha256` and `GOG/validation/critter_*.sha256`
- Fixer Guidance: Decide whether to accept the DAT replacement as authoritative (easy) or to convert the update into a loose-data overlay (preferred when wanting to keep DATs stable). Use `GOG/validation/raw/rme-crossref-patched.csv` and `master_added_rows.csv` to generate a data-only overlay.
- Verification: Either the expected sha256 values match the official xdelta build, or an overlay reproduces the same runtime behavior without replacing DATs.
- Priority: High


## 4) Promotions into DATs (114 to master, 289 to critter)
- Claim: Many RME files are integrated into the patched DATs (not left as loose files).
- Reproduce: wc -l GOG/master_added_files.txt; wc -l GOG/critter_added_files.txt
- Evidence: `GOG/validation/master_added_files.txt`, `GOG/validation/critter_added_files.txt`, `GOG/validation/promotions.md`
- Fixer Guidance: If the project wants a drop-in `data/` overlay, generate `GOG/validation/overlay_data/` containing these promoted files. A reference helper file is available at `GOG/validation/scripts_archive/generate_overlay_from_rows.sh` (archived for reference only); prefer manual extraction or a curated overlay instead of running archived scripts directly. If keeping DAT replacement, ensure the xdelta files used by `rebrek-validate-data.sh` are correct and test on CI.
- Verification: `ls -la GOG/validation/overlay_data` contains files corresponding to the `*_added_rows.csv` lists and running the game with overlay applied (or the validation script) should not report missing resources.
- Priority: High


## 5) LST missing references (117 heuristic misses)
- Claim: 117 LST entries reference assets not found in overlay or base DATs.
- Reproduce: grep -c '^-' GOG/rme_xref_patched/rme-lst-report.md
- Evidence: `GOG/validation/lst_missing_patched.md` (copy of LST report), `GOG/validation/raw/08_lst_missing.md`
- Fixer Guidance: Use the reference helper file `GOG/validation/scripts_archive/find_lst_candidates.py` (archived) or perform case-insensitive searches manually to propose corrections. For each missing asset: either (A) provide the asset in overlay, or (B) update the LST/INT to point to an existing asset after review.
- Verification: rerun `python3 scripts/patch/rme-crossref.py --rme third_party/rme/source --base-dir GOG/patchedfiles --out-dir GOG/rme_xref_patched` and confirm the reported count decreases.
- Priority: High


## 6) Map endianness flagged (9 maps)
- Claim: 9 `.MAP` files are labeled `map_endian=big` (confirmed expected format for the engine reader).
- Reproduce: grep 'map_endian=big' GOG/rme_xref_patched/rme-crossref.csv | wc -l
- Evidence: `GOG/validation/map_endian.md`, `GOG/rme_xref_patched/rme-crossref.csv`
- Fixer Guidance: Usually no change required if engine expects big-endian. Only act if runtime tests show corrupted maps. A helper script to swap endianness can be added if and when required.
- Verification: Use engine logging or a small parse test to read header ints correctly (no error messages and map tile geometry looks correct).
- Priority: Low


## 7) Case-only renames (20 pairs) — dangerous on case-sensitive FS
- Claim: 20 pairs of files/directories differ only by case.
- Reproduce: cat GOG/case_renames.txt; inspect `third_party/rme/docs/validation/case_test_results.txt` for the case-sensitivity test results or refer to the archived helper `GOG/validation/scripts_archive/run_case_test.py` for reproduction guidance (archived reference).
- Evidence: `GOG/case_renames.txt`, `third_party/rme/docs/validation/case_test_results.txt` (detailed proof)
- Fixer Guidance: Resolve by one of:
  - Use canonical case consistent with engine lookups (check LSTs and code to choose case), or
  - Provide both variants in a validation overlay (reference helper at `GOG/validation/scripts_archive/propose_case_fixes.sh` — archived for reference only) for compatibility across FS types.
- Verification: Run the `run_case_test.py` and confirm both names co-exist on a case-sensitive volume or the overlay provides the requested case variant.
- Priority: High


## 8) Validation script passed
- Claim: The overlay + DAT verification script reports `[OK] Validation passed`.
- Reproduce: ./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme/source
- Evidence: `GOG/validation/rebirth_validate.log`
- Fixer Guidance: Use this script as a gate for any proposed changes to patchedfiles or to new overlay artifacts.
- Verification: Re-run the script after changes and confirm `[OK] Validation passed` (or intentionally updated success criteria documented in PR).
- Priority: Medium


## 9) Unified diff artifact
- Claim: Full tree diff saved as `GOG/unpatched_vs_patched.diff` (16 MB, 371k lines).
- Evidence: `GOG/unpatched_vs_patched.diff`
- Fixer Guidance: Use the diff for manual inspection of specific textual changes and to quickly generate patch hunks for small file edits.
- Verification: `wc -l GOG/unpatched_vs_patched.diff` and spot-check important hunks.
- Priority: Low


---

If you want, I can expand this file into a per-file PASS/FAIL JSON (`GOG/validation/raw/audit_result_per_file.json`) enumerating each RME file and the command evidence; that is slower but useful for strict auditability.

---

Notes:
- All fixes should be implemented as small, testable PRs that include verification steps and run `./scripts/dev/dev-check.sh` and `./scripts/dev/dev-verify.sh` locally.
- Use the `GOG/validation/LLM_fix_mapping.md` as your map for action items — it points to helper scripts and includes prioritisation and verification instructions.
