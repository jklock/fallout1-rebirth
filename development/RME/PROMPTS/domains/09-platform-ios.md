# Prompt: Platform iOS Domain (End To End)

You are the domain owner for `platform-ios`.

## Objective
Pass iOS simulator functional smoke gates with canonical patched data staging.

## Scope
- iOS headless test flow
- iOS simulator interactive flow
- simulator container data copy correctness

## Required Context
Read before execution:
- `development/RME/PLAN/domains/09-platform-ios.md`
- `development/RME/TODO/domains/09-platform-ios.md`
- `development/RME/OUTCOME/domains/09-platform-ios.md`
- `development/RME/VALIDATE/domains/09-platform-ios.md`

## Hard Constraints
- Use canonical `GOG/patchedfiles` for all iOS test data staging.
- Do not bypass container data copy validation.
- Do not mark pass without both headless and simulator results.

## Phase 1: Discovery And Baseline
Run baseline iOS tests:
```bash
./scripts/test/test-ios-headless.sh --build
./scripts/test/test-ios-simulator.sh
```

## Phase 2: Development Fix Loop
1. If failures occur, classify by build/install/launch/data-copy categories.
2. Apply targeted fix.
3. Re-run impacted command first.

## Phase 3: Testing Loop
1. Re-run headless test.
2. Re-run simulator test.
3. Confirm canonical data staged to simulator container and app launches.

## Phase 4: Validation And Sign-Off
Domain is complete when:
- iOS headless test passes
- iOS simulator smoke passes
- no blocker-level iOS defects remain

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/09-platform-ios.md`
- `development/RME/TODO/domains/09-platform-ios.md`
- `development/RME/OUTCOME/domains/09-platform-ios.md`
- `development/RME/VALIDATE/domains/09-platform-ios.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Headless results
- Simulator results
- Data-copy validation status
- Remaining blockers and next action
