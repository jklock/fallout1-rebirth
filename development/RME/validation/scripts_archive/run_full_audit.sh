#!/usr/bin/env bash
set -euo pipefail
OUTDIR=GOG/validation/raw
mkdir -p "$OUTDIR"

echo "1) Quick tree diff (diff -qr)" > "$OUTDIR/01_diff_qr.txt"
diff -qr GOG/unpatchedfiles GOG/patchedfiles >> "$OUTDIR/01_diff_qr.txt" || true

echo "2) Copy existing unified diff (already generated)" > "$OUTDIR/02_unpatched_vs_patched_diff_info.txt"
ls -lh GOG/unpatched_vs_patched.diff >> "$OUTDIR/02_unpatched_vs_patched_diff_info.txt" || true
cp GOG/unpatched_vs_patched.diff "$OUTDIR/unpatched_vs_patched.diff" || true

echo "3) Config diffs" > "$OUTDIR/03_configs_diff.txt"
diff -u GOG/unpatchedfiles/f1_res.ini GOG/patchedfiles/f1_res.ini >> "$OUTDIR/03_configs_diff.txt" || true

diff -u GOG/unpatchedfiles/fallout.cfg GOG/patchedfiles/fallout.cfg >> "$OUTDIR/03_configs_diff.txt" || true

echo "4) DAT checksums" > "$OUTDIR/04_dat_shasums.txt"
shasum -a 256 GOG/unpatchedfiles/master.dat GOG/unpatchedfiles/critter.dat GOG/patchedfiles/master.dat GOG/patchedfiles/critter.dat >> "$OUTDIR/04_dat_shasums.txt"

echo "5) Copy rme-crossref CSVs (patched/unpatched)" > "$OUTDIR/05_rme_crossref_copy.txt"
cp GOG/rme_xref_unpatched/rme-crossref.csv "$OUTDIR/rme-crossref-unpatched.csv"
cp GOG/rme_xref_patched/rme-crossref.csv "$OUTDIR/rme-crossref-patched.csv"

echo "6) RME crossref counts" > "$OUTDIR/06_rme_crossref_counts.txt"
awk -F, '$5==""{c++} END{print "unpatched: new files (base empty)=",c+0}' "$OUTDIR/rme-crossref-unpatched.csv" >> "$OUTDIR/06_rme_crossref_counts.txt" || true
awk -F, '$5==""{c++} END{print "patched: new files (base empty)=",c+0}' "$OUTDIR/rme-crossref-patched.csv" >> "$OUTDIR/06_rme_crossref_counts.txt" || true
awk -F, '$5=="master.dat"{c++} END{print "patched: master.dat override count=",c+0}' "$OUTDIR/rme-crossref-patched.csv" >> "$OUTDIR/06_rme_crossref_counts.txt" || true
awk -F, '$5=="critter.dat"{c++} END{print "patched: critter.dat override count=",c+0}' "$OUTDIR/rme-crossref-patched.csv" >> "$OUTDIR/06_rme_crossref_counts.txt" || true

echo "7) Extract map_endian=big lines" > "$OUTDIR/07_map_endian.txt"
grep 'map_endian=big' "$OUTDIR/rme-crossref-patched.csv" > "$OUTDIR/07_map_endian.txt" || true

echo "8) LST missing references" > "$OUTDIR/08_lst_missing.txt"
cp GOG/rme_xref_patched/rme-lst-report.md "$OUTDIR/08_lst_missing.md" || true

echo "9) Promotions crossref rows" > "$OUTDIR/09_promotions_crossref.txt"
# master
if [ -f GOG/master_added_files.txt ]; then
  grep -iF -f GOG/master_added_files.txt "$OUTDIR/rme-crossref-patched.csv" > "$OUTDIR/master_added_rows.csv" || true
  echo "master_added_rows.csv: " $(wc -l < "$OUTDIR/master_added_rows.csv") >> "$OUTDIR/09_promotions_crossref.txt"
fi
# critter
if [ -f GOG/critter_added_files.txt ]; then
  grep -iF -f GOG/critter_added_files.txt "$OUTDIR/rme-crossref-patched.csv" > "$OUTDIR/critter_added_rows.csv" || true
  echo "critter_added_rows.csv: " $(wc -l < "$OUTDIR/critter_added_rows.csv") >> "$OUTDIR/09_promotions_crossref.txt"
fi

echo "10) Case renames and case test evidence" > "$OUTDIR/10_case_renames.txt"
cp GOG/case_renames.txt "$OUTDIR/case_renames.txt" || true
cp GOG/validation/case_test_results.txt "$OUTDIR/case_test_results.txt" || true

echo "11) Validation script log (already run)" > "$OUTDIR/11_validation_script.txt"
cp GOG/validation/rebirth_validate.log "$OUTDIR/rebirth_validate.log" || true

echo "Full audit run complete. Raw logs are in $OUTDIR." > "$OUTDIR/_run_complete_notice.txt"
