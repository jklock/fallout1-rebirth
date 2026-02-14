# Rebirth Audit Guidelines

Last updated: 2026-02-14

## Objective

Provide a repeatable audit process to verify code quality, patch integrity, build correctness, SDL3 integration, runtime configuration behavior, and release readiness.

## Scope

- `scripts/` (build/dev/test/patch automation)
- `src/` (engine/source code)
- `third_party/rme/` patch payload integration points
- Build definitions (`CMakeLists.txt`, toolchains, packaging scripts)
- SDL3 usage and migration correctness
- Game configuration templates and runtime key usage (`gameconfig/`, `fallout.cfg`, `f1_res.ini`)

## Audit Rules

1. Prefer reproducible command outputs over manual claims.
2. Record every check command and result in `docs/audit/results.md`.
3. Fix actionable failures immediately and rerun the same check.
4. Separate known legacy upstream TODO/FIXME annotations from new regressions.
5. Do not mark runtime/UI coverage as complete without produced artifacts (logs/screenshots).

## Audit Checklist

### A. Repository and Script Integrity

- Validate script executability and shebangs for `scripts/**/*.sh` and `scripts/**/*.py`.
- Run syntax checks:
  - `bash -n` on shell scripts
  - `python3 -m py_compile` on Python scripts
- Verify script paths referenced by docs exist.
- Flag stale references or renamed script drift.

### B. Source-Code Quality

- Run `./scripts/dev/dev-check.sh` and `./scripts/dev/dev-verify.sh` (capture full logs).
- Scan for unresolved conflict markers and accidental placeholder code.
- Scan for TODO/FIXME/STUB markers and classify:
  - `legacy_upstream_annotation`
  - `new_regression`
  - `requires_followup`
- Ensure no newly introduced stubs/TODOs in Rebirth-specific files.

### C. Build Process

- Validate macOS configure/build flow.
- Validate iOS configure flow (and simulator/headless if available).
- Check consistency between:
  - `CMakeLists.txt`
  - build scripts in `scripts/build/`
  - docs in `docs/building.md`
- Verify build entrypoints (`build-macos.sh`, `build-ios.sh`) and packaging paths are coherent and referenced paths exist.

### D. Patch Flow and Data Validation

- Verify patch scripts run with expected arguments:
  - `patch-rebirth-data.sh`
  - `test-rebirth-validate-data.sh`
  - `test-rebirth-refresh-validation.sh`
- Run checksum/overlay validation commands when patched data is available.
- Confirm patchflow helper scripts and autofix scripts parse and execute.

### E. SDL3 Compliance

- Confirm SDL3 includes (`<SDL3/SDL.h>`) and `SDL_EVENT_*` usage in input/event paths.
- Confirm renderer configuration (`SDL_CreateRenderer`, `SDL_SetRenderVSync`).
- Confirm touch/mouse coordinate conversion uses SDL3 logical/window APIs.
- Confirm audio stream path uses SDL3 stream API.

### F. Configuration Correctness

- Cross-check runtime config reads in code against documented keys.
- Verify `gameconfig/{macos,ios}` templates include keys actively read by runtime.
- Validate docs and template defaults match behavior (vsync/fps/input offsets/pencil settings).

### G. End-to-End Runtime Proof

- Execute RME runtime/coverage scripts where environment allows:
  - `test-rme-end-to-end.sh`
  - `test-rme-runtime-sweep.py`
  - `test-rme-log-sweep.sh`
- Require per-map runtime artifacts:
  - patchlogs
  - screenshot evidence (`scr*.bmp` or copied map screenshots)
  - run summaries
- If blocked (missing data/runtime prerequisites), record exact blockers and incomplete scope.

## Result Files

- `docs/audit/results.md`: command-by-command audit log and statuses.
- `docs/audit/findings.md`: actionable findings with severity and remediation state.
- `docs/audit/remediation.md`: fixes applied and rerun results.
- `docs/audit/e2e.md`: runtime test execution evidence and screenshot index.
