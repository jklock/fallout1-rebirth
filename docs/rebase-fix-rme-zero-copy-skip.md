# Rebase Record: fix/rme-zero-copy-skip

## Scope
- Rebased branch `fix/rme-zero-copy-skip` onto `main`.
- Resolved all conflicts and completed the rebase.

## Conflicts and Resolutions
- Logging/selftest: src/game/rme_log.cc, src/game/rme_log.h, src/game/rme_selftest.cc, src/game/game.cc
  - Kept enhanced RME logging helpers and config sync.
  - Kept safer tolower casts and relative message paths.
  - Kept namespace-qualified shutdown and existing selftest robustness.
- RME docs: development/RME/plan/TASKS.md, development/RME/todo/progress.md
  - Kept completed task/progress history.
  - Dropped the stash note from the conflicting branch.
- Generated artifacts: tmp/fallout1-rebirth-check/CMakeFiles/* (C/CXX ABI bins, CMakeConfigureLog.yaml)
  - Accepted deletion per branch intent to ignore/untrack generated runtime artifacts.

## Decisions
- Followed POSIX-only direction for DB/patchlog paths in this branch.
- Preserved RME logging and selftest improvements from the zero-copy stack.
- Did not re-add generated tmp CMake artifacts.

## Current State
- Branch: fix/rme-zero-copy-skip (rebased on main).
- Working tree: clean except untracked .git-merge-history.txt (remove if desired).
- Large historical RME validation artifacts remain unchanged (patchlogs, screenshots, BMPs).

## Suggested Next Steps
1) Optionally remove .git-merge-history.txt for a pristine tree.
2) Run: ./scripts/dev/dev-check.sh and ./scripts/dev/dev-verify.sh.
3) Decide whether to keep or purge legacy RME artifact commits (history rewrite needed to purge).
