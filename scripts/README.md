# scripts

Last updated (UTC): 2026-02-14

Automation entrypoints for build, patching, development checks, and testing.

## Directory Layout
- `scripts/build/`: build and packaging scripts.
- `scripts/dev/`: developer checks and diagnostics.
- `scripts/patch/`: patch application and validation-refresh orchestration.
- `scripts/test/`: all test and validation scripts (`test-*`).

## Required Naming
- `build-*` for build scripts.
- `dev-*` for dev scripts.
- `rebirth-*` for patch scripts.
- `test-*` for test scripts.

## Data Path Policy
- Do not depend on repo-local game data folders.
- Use user-provided paths via script flags and/or environment variables.
- Common variables:
  - `GAME_DATA`: patched data directory (`master.dat`, `critter.dat`, `data/`).
  - `FALLOUT_GAMEFILES_ROOT`: root containing `patchedfiles/` and optionally `unpatchedfiles/`.

## Typical Flows
- Build check: `./scripts/dev/dev-check.sh`
- Full verify: `./scripts/dev/dev-verify.sh`
- macOS test: `./scripts/test/test-macos.sh`
- iOS simulator test: `./scripts/test/test-ios-simulator.sh`
- RME coverage run: `./scripts/test/test-rme-full-coverage.sh`
- RME final end-to-end run: `./scripts/test/test-rme-end-to-end.sh`
- Compile-time logging toggle: `./scripts/patch/rebirth-toggle-logging.sh`

## Notes
- `scripts/dev/dev-toggle-dev-files.sh` is the only script that toggles development ignore rules in `.gitignore`.
- Build scripts source `.f1r-build.env` when present (used by `rebirth-toggle-logging.sh`).
