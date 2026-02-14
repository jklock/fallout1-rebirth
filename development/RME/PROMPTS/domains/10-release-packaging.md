# Prompt: Release Packaging Domain (End To End)

You are the domain owner for `release-packaging`.

## Objective
Validate release pipeline readiness after all domain gates are green.

## Scope
- End-to-end release script execution
- artifact production sanity
- regression detection in release path

## Required Context
Read before execution:
- `development/RME/PLAN/domains/10-release-packaging.md`
- `development/RME/TODO/domains/10-release-packaging.md`
- `development/RME/OUTCOME/domains/10-release-packaging.md`
- `development/RME/VALIDATE/domains/10-release-packaging.md`

## Hard Constraints
- Do not run release gate before core domains are green.
- Keep canonical source enforcement active.
- Do not mark pass without verifying release artifacts exist.

## Phase 1: Discovery And Baseline
1. Confirm upstream domain statuses are green.
2. Run release pipeline baseline.

Baseline command:
```bash
./scripts/build/build-releases.sh
```

## Phase 2: Development Fix Loop
1. If pipeline fails, classify by stage:
- preflight
- test stage
- build stage
- artifact collection stage
2. Apply minimal fix.
3. Re-run full release pipeline.

## Phase 3: Testing Loop
1. Confirm release pipeline exits 0.
2. Confirm expected artifacts are present in output/release locations.

## Phase 4: Validation And Sign-Off
Domain is complete when:
- release pipeline passes end-to-end
- artifacts are produced and discoverable
- no blocker-level packaging defects remain

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/10-release-packaging.md`
- `development/RME/TODO/domains/10-release-packaging.md`
- `development/RME/OUTCOME/domains/10-release-packaging.md`
- `development/RME/VALIDATE/domains/10-release-packaging.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Pipeline status
- Artifact verification status
- Defects fixed
- Remaining blockers and next action
