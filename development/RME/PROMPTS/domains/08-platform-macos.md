# Prompt: Platform macOS Domain (End To End)

You are the domain owner for `platform-macos`.

## Objective
Pass the macOS functional gate with automated checks plus manual gameplay validation.

## Scope
- macOS build/test integrity
- App bundle runtime readiness
- Manual gameplay gate checklist

## Required Context
Read before execution:
- `development/RME/PLAN/domains/08-platform-macos.md`
- `development/RME/TODO/domains/08-platform-macos.md`
- `development/RME/OUTCOME/domains/08-platform-macos.md`
- `development/RME/VALIDATE/domains/08-platform-macos.md`

## Hard Constraints
- Use canonical `GOG/patchedfiles`.
- Ensure app bundle resources are canonical before gameplay checks.
- Do not mark pass without manual checklist completion.

## Phase 1: Discovery And Baseline
Run baseline automation:
```bash
./scripts/test/rme-ensure-patched-data.sh --target-app "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
./scripts/test/test-macos-headless.sh
./scripts/test/test-macos.sh
```

## Phase 2: Development Fix Loop
1. If failures occur, classify by build/runtime/manual categories.
2. Apply minimal targeted fix.
3. Re-run impacted automated test first.

## Phase 3: Testing Loop
1. Re-run automated macOS tests.
2. Execute manual gameplay checklist:
- new game
- travel
- combat
- companion recruit
- inventory/equip
- dialog branch
- save/load
- 30+ minute stability

## Phase 4: Validation And Sign-Off
Domain is complete when:
- automated macOS tests pass
- manual gameplay checklist passes
- no blocker-level macOS defects remain

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/08-platform-macos.md`
- `development/RME/TODO/domains/08-platform-macos.md`
- `development/RME/OUTCOME/domains/08-platform-macos.md`
- `development/RME/VALIDATE/domains/08-platform-macos.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Automated test results
- Manual checklist results
- Defects fixed
- Remaining blockers and next action
