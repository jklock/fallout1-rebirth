# JOURNAL: scripts/dev

Last updated (UTC): 2026-02-15

## 2026-02-14
- Moved RME-specific analyzer/extractor scripts out of `scripts/dev` and into `scripts/test` with `test-rme-*` names.
- Moved development ignore toggler back to root as `scripts/hideall.sh`.
- Added temp-dir env overrides to eliminate fixed scratch path requirements.

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.
