# Maps Runtime Domain Execution Prompt

## Purpose
Reach full map runtime coverage and stabilize map-load regressions.

## Scope
Hotspot repeats, full sweep coverage, map runtime triage.

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
- Prioritize hotspot map fixes first (CARAVAN, ZDESERT1, TEMPLAT1).\n- Fix map-specific data/script issues before broad reruns.\n- Keep remediation tied to reproducible failing maps.
4. Execute the domain test loop:
- Run hotspot repeats:\n  - \Run 1/10 for CARAVAN
Run 2/10 for CARAVAN
Run 3/10 for CARAVAN
Run 4/10 for CARAVAN
Run 5/10 for CARAVAN
Run 6/10 for CARAVAN
Run 7/10 for CARAVAN
Run 8/10 for CARAVAN
Run 9/10 for CARAVAN
Run 10/10 for CARAVAN
[FULL_LOAD_FAIL] CARAVAN: map_load rc!=0 or missing; display all black; dude not placed; post_click missing\n  - \Install the patched data (GOG/patchedfiles) into the app bundle and retry.\n  - \Install the patched data (GOG/patchedfiles) into the app bundle and retry.\n- Run full sweep:\n  - \
5. Execute domain validation checks:
- Run analyzer:\n  - \Analyzing development/RME/validation/runtime/patchlogs/BRODEAD.MAP.patchlog.txt
No suspicious GNW_SHOW_RECT surf_pre>0 && surf_post==0 found\n- Verify required patchlog markers for repeated maps:\n  - load_end rc=0\n  - display non-black\n  - valid dude tile\n  - valid post-click tile
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
- 10/10 pass for each hotspot map.\n- Full sweep covers 72 targets with no untriaged critical failures.\n- Analyzer results are triaged to zero blockers.
