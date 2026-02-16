# JOURNAL: scripts/patch

Last updated (UTC): 2026-02-15

## 2026-02-14
- Rewired validation refresh helper calls to `scripts/test/test-rme-*.py` tools.
- Removed `GOG/...` temp/output assumptions from refresh flow.
- Added temp crossref outputs under the selected `--out` directory.
- Renamed patch scripts to `patch-rebirth-*` naming.
- Moved non-patching Rebirth scripts (`refresh-validation`, `validate-data`, `toggle-logging`) to `scripts/test/` as `test-rebirth-*`.

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.
