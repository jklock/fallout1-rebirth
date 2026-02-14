# Scripts And Dialog Domain Execution Prompt

## Purpose
Verify script-driven gameplay and dialog paths remain functional end-to-end.

## Scope
Quest scripts, dialog branches, save/load state continuity.

## Required Inputs
- Repository root: \
- Canonical game data source: \
- Domain plan: \
- Domain todo: \
- Domain outcome: \
- Domain validation: \

## Hard Constraints
- Use \ for all runtime/test flows.
- Keep \ patch-only and \ test-only.
- Do not commit generated runtime evidence/logs/screenshots/patchlogs.
- If runtime data is required in app/simulator target, run \ first.

## Execution Instructions
1. Read domain docs listed above and summarize current domain blockers in 3-6 lines.
2. Run baseline preflight:
   - \
3. Execute the domain development loop:
- Define a minimal critical-path dialog/script checklist before running tests.\n- Fix blocking script/dialog regressions first.\n- Retest exact failing branch after each fix.
4. Execute the domain test loop:
- Run script-ref audit baseline:\n  - \>>> Indexing DATs: master.dat, critter.dat
>>> Scanning overlay: /Volumes/Storage/GitHub/fallout1-rebirth/GOG/patchedfiles/data
>>> Reading scripts.lst: /Volumes/Storage/GitHub/fallout1-rebirth/GOG/patchedfiles/data/scripts/scripts.lst
>>> Scanning PROs: overlay=99
>>> Scanning PROs: dat-only=4299
>>> Scanning MAPs: overlay=10
>>> Scanning MAPs: dat-only=62\n- Run manual gameplay checks for critical dialog/quest branches (record exact branches tested).
5. Execute domain validation checks:
- Validate quest/dialog branch completion and state persistence across save/load.\n- Confirm no blocker script dispatch failures in tested scenarios.
6. If any check fails, fix the smallest root cause first, then re-run only impacted checks, then re-run full domain checks.
7. Stop only when all domain done criteria are satisfied.

## Required Output Format
- Domain summary: what changed and why.
- Commands executed (exact).
- Pass/fail status per command.
- Blockers remaining (if any).
- Next action.

## Documentation Update Requirements
After the run, update all four domain docs:
- \
- \
- \
- \
Also update \ with timestamped status.

## Done Criteria
- Critical dialog and script paths pass.\n- No unresolved blocker-level script/dialog defects remain.
