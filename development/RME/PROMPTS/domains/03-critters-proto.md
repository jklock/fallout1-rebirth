# Prompt: Critters And Proto Domain (End To End)

You are the domain owner for `critters-proto`.

## Objective
Eliminate blocker-level proto/script index linkage issues that affect runtime stability.

## Scope
- Proto/script reference audit
- Impacted map retests
- Critter/item runtime linkage validation

## Required Context
Read before execution:
- `development/RME/PLAN/domains/03-critters-proto.md`
- `development/RME/TODO/domains/03-critters-proto.md`
- `development/RME/OUTCOME/domains/03-critters-proto.md`
- `development/RME/VALIDATE/domains/03-critters-proto.md`

## Hard Constraints
- Use canonical `GOG/patchedfiles`.
- Tie every fix to a reproducible failing reference or runtime symptom.
- Keep test artifacts local-only.

## Phase 1: Discovery And Baseline
Run baseline audit:
```bash
./scripts/test/rme-ensure-patched-data.sh
python3 scripts/test/rme-audit-script-refs.py --patched-dir GOG/patchedfiles --out-dir development/RME/validation/raw
```

## Phase 2: Development Fix Loop
1. Build a list of unresolved references from audit output.
2. Map each reference to impacted runtime map(s).
3. Apply targeted fix.
4. Re-run audit and impacted map tests.

Impacted retest pattern:
```bash
python3 scripts/test/rme-repeat-map.py <MAP> 3 --timeout 120 --out-dir development/RME/validation/runtime
```

## Phase 3: Testing Loop
1. Re-run audit until blocker references are eliminated.
2. Re-run impacted maps until stable.

## Phase 4: Validation And Sign-Off
Domain is complete when:
- no blocker-level unresolved proto/script references remain
- impacted runtime maps re-pass after fixes

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/03-critters-proto.md`
- `development/RME/TODO/domains/03-critters-proto.md`
- `development/RME/OUTCOME/domains/03-critters-proto.md`
- `development/RME/VALIDATE/domains/03-critters-proto.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Audit baseline summary
- Fixes applied
- Retest evidence summary
- Remaining blockers and next action
