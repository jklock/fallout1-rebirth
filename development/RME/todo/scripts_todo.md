# RME Scripts Todo (End-to-End)

## Goal
Provide a one-command patch flow for macOS and iOS users that produces patched data ready for the `.app` / `.ipa`.

## Tasks
1. Implement core patcher:
   - `scripts/patch/rebirth-patch-data.sh`
   - Inputs: `--base`, `--rme`, `--out`
   - Steps: validate -> copy -> xdelta -> overlay -> lowercase -> configs -> summary
2. Add cross-reference generator:
   - `scripts/patch/rme-crossref.py`
   - Output: `development/RME/summary/rme-crossref.csv`
   - Output: `development/RME/summary/rme-crossref.md`
3. Implement macOS wrapper:
   - `scripts/patch/rebirth-patch-app.sh`
   - Uses `gameconfig/macos` templates
   - Prints exact copy destination:
     - `/Applications/Fallout 1 Rebirth.app/Contents/Resources/`
4. Implement iOS wrapper:
   - `scripts/patch/rebirth-patch-ipa.sh`
   - Uses `gameconfig/ios` templates
   - Prints Finder destination:
     - `Files > Fallout 1 Rebirth > Documents/`
5. Add dependency checks:
   - `xdelta3`, `python3`, `rsync` (or `cp` fallback)
6. Add verification output:
    - Checksums
    - File counts
    - Output size
    - MAP header sanity check (warn or fail if unexpected)
    - CRLF normalization for .lst/.msg/.txt
7. Add validation reports:
   - `scripts/patch/rebirth-validate-data.sh` should surface crossref warnings
   - LST heuristic report as a non-failing warning
8. Update docs to reference the new scripts.
## Done Criteria
- All three scripts exist and run on macOS.
- Output is a ready-to-copy folder containing patched data + configs.
