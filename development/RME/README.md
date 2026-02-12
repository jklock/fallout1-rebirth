# RME Integration Documentation

**Last Updated:** 2026-02-07

## Purpose

Documentation and planning materials for the Restoration Mod Engine (RME) integration into Fallout 1 Rebirth. RME provides extended scripting capabilities and mod support.

## Contents

| Directory | Purpose |
|-----------|---------|
| `plan/` | Integration planning documents and approach |
| `summary/` | Summary reports of integration work |
| `todo/` | Outstanding tasks and work items |
| `validation/` | Testing and validation procedures |

## About RME

The Restoration Mod Engine extends Fallout 1 with:
- Additional script opcodes
- Enhanced modding capabilities
- Compatibility with community content
- TeamX Patch 1.3.5 support

## Integration Status

RME integration is **COMPLETED** (Phase 3). See the following for details:
- `third_party/rme/` - RME source code
- `summary/` - Integration summary reports

## Related Files

- `third_party/rme/README.md` - RME library documentation
- `src/int/support/intextra.cc` - Script opcode implementations
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
