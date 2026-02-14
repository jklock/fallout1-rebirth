# Prompt: Scripts And Dialog Domain (End To End)

You are the domain owner for `scripts-dialog`.

## Objective
Validate that critical script execution and dialog flows work without blocker defects.

## Scope
- Script-driven quest/dialog branches
- Save/load continuity for script state
- Blocker script dispatch failures

## Required Context
Read before execution:
- `development/RME/PLAN/domains/04-scripts-dialog.md`
- `development/RME/TODO/domains/04-scripts-dialog.md`
- `development/RME/OUTCOME/domains/04-scripts-dialog.md`
- `development/RME/VALIDATE/domains/04-scripts-dialog.md`

## Hard Constraints
- Use canonical `GOG/patchedfiles` data.
- Define explicit dialog/script test paths before testing.
- Do not report pass without running manual critical-path scenarios.

## Phase 1: Discovery And Baseline
1. Run script reference audit.
2. Create a critical-path checklist (quest/dialog branches) for this run.

Baseline command:
```bash
python3 scripts/test/rme-audit-script-refs.py --patched-dir GOG/patchedfiles --out-dir development/RME/validation/raw
```

## Phase 2: Development Fix Loop
1. Prioritize blocker-level script/dialog issues.
2. Apply minimal fixes and retest specific failing branch immediately.
3. Validate save/load state continuity for each fixed path.

## Phase 3: Testing Loop
1. Execute critical-path checklist end-to-end.
2. Capture pass/fail for each branch.
3. Re-run audit if script mappings changed.

## Phase 4: Validation And Sign-Off
Domain is complete when:
- critical script/dialog branches pass
- no blocker-level script dispatch issues remain
- save/load continuity is confirmed for tested branches

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/04-scripts-dialog.md`
- `development/RME/TODO/domains/04-scripts-dialog.md`
- `development/RME/OUTCOME/domains/04-scripts-dialog.md`
- `development/RME/VALIDATE/domains/04-scripts-dialog.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Checklist used
- Branch results
- Defects fixed
- Remaining blockers and next action
