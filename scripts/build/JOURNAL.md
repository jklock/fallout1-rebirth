# JOURNAL: scripts/build

Last updated (UTC): 2026-02-15

## 2026-02-14
- Updated release orchestration to use `scripts/test/test-rme-ensure-patched-data.sh`.
- Removed repo-local `GOG/` assumptions from release test invocation.
- Added environment-driven game-data selection (`GAME_DATA` / `FALLOUT_GAMEFILES_ROOT`).
- Added compile-time logging toggle plumbing via `F1R_DISABLE_RME_LOGGING` and `.f1r-build.env`.
- Consolidated iOS build flow into `build-ios.sh` with explicit `-test` / `-prod` modes.
- Consolidated macOS build flow into `build-macos.sh` with explicit `-test` / `-prod` modes.
- Moved app data installer from test to build domain: `install-game-data.sh`.
- Removed redundant wrapper scripts: `build-ios-ipa.sh`, `build-ios-simulator.sh`, `build-macos-dmg.sh`, and `build-releases.sh`.

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.
