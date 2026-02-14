# Prompt: Maps Runtime Domain (End To End)

You are the domain owner for `maps-runtime`.

## Objective
Reach stable map runtime coverage with full sweep completion while keeping hotspot checks regression-only.

## Scope
- Hotspot maps (`CARAVAN`, `ZDESERT1`, `TEMPLAT1`) are already triaged and should not be re-run by default
- Full 72-map runtime sweep
- Patchlog/analyzer triage to zero blocker state

## Required Context
Read before execution:
- `development/RME/PLAN/domains/02-maps-runtime.md`
- `development/RME/TODO/domains/02-maps-runtime.md`
- `development/RME/OUTCOME/domains/02-maps-runtime.md`
- `development/RME/VALIDATE/domains/02-maps-runtime.md`

## Hard Constraints
- All runs must use canonical `GOG/patchedfiles` source.
- Keep generated runtime artifacts local-only.
- Do not mark success if failures are merely unreviewed.

## Phase 1: Discovery And Baseline
1. Run canonical source preflight.
2. Skip hotspot repeats unless a regression trigger exists.

Commands:
```bash
./scripts/test/rme-ensure-patched-data.sh
python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime
```

Regression-only hotspot command set:
```bash
python3 scripts/test/rme-repeat-map.py CARAVAN 1 --timeout 25 --out-dir development/RME/validation/runtime
python3 scripts/test/rme-repeat-map.py ZDESERT1 1 --timeout 25 --out-dir development/RME/validation/runtime
python3 scripts/test/rme-repeat-map.py TEMPLAT1 1 --timeout 25 --out-dir development/RME/validation/runtime
```

## Phase 2: Development Fix Loop
1. For each failing map, classify cause:
- missing asset
- missing script/proto ref
- render anomaly
- engine behavior regression
2. Fix one root cause at a time.
3. Re-run only impacted map first.

## Phase 3: Testing Loop
Run full sweep as the default validation path:
```bash
python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime
python3 scripts/dev/patchlog_analyze.py development/RME/validation/runtime/patchlogs/*.patchlog.txt
```

## Phase 4: Validation And Sign-Off
Domain is complete when:
- full sweep covers 72 target maps
- no untriaged blocker-level map failures remain
- hotspot maps are only re-run when triggered by a regression signal

## Required Documentation Updates
Update all:
- `development/RME/PLAN/domains/02-maps-runtime.md`
- `development/RME/TODO/domains/02-maps-runtime.md`
- `development/RME/OUTCOME/domains/02-maps-runtime.md`
- `development/RME/VALIDATE/domains/02-maps-runtime.md`
- `development/RME/TODO/PROGRESS.MD`

## Required Final Report Format
- Hotspot status (`CARAVAN`, `ZDESERT1`, `TEMPLAT1`)
- Full sweep status
- Analyzer status
- Remaining blockers and next action
