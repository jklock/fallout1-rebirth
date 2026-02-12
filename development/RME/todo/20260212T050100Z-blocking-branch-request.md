# Blocking: Manual branch recovery required for porting commits

**timestamp:** 2026-02-12T05:01:00Z

**summary:** A prior automated attempt to rebase/cherry-pick commits across branches encountered conflicts and left the repository in a state that blocks a simple branch switch. This requires a human to run careful branch-recovery steps. See existing detailed report: `20260212T0205-blocking-branch-switch.md`.

**recommended human action (non-automated):**
1. Inspect current state and backups:
   - `git status --porcelain --branch`
   - Review `tmp/merge-backup-20260212T020519Z/` for preserved resolved files (TASKS.md, progress.md, winmain.cc)
2. Create a safe backup branch:
   - `git branch backup/port-before-recover-$(date -u +%Y%m%dT%H%M%SZ)`
3. If you agree to force-reset and reapply, run:
   - `git fetch origin` (ensure up-to-date)
   - `git reset --hard restart/rme-clean`
   - For each commit to port (order matters):
       - `git cherry-pick -x -n <sha>`
       - If conflicts, copy resolved files from `tmp/merge-backup-20260212T020519Z/` into working tree and `git add` them
       - `./scripts/dev/dev-format.sh && ./scripts/dev/dev-check.sh`
       - `git commit -m "<original message> (ported)"`
4. Push or open a PR only after verifying all checks.

**If you prefer not to proceed with destructive recovery, reply with `inspect` and an operator will provide interactive guidance.**

**Note:** Automation agents will not perform branch creation or destructive git operations without explicit human instruction.
