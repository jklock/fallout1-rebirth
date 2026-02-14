# Prompt: RME Master Orchestrator (Domains 02-10, Overnight)

You are the master orchestrator for RME domains `02` through `10`.

## Objective
Finish domains `02-10` in one uninterrupted run, including remediation and validation, so the morning state is fully updated and verified.

## Non-Stop Execution Contract
- Do not stop after first failure.
- Do not pause for status-only updates.
- Continue domain-by-domain until all target domains are complete.
- On any failure: triage, remediate, re-test, and continue.
- Only treat a domain as incomplete when a hard external blocker remains after remediation attempts.

## Hard Constraints
- Use canonical source for all game-data validation: `GOG/patchedfiles`.
- Keep generated evidence local-only.
- Do not mark success when failures are unreviewed.
- Do not skip documentation updates.

## Domain Order (required)
1. `development/RME/PROMPTS/domains/02-maps-runtime.md`
2. `development/RME/PROMPTS/domains/03-critters-proto.md`
3. `development/RME/PROMPTS/domains/04-scripts-dialog.md`
4. `development/RME/PROMPTS/domains/05-audio.md`
5. `development/RME/PROMPTS/domains/06-art-ui-fonts.md`
6. `development/RME/PROMPTS/domains/07-text-localization.md`
7. `development/RME/PROMPTS/domains/08-platform-macos.md`
8. `development/RME/PROMPTS/domains/09-platform-ios.md`
9. `development/RME/PROMPTS/domains/10-release-packaging.md`

## Global Preflight (before domain loop)
1. `./scripts/test/rme-ensure-patched-data.sh`
2. Ensure no stale/parallel validation run is active.
3. Ensure evidence output paths exist under `development/RME/validation/`.

## Per-Domain Loop (execute for every domain in order)
1. Read domain prompt and required domain docs:
- `development/RME/PLAN/domains/<domain>.md`
- `development/RME/TODO/domains/<domain>.md`
- `development/RME/OUTCOME/domains/<domain>.md`
- `development/RME/VALIDATE/domains/<domain>.md`
2. Execute domain baseline commands from that domain prompt.
3. If any command fails:
- classify root cause (`missing asset`, `missing script/proto ref`, `render anomaly`, `engine behavior regression`, `harness/tooling issue`, `platform/env issue`)
- fix one root cause at a time
- rerun smallest impacted command first
- when fixed, rerun full domain command set
- repeat until domain passes or a hard external blocker is proven
4. Update domain docs and `development/RME/TODO/PROGRESS.MD` with:
- UTC timestamp
- commands run
- pass/fail status
- blocker summary
- evidence paths
- exact next action
5. Move to next domain immediately after domain is validated or explicitly marked blocked-with-evidence.

## Domain 02 Special Rule (already triaged hotspots)
- Do not run hotspot repeats by default for `CARAVAN`, `ZDESERT1`, `TEMPLAT1`.
- Use full sweep as default.
- Run hotspot commands only if regression triggers exist:
- map/runtime flow changes
- render/present pipeline changes
- autorun/patchlog harness changes
- full sweep reports one of those maps failing

## Regression Control Across Domains
- If a fix in a later domain can affect an earlier domain, rerun the minimal impacted validation from the earlier domain before final sign-off.
- Keep working set stable: avoid broad unrelated refactors during overnight run.

## Hard Blocker Policy
- If a blocker cannot be fixed in-session (external dependency, unavailable simulator/device, missing credentials/toolchain), do not stop orchestration.
- Continue remaining domains.
- Return to unresolved blockers at the end and attempt once more.
- Record blocker evidence and required follow-up in domain docs and `PROGRESS.MD`.

## Completion Criteria
Complete only when all are true:
- Domains `02-10` executed in order.
- Each domain is either:
- `PASS` with validation evidence, or
- `BLOCKED` with explicit root cause, evidence, and next action.
- No untriaged blocker-level failures remain.
- All required docs are updated for every domain.

## Final Report Format (required)
- Overall status by domain (`02`..`10`): pass/blocked
- Commands executed per domain
- Validation evidence paths
- Blockers that remain (if any) and exact next action
- Confirmation that documentation files were updated
