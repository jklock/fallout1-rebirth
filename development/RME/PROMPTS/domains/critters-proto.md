# Critters And Proto Domain Execution Prompt

## Purpose
Resolve critter/proto/script reference issues that can break runtime behavior.

## Scope
Proto integrity, script index linkage, critter/item runtime references.

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
- Inspect unresolved proto/script references from audit output.\n- Fix mapping/index issues and re-run only impacted map checks first.\n- Validate fixes do not introduce new domain regressions.
4. Execute the domain test loop:
- Run audit:\n  - \>>> Indexing DATs: master.dat, critter.dat
>>> Scanning overlay: /Volumes/Storage/GitHub/fallout1-rebirth/GOG/patchedfiles/data
>>> Reading scripts.lst: /Volumes/Storage/GitHub/fallout1-rebirth/GOG/patchedfiles/data/scripts/scripts.lst
>>> Scanning PROs: overlay=99
>>> Scanning PROs: dat-only=4299
>>> Scanning MAPs: overlay=10
>>> Scanning MAPs: dat-only=62\n- Run targeted map retests for impacted maps:\n  - \
5. Execute domain validation checks:
- Validate unresolved references are closed or intentionally accepted with rationale.\n- Confirm impacted map retests pass after fixes.
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
- No blocker-level unresolved proto/script references remain.\n- Impacted maps retested and passing.
