# Prompt: Audio Domain (End To End)

You are the domain owner for `audio`.

## Objective
Verify that representative audio behavior (SFX/music/ambient) works across target scenarios.

## Scope
- Audio asset availability
- Trigger behavior in representative maps
- macOS and iOS smoke audio checks

## Required Context
Read before execution:
- `development/RME/PLAN/domains/05-audio.md`
- `development/RME/TODO/domains/05-audio.md`
- `development/RME/OUTCOME/domains/05-audio.md`
- `development/RME/VALIDATE/domains/05-audio.md`

## Hard Constraints
- Use canonical `GOG/patchedfiles`.
- Build an explicit audio scenario matrix for this run.
- Do not mark pass without scenario-level playback checks.

## Phase 1: Discovery And Baseline
1. Confirm canonical source preflight.
2. Define scenario matrix (map + expected SFX/music cues).

Baseline commands:
```bash
./scripts/test/rme-ensure-patched-data.sh
./scripts/test/test-macos.sh
```

## Phase 2: Development Fix Loop
1. If audio fails, identify root cause category:
- missing asset
- path/case mismatch
- platform playback issue
2. Apply targeted fix.
3. Re-run only affected scenarios first.

## Phase 3: Testing Loop
1. Execute audio scenario matrix on macOS.
2. Execute available audio checks on iOS simulator.

iOS command (if environment available):
```bash
./scripts/test/test-ios-simulator.sh
```

## Phase 4: Validation And Sign-Off
Domain is complete when:
- scenario matrix passes for blocker-level audio requirements
- no unresolved blocker-level audio defects remain

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/05-audio.md`
- `development/RME/TODO/domains/05-audio.md`
- `development/RME/OUTCOME/domains/05-audio.md`
- `development/RME/VALIDATE/domains/05-audio.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Audio scenario matrix and results
- Defects fixed
- Remaining blockers and next action
