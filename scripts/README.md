# scripts

Last updated (UTC): 2026-02-15

Automation entrypoints for build, patching, development checks, and testing.

## Directory Layout
- `scripts/build/`: canonical build scripts (`build-ios.sh`, `build-macos.sh`, installers).
- `scripts/dev/`: developer checks and diagnostics.
- `scripts/patch/`: patch-application scripts only (`patch-rebirth-*`).
- `scripts/test/`: test and validation scripts (`test-*`), including Rebirth validation and RME suites.

## Required Naming
- `build-*` for build scripts.
- `dev-*` for dev scripts.
- `patch-rebirth-*` for patch scripts.
- `test-rebirth-*` for Rebirth validation scripts.
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
- Build macOS (prod): `./scripts/build/build-macos.sh -prod`
- Build iOS (prod): `./scripts/build/build-ios.sh -prod`
- Stage iOS release IPA: `cp build-outputs/iOS/fallout1-rebirth.ipa releases/prod/iOS/fallout1-rebirth.ipa`
- Build macOS (test payload): `./scripts/build/build-macos.sh -test`
- Build iOS (test payload): `./scripts/build/build-ios.sh -test --both`
- RME suite: `python3 scripts/test/rme/suite.py all`
- Compile-time logging toggle: `./scripts/test/test-rebirth-toggle-logging.sh`
- Per-key config gate: `./scripts/test/test-rme-config-compat.sh`
- Template/package alignment gate: `./scripts/test/test-rme-config-packaging.sh`

## Notes
- `scripts/hideall.sh` is the only script that toggles development ignore rules in `.gitignore`.
- Build scripts source `.f1r-build.env` when present (used by `test-rebirth-toggle-logging.sh`).
