# Validation Summary

**NOTE:** An enriched summary with step-by-step instructions for fixers is available at `GOG/validation/summary_enriched.md`.

Quick verification of the priority claims you asked to validate:

- Config changes (f1_res.ini, fallout.cfg): PASS — see `GOG/validation/configs.md` and excerpt files.
- DAT checksums (master.dat/critter.dat): PASS — see `GOG/validation/*.sha256`.
- Promotions (master, critter): PASS — `GOG/validation/master_added_files.txt` (114), `GOG/validation/critter_added_files.txt` (289).
- LST missing refs: PASS — `GOG/validation/lst_missing_patched.md` (117 entries).
- MAP endianness: PASS — `GOG/validation/map_endian.md` (9 maps flagged `map_endian=big`).
- Case-only renames: PASS — `GOG/validation/case_test_results.txt` demonstrates case-sensitive vs case-insensitive behavior.
- Full validation script: PASS — `GOG/validation/rebirth_validate.log` contains `[OK] Validation passed`.
- Unified diff artifact: `GOG/unpatched_vs_patched.diff` (16 MB; 371,523 lines).

All artifacts are in `GOG/validation/`. If you'd like, I can now:
1) Expand the checklist into a true "line-by-line" run that executes each command that generated Diff.md and saves the output file-by-file (slow), or
2) Produce CSV mappings (`path,ext,base_source`) for easier querying, or
3) Run a platform test (e.g., copy patched `data/` into a case-sensitive VM or container and run the game to reproduce runtime issues).

Which option should I do next? (I recommend option 1 for full auditability.)
