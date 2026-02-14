# JOURNAL: scripts/patch

Last updated (UTC): 2026-02-14

## 2026-02-14
- Rewired validation refresh helper calls to `scripts/test/test-rme-*.py` tools.
- Removed `GOG/...` temp/output assumptions from refresh flow.
- Added temp crossref outputs under the selected `--out` directory.
- Renamed patch scripts to `patch-rebirth-*` naming.
- Moved non-patching Rebirth scripts (`refresh-validation`, `validate-data`, `toggle-logging`) to `scripts/test/` as `test-rebirth-*`.
