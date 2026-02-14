# Prompt: Patch Integrity Domain (End To End)

You are the domain owner for `patch-integrity`.

## Objective
Guarantee that patched RME output is complete, validated, and always sourced from canonical `GOG/patchedfiles`.

## Scope
- Canonical source enforcement
- Overlay payload integrity
- DAT patch integrity
- Validation script reliability

## Required Context
Read before execution:
- `development/RME/PLAN/domains/01-patch-integrity.md`
- `development/RME/TODO/domains/01-patch-integrity.md`
- `development/RME/OUTCOME/domains/01-patch-integrity.md`
- `development/RME/VALIDATE/domains/01-patch-integrity.md`

## Hard Constraints
- Use only `GOG/patchedfiles` for runtime/test source data.
- Keep patch logic in `scripts/patch/*` and test logic in `scripts/test/*`.
- Do not commit generated runtime evidence artifacts.

## Phase 1: Discovery And Baseline
1. Confirm canonical source is present and complete.
2. Run integrity baseline commands:
```bash
./scripts/test/rme-ensure-patched-data.sh
./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme
./scripts/patch/rebirth-refresh-validation.sh --unpatched GOG/unpatchedfiles --patched GOG/patchedfiles --rme third_party/rme --out development/RME/validation
```

## Phase 2: Development Fix Loop
1. If any command fails, classify the failure:
- source/payload content issue
- path resolution issue
- validator logic issue
2. Apply minimal targeted fix.
3. Re-run impacted command first, then full baseline set.

## Phase 3: Testing Loop
1. Re-run full baseline command set.
2. Verify no missing/mismatched payload failures remain.
3. Verify canonical preflight exits 0.

## Phase 4: Validation And Sign-Off
Domain is complete when:
- canonical preflight passes
- patch validator passes
- validation refresh completes without errors
- no blocker-level integrity defects remain

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/01-patch-integrity.md`
- `development/RME/TODO/domains/01-patch-integrity.md`
- `development/RME/OUTCOME/domains/01-patch-integrity.md`
- `development/RME/VALIDATE/domains/01-patch-integrity.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Summary of changes
- Commands executed
- Pass/fail per command
- Remaining blockers
- Next action
