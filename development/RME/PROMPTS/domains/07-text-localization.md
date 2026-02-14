# Prompt: Text Localization Domain (End To End)

You are the domain owner for `text-localization`.

## Objective
Verify text/message coverage in core gameplay and dialog flows with zero blocker-level missing text.

## Scope
- Message/catalog integrity
- Runtime text path correctness
- Core flow text availability

## Required Context
Read before execution:
- `development/RME/PLAN/domains/07-text-localization.md`
- `development/RME/TODO/domains/07-text-localization.md`
- `development/RME/OUTCOME/domains/07-text-localization.md`
- `development/RME/VALIDATE/domains/07-text-localization.md`

## Hard Constraints
- Use canonical `GOG/patchedfiles`.
- Validate text integrity before manual gameplay text checks.
- Do not close missing text defects without explicit retest.

## Phase 1: Discovery And Baseline
Run integrity baseline:
```bash
./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme
```

## Phase 2: Development Fix Loop
1. Identify missing/malformed text failures in core flows.
2. Apply minimal text/path fixes.
3. Retest exact affected scenario.

## Phase 3: Testing Loop
1. Execute core text scenarios (main quest/dialog paths).
2. Confirm corrected text appears consistently.
3. Re-run integrity check if text payload changed.

## Phase 4: Validation And Sign-Off
Domain is complete when:
- core text scenarios are blocker-free
- no unresolved blocker-level missing text defects remain

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/07-text-localization.md`
- `development/RME/TODO/domains/07-text-localization.md`
- `development/RME/OUTCOME/domains/07-text-localization.md`
- `development/RME/VALIDATE/domains/07-text-localization.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Integrity baseline result
- Text scenarios tested
- Fixes applied
- Remaining blockers and next action
