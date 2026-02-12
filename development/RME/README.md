# RME (Restoration Mod Enhanced) Integration Documentation

**Last Updated:** 2026-02-08

## Purpose

Documentation and planning materials for integrating the Restoration Mod Enhanced (RME) data payload into Fallout 1 Rebirth. RME is a curated data pack (TeamX patches + restoration content) applied on top of user-supplied Fallout 1 assets.

## Contents

| Directory | Purpose |
|-----------|---------|
| `plan/` | Integration planning documents and approach |
| `summary/` | Summary reports of integration work |
| `todo/` | Outstanding tasks and work items |
| `validation/` | Testing and validation procedures |

## Navigation (what to read)
- Coverage plan: [plan/coverage.md](plan/coverage.md)
- Tasks (step-by-step): [todo/engine_todo.md](todo/engine_todo.md), [todo/game_data_todo.md](todo/game_data_todo.md), [todo/scripts_todo.md](todo/scripts_todo.md), [todo/validation_todo.md](todo/validation_todo.md)
- Validation outputs: [validation/runtime](validation/runtime) (sweep logs, patchlogs, screenshots), [validation/raw](validation/raw) (crossref/LST/hash reports)

## About RME

Restoration Mod Enhanced (RME) bundles:
- TeamX Patch 1.2 / 1.2.1 / 1.3.5
- NPC Mod 3.5 (+ Fix, with optional No Armor variant)
- Restoration Mod 1.0b1
- Restored Good Endings 2.0
- Dialog and assorted fix packs

## Integration Status

Patch pipeline is implemented and validated at the data/script level. In-game visual verification and variant selection (NPC Mod No Armor) are pending. See the following for details:
- `third_party/rme/` - RME payload
- `summary/` - Integration summary reports

## Definition of Done (100% validated & working)
- Data integrity: `rebirth-validate-data.sh` missing=0, mismatched=0; base DAT re-xdelta matches patched hashes.
- Crossref/LST: `08_lst_missing.md` empty; no unresolved references.
- Runtime: runtime_map_sweep.csv includes all maps (72) with zero failures/suspicious; `patchlog_summary.csv` all `suspicious=0`; present-anomalies empty; flaky-map repeats clean.
- Functional: per-mod spot checks in [todo/validation_todo.md](todo/validation_todo.md) pass (dialogs, NPC mod behaviors, restored content, fonts/SFX/art) with no crashes.
- Artifacts archived under `development/RME/validation/` (raw + runtime) with command lines used.

## How to validate (quick path)
- Patch data: `./scripts/patch/rebirth-patch-data.sh --base <unpatched> --out <patched> --rme third_party/rme/source`
- Validate data: `./scripts/patch/rebirth-validate-data.sh --patched <patched> --base <unpatched> --rme third_party/rme/source`
- Runtime sweep (macOS): `./scripts/patch/rme-run-validation.sh` (uses build-macos + default dirs) to produce runtime_map_sweep.* and patchlogs.
- Flaky maps: `TIMEOUT=120 ./scripts/patch/rme-repeat-map.sh CARAVAN 5` (repeat for ZDESERT1/2/3, TEMPLAT1) and confirm analyzers are clean.

## Related Files

- `third_party/rme/README.md` - RME payload documentation
- `scripts/patch/` - Patch pipeline scripts
- `.github/copilot-instructions.md` - Project phases overview

## RME Validation harness (how-to)

Quick start (local):
- Build the app (fast):
  - `./scripts/build/build-macos.sh --build-only`
- Run the orchestrator with your patched files:
  - `./scripts/test/test-rme-patchflow.sh [--autorun-map] [path/to/GOG/patchedfiles]`
- Run autofix dry-run against a failing run:
  - `./scripts/test/rme-autofix.py --workdir <tmp/rme-run-*/work> --iterations 1 --dry-run`

Auto-fix rules and artifacts:
- The engine writes proposals into `<WORKDIR>/fixes/iter-<N>/proposed.diff` and `fix-summary.json`.
- If whitelist candidates are found, `whitelist-additions.txt` is written to the same folder.
- To apply fixes locally, run rme-autofix with `--apply` and only on temporary run directories (enforced).

Approving whitelist additions:
- The engine will never auto-commit to `development/RME/validation/whitelist.txt`.
- When `--apply-whitelist` is requested, a proposed diff is written to `development/RME/fixes-proposed/whitelist-proposed.diff` and a blocking file is created under `development/RME/todo/` describing the proposed change.
- Human reviewers should inspect the proposed diff, run the harness locally, and if acceptable, apply the whitelist update and commit with a descriptive message.

Testing helpers:
- `scripts/test/test-rme-patchflow-autofix.sh` — integration test that runs the orchestrator against a small synthetic failure fixture and validates the autofix dry-run and apply flows.
- `scripts/test/rme-validate-ci.sh` — quick local validation (build-only + a short adulterated dry-run with the included synthetic fixture).

If you find a run that requires a policy decision (e.g., enabling `RME_CASE_FALLBACK`), the harness will create a blocking file under `development/RME/todo/` explaining why human approval is required. Follow that file's guidance.

## See Also

- [Features Documentation](../../docs/features.md)
- [Architecture Overview](../../docs/architecture.md)
