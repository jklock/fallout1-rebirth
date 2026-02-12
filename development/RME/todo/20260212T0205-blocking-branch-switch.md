# Blocking: Cannot switch to `restart/rme-clean` due to interrupted cherry-pick and repo state

**timestamp:** 2026-02-12T02:05:00Z

**summary:** During the attempt to port recent work from `fix/rme-zero-copy-skip` to `restart/rme-clean` I started a `git cherry-pick` of recent task commits (T001–T004), which produced merge conflicts. I resolved the conflicts in several files, but `git cherry-pick --continue` did not complete successfully (pre-commit hooks / editor invocation blocked the commit). After attempting to clear the cherry-pick state some git metadata (e.g., `COMMIT_MSG`) left the repository in an inconsistent state that currently prevents a clean `git checkout restart/rme-clean`.

**what I attempted:**
- Created a new port branch: `port/fix-to-restart-<timestamp>` from `restart/rme-clean`.
- `git cherry-pick -x` of the following commits (oldest → newest):
  - `3620a14` — task(RME/T001): add RME_WORKING_DIR override and test
  - `c1b3909` — task(RME/T001): add RME logging implementation and include for working-dir test
  - `59eb01a` — task(RME/T002): add RME in-process self-test runner
  - `cf1d3a6` — task(RME/T003): hook selftest into startup
  - `6e59677` — task(RME/T004): add RME patchflow orchestrator script
  - `de479c3` — task(RME/T001): update progress & working-dir test
- The first cherry-pick (3620a14) created conflicts in:
  - `src/plib/gnw/winmain.cc` (content conflict)
  - `development/RME/todo/progress.md` (add/add conflict)
  - `development/RME/plan/TASKS.md` (add/add conflict)
- I resolved the conflicts by merging content and saved the resolved files to `tmp/merge-backup-<timestamp>/`.
- `git cherry-pick --continue` attempted to open an editor or run pre-commit hooks and stalled; `CHERRY_PICK_HEAD` and `COMMIT_MSG` remnants were present.
- I attempted to abort the cherry-pick and clean up, but the repo remained in a state where `git checkout restart/rme-clean` did not switch branches.

**current repo facts (on host):**
- `HEAD` currently points at `port/fix-to-restart-20260212T020519Z` (we created this helper branch).
- Backed up the resolved files to: `tmp/merge-backup-20260212T020519Z/` (files: `TASKS.md`, `progress.md`, `winmain.cc`).
- The cherry-pick is partially applied and `CHERRY_PICK_HEAD` present earlier; I removed some helper files but the repository still doesn't allow a clean branch switch.

**requested human action / decisions (choose one):**
- OPTION A (recommended): Allow me to force-reset the working branch to `restart/rme-clean` and re-apply the commits non-interactively (using `git cherry-pick -n` + manual commits) — I will preserve backups and create a `backup/port-before-recover-<timestamp>` branch first.
- OPTION B (conservative): You (human) inspect the local working directory and confirm it's safe for me to run `git reset --hard restart/rme-clean` to clear state (I will not proceed without confirmation).
- OPTION C: If you prefer, I can stop and hand-off instructions to you on the exact git commands to run locally to recover (I will produce the precise commands and the paths to the saved backups).

**repro steps for humans (if you want to reproduce / recover):**
1. Inspect current branch and status: `git status --porcelain --branch` (note conflicting files if any).  
2. Backup current branch: `git branch backup/port-before-recover-<timestamp>`  
3. Optionally check current cherry-pick state: look for `.git/CHERRY_PICK_HEAD` and `.git/COMMIT_MSG`  
4. If you approve destructive recovery: `git reset --hard restart/rme-clean` (this will discard uncommitted changes — ensure backups exist)  
5. Reapply commits (one-by-one) using non-interactive cherry-picks: `git cherry-pick -x -n <sha>` then `git add` resolved files from `tmp/merge-backup-<timestamp>/`, run `./scripts/dev/dev-format.sh && ./scripts/dev/dev-check.sh`, and `git commit -m "<original message> (ported)"` (use `--no-verify` if pre-commit hooks block)  

**artifacts / backups I created:**
- `tmp/merge-backup-20260212T020519Z/` — resolved file copies (safe to restore)

**my recommendation:**
- Proceed with OPTION A: I will create a local safety branch and perform the non-interactive reapply of the six commits in order, running formatting/lint checks before each commit. If any conflicts occur, I will stop and create a blocking todo with the conflict details for human resolution.

**If you'd like me to proceed with OPTION A, reply with `proceed` — I will carry on and report back.**


---

This blocking issue was created automatically while attempting to port RME task commits from `fix/rme-zero-copy-skip` to `restart/rme-clean`.
