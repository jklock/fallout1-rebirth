# Branch Consolidation Playbook (2026-02-12)

Plan to land the branch backlog onto `main` with minimal conflicts and clear checkpoints. Default branch is `main`; current working branch is `fix/rme-zero-copy-skip` (ahead 145).

## Pre-flight
- Ensure a clean tree: `git status -sb` should show no changes.
- Update baseline: `git fetch origin` then `git switch main && git merge --ff-only origin/main`.
- Work on a dedicated staging branch: `git switch -c merge/branch-consolidation main`.
- Use project scripts for verification: `./scripts/dev/dev-check.sh` and `./scripts/dev/dev-verify.sh` (no raw cmake/xcodebuild).
- Known conflict hotspots: [src/plib/gnw/gnw.cc](src/plib/gnw/gnw.cc), [src/plib/gnw/grbuf.cc](src/plib/gnw/grbuf.cc), [src/plib/gnw/svga.cc](src/plib/gnw/svga.cc), [src/plib/db/db.cc](src/plib/db/db.cc), [src/plib/db/patchlog.cc](src/plib/db/patchlog.cc), [CMakeLists.txt](CMakeLists.txt), [scripts/patch](scripts/patch), [scripts/dev](scripts/dev), RME assets under [third_party/rme](third_party/rme), and tmp artifacts under [tmp/](tmp/).

## Branch inventory (status from /tmp/branch-summary.txt)
- Ahead-only: patchfix (1), chore/docs/archive-scripts-update (2), fix/rme-remove-win32-branching (20), restart/rme-clean (23), validation/rme-sweep-2026-02-09 (23), backup/port-before-delete-20260212T183738Z (23), fix/rme-zero-copy-skip (145).
- Diverged (main behind/ahead): SDL3, apple-pencil, backup-reword-20260206-195639, feature/apple-rebirth, fix/pencil-edge-scroll-speed, evaera*, korri123*, radozd, zverinapavel*, korri123/patch-1, zverinapavel/touch-control-optimization.
- Merged already: codex/bugfix-ios-polish, codex/feature-patch, upstream.

## Execution order
### Stage 0 — Baseline
- Create staging branch from fresh main (see Pre-flight). Keep a log of actions in `.git-merge-history.txt` if desired.

### Stage 1 — Cherry-pick small, low-risk fixes
Cherry-pick with `git cherry-pick <hash>`; run `./scripts/dev/dev-check.sh` afterward.
- `f4e74d8` from korri123/patch-1 — combatai UB fix.
- `5a812cd` from zverinapavel/touch-control-optimization — movie_lib return type fix.
- `42099fd` and `b82e1c8` from evaera — F-key emulation and iPad mouse cursor support.
- `fd0460c` from korri123 — format string fixes (review dependencies in [src/game/sfxlist.cc](src/game/sfxlist.cc) and related audio paths; skip if it drags voice assets).

### Stage 2 — Doc-only and helper updates (ahead-only)
Merge with `git merge --no-ff <branch>`; resolve doc conflicts only.
- patchfix — patch script updates.
- chore/docs/archive-scripts-update — archive docs update.

### Stage 3 — RME data snapshots (ahead-only, large binaries)
These bring tmp artifacts and RME data; prefer staging in a separate commit each.
- backup/port-before-delete-20260212T183738Z — raw RME pull and tmp captures.
- restart/rme-clean — cleaned snapshot.
- validation/rme-sweep-2026-02-09 — runtime sweep artifacts (patchlog analyses touch [src/plib/gnw/*](src/plib/gnw)).

### Stage 4 — Code-first RME fixes
- fix/rme-remove-win32-branching — POSIX-only cleanup in [src/plib/db](src/plib/db) and [src/plib/gnw](src/plib/gnw); expect db/patchlog conflicts.

### Stage 5 — Input/Apple stacks (diverged)
Prefer cherry-picking targeted commits instead of merging the full branches to avoid binary churn.
- Apple Pencil: from apple-pencil and fix/pencil-edge-scroll-speed, grab the latest Pencil/touch commits that do not reintroduce RME assets; expect touches in [src/int/audio.cc](src/int/audio.cc), [src/game/input](src/game), and docs.
- evaera stacks: if Stage 1 covered `42099fd` and `b82e1c8`, skip merging the full branches unless you need the remaining small input tweaks; conflicts likely in [src/int/audio.cc](src/int/audio.cc) and [src/int/audiof.cc](src/int/audiof.cc).

### Stage 6 — RME patchflow stack
- fix/rme-zero-copy-skip (current branch) — land after prior RME branches to reduce rework. Conflicts expected in [src/game/rme_log.cc](src/game/rme_log.cc), [src/game/rme_selftest.cc](src/game/rme_selftest.cc), [src/game/game.cc](src/game/game.cc), and [CMakeLists.txt](CMakeLists.txt). Verify with `./scripts/dev/dev-verify.sh`.

### Stage 7 — Large or optional branches
Handle last; consider archiving if not needed.
- SDL3 — major platform experiment with binary deltas under [third_party/rme](third_party/rme).
- korri123 (75 commits, voice assets), backup-reword-20260206-195639 (asset-heavy), feature/apple-rebirth (old Pencil stack). Merge only with a clear need; otherwise, leave archived.

## Conflict handling checklist
- For [src/plib/gnw](src/plib/gnw) merges, keep POSIX-only paths and current Apple-only logic; re-run clang-format via `./scripts/dev/dev-format.sh`.
- For [src/plib/db](src/plib/db) and [src/plib/db/patchlog.cc](src/plib/db/patchlog.cc), prefer the POSIX/Apple cleanup from fix/rme-remove-win32-branching and retain new logging added in fix/rme-zero-copy-skip.
- Avoid reintroducing tmp artifacts under [tmp/](tmp/) unless intentionally preserving validation outputs.
- When binary RME assets conflict, prefer the newer sweep artifacts (validation/rme-sweep-2026-02-09) over earlier snapshots.

## Verification after each stage
- `./scripts/dev/dev-check.sh` for format/lint.
- `./scripts/dev/dev-verify.sh` for build + static checks.
- For RME changes, run relevant harness (see [development/RME/validation/README.md](development/RME/validation/README.md)).

## Notes
- Keep main fast-forwardable when possible; avoid rebases on shared branches.
- If `.git-merge-history.txt` is present, append the exact commands and resolutions for traceability.
- If a branch introduces large RME assets without clear value, park it in an archive branch instead of merging.
