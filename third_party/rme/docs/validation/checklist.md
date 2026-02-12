# Validation Checklist

**NOTE:** An enriched version with additional Fixer Guidance and verification steps is available at `GOG/validation/checklist_enriched.md`. The short checklist below is preserved for quick reference.

This checklist enumerates the key claims from Diff.md and provides the command run and evidence file for each. Each item shows a PASS/FAIL result and the relevant artifact under `GOG/validation/`.

1. Config: `f1_res.ini` updated (SCR_WIDTH, SCR_HEIGHT, WINDOWED, IFACE and CLICK_OFFSET added)
   - Command: `diff -u GOG/unpatchedfiles/f1_res.ini GOG/patchedfiles/f1_res.ini`
   - Evidence: `GOG/validation/configs.md` (section `f1_res.ini`) and `GOG/validation/f1_res_excerpt.txt`
   - Result: PASS

2. Config: `fallout.cfg` updated (master_patches & critter_patches set to `data`, debug restructured)
   - Command: `diff -u GOG/unpatchedfiles/fallout.cfg GOG/patchedfiles/fallout.cfg`
   - Evidence: `GOG/validation/configs.md` (section `fallout.cfg`) and `GOG/validation/fallout_cfg_excerpt.txt`
   - Result: PASS

3. DAT checksums: `master.dat` and `critter.dat` differ between unpatched and patched
   - Command: `shasum -a 256 GOG/*files/*.dat`
   - Evidence: `GOG/validation/master_unpatched.sha256`, `GOG/validation/master_patched.sha256`, `GOG/validation/critter_unpatched.sha256`, `GOG/validation/critter_patched.sha256`
   - Result: PASS (checksums recorded)

4. Promotions: Files were added into `master.dat` and `critter.dat`
   - Command: `wc -l GOG/master_added_files.txt; wc -l GOG/critter_added_files.txt`
   - Evidence: `GOG/validation/master_added_files.txt` (114 entries), `GOG/validation/critter_added_files.txt` (289 entries), `GOG/validation/promotions.md`
   - Result: PASS

5. LST missing references: Heuristic scan found missing LST entries (117)
   - Command: `grep -c '^-' GOG/rme_xref_patched/rme-lst-report.md`
   - Evidence: `GOG/validation/lst_missing_patched.md` (117 entries)
   - Result: PASS

6. Map endianness: 9 MAP files flagged as big-endian
   - Command: `grep -c 'map_endian=big' GOG/rme_xref_patched/rme-crossref.csv`
   - Evidence: `GOG/validation/map_endian.md` (9 entries)
   - Result: PASS

7. Case-only renames: 20 pairs identified; verify behavior on case-sensitive vs case-insensitive
   - Command: `GOG/validation/run_case_test.py` (copies each case pair onto a case-sensitive disk image and into /tmp)
   - Evidence: `GOG/case_renames.txt`; `GOG/validation/case_test_results.txt` (shows both variants co-exist on case-sensitive volume but only one exists on case-insensitive `/tmp`)
   - Result: PASS (demonstrated)

8. Validation script: RME overlay validation passed
   - Command: `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme/source`
   - Evidence: `GOG/validation/rebirth_validate.log` (contains `[OK] Validation passed`)
   - Result: PASS

9. Unified diff artifact generated (very large)
   - Command: `diff -ruN GOG/unpatchedfiles GOG/patchedfiles > GOG/unpatched_vs_patched.diff`
   - Evidence: `GOG/unpatched_vs_patched.diff` (16 MB, 371,523 lines)
   - Result: PASS (artifact available for offline inspection)


---

If you want, I can now:
- Expand this checklist into per-file commands and record each command's raw output into separate files (slow, full "line-by-line" verification), or
- Generate CSVs from `rme-crossref.csv` mapping `path,ext,base_source` for interactive queries.

Tell me which next step you prefer and I'll proceed. (Recommended: produce full per-file verification for high-priority files only.)
