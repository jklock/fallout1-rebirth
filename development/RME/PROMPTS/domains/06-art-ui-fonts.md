# Prompt: Art UI Fonts Domain (End To End)

You are the domain owner for `art-ui-fonts`.

## Objective
Ensure rendering, UI assets, and fonts are stable and blocker-free in core gameplay surfaces.

## Scope
- Black-screen/black-region anomalies
- UI surface integrity (inventory, barter, dialog, combat)
- Font readability/layout checks

## Required Context
Read before execution:
- `development/RME/PLAN/domains/06-art-ui-fonts.md`
- `development/RME/TODO/domains/06-art-ui-fonts.md`
- `development/RME/OUTCOME/domains/06-art-ui-fonts.md`
- `development/RME/VALIDATE/domains/06-art-ui-fonts.md`

## Hard Constraints
- Use canonical `GOG/patchedfiles`.
- Do not close issues without map/surface-specific retest.
- Keep runtime evidence local-only.

## Phase 1: Discovery And Baseline
1. Run runtime sweep baseline and review suspicious outputs.

Baseline command:
```bash
python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime
```

## Phase 2: Development Fix Loop
1. Triage highest-impact visual blockers first.
2. Apply targeted fixes.
3. Retest impacted maps/surfaces immediately.

Targeted retest pattern:
```bash
python3 scripts/test/rme-repeat-map.py <MAP> 3 --timeout 120 --out-dir development/RME/validation/runtime
```

## Phase 3: Testing Loop
1. Re-run sweep if core rendering behavior changed.
2. Perform manual UI/font checks on critical surfaces:
- inventory
- barter
- dialog
- combat

## Phase 4: Validation And Sign-Off
Domain is complete when:
- no blocker-level visual anomalies remain
- UI/font checks pass in critical surfaces

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/06-art-ui-fonts.md`
- `development/RME/TODO/domains/06-art-ui-fonts.md`
- `development/RME/OUTCOME/domains/06-art-ui-fonts.md`
- `development/RME/VALIDATE/domains/06-art-ui-fonts.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Baseline anomalies
- Fixes and retests
- UI/font checklist results
- Remaining blockers and next action
