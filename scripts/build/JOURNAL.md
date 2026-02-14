# JOURNAL: scripts/build

Last updated (UTC): 2026-02-14

## 2026-02-14
- Updated release orchestration to use `scripts/test/test-rme-ensure-patched-data.sh`.
- Removed repo-local `GOG/` assumptions from release test invocation.
- Added environment-driven game-data selection (`GAME_DATA` / `FALLOUT_GAMEFILES_ROOT`).
- Added compile-time logging toggle plumbing via `F1R_DISABLE_RME_LOGGING` and `.f1r-build.env`.
