# Scripts Reference

Current script map for `scripts/`.

## Principles

- Build scripts create artifacts.
- Test scripts validate existing artifacts and should not compile binaries.
- Patch scripts generate patched data payloads.

## Top-Level Structure

| Area | Path | Purpose |
|------|------|---------|
| Build | `scripts/build/` | Compile/package artifacts |
| Dev | `scripts/dev/` | Format/check/verify workflows |
| Patch | `scripts/patch/` | Rebirth patch application |
| Test | `scripts/test/` | Runtime, validation, and RME audit tests |
| Toggle | `scripts/hideall.sh` | Local gitignore toggle helper |

## Build Scripts

### `scripts/build/build-macos.sh`

Single macOS build entrypoint.

```bash
./scripts/build/build-macos.sh -prod
./scripts/build/build-macos.sh -test --game-data /path/to/patchedfiles
```

Key options:

- Modes: `-prod`, `-test`
- Env: `BUILD_DIR`, `BUILD_TYPE`, `JOBS`, `CLEAN`, `GAME_DATA`, `FALLOUT_GAMEFILES_ROOT`

### `scripts/build/build-ios.sh`

Single iOS build entrypoint for device/simulator.

```bash
./scripts/build/build-ios.sh -prod --device
./scripts/build/build-ios.sh -prod --simulator
./scripts/build/build-ios.sh -test --both --game-data /path/to/patchedfiles
```

Key options:

- Modes: `-prod`, `-test`
- Targets: `--device`, `--simulator`, `--both`
- Env: `BUILD_DIR_DEVICE`, `BUILD_DIR_SIM`, `BUILD_TYPE`, `JOBS`, `CLEAN`, `GAME_DATA`

Notes:

- Device builds produce IPA output via CPack in `build-outputs/iOS/`.
- `-test` embeds patched data/config into the app payload.

### `scripts/build/install-game-data.sh`

Installs game data into an existing macOS app bundle.

```bash
./scripts/build/install-game-data.sh --source /path/to/patchedfiles --target "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
```

## Dev Scripts

### `scripts/dev/dev-format.sh`

```bash
./scripts/dev/dev-format.sh
./scripts/dev/dev-format.sh --check
```

### `scripts/dev/dev-check.sh`

Runs pre-build checks without compiling:

- Runs `dev-format`
- Verifies formatting
- Runs `cppcheck` (if installed)
- Validates project file sanity

```bash
./scripts/dev/dev-check.sh
```

### `scripts/dev/dev-verify.sh`

Verifies an existing build artifact (no configure/build).

```bash
./scripts/dev/dev-verify.sh --build-dir build-macos
./scripts/dev/dev-verify.sh --app "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"
```

### `scripts/dev/dev-clean.sh`

```bash
./scripts/dev/dev-clean.sh
```

## Patch Scripts

### `scripts/patch/patch-rebirth-data.sh`

Core patch pipeline for DAT + overlay output.

```bash
./scripts/patch/patch-rebirth-data.sh --base /path/to/FalloutData --out /path/to/Fallout1-RME
```

### `scripts/patch/patch-rebirth-app.sh`

macOS wrapper around core patch flow.

```bash
./scripts/patch/patch-rebirth-app.sh --base /path/to/FalloutData --out /path/to/Fallout1-RME
```

### `scripts/patch/patch-rebirth-ipa.sh`

iOS wrapper around core patch flow.

```bash
./scripts/patch/patch-rebirth-ipa.sh --base /path/to/FalloutData --out /path/to/Fallout1-RME
```

## Test Scripts

### Platform verification

- `scripts/test/test-macos.sh`
- `scripts/test/test-macos-headless.sh`
- `scripts/test/test-ios-simulator.sh`
- `scripts/test/test-ios-headless.sh`

Example:

```bash
./scripts/build/build-macos.sh -prod
./scripts/test/test-macos.sh

./scripts/build/build-ios.sh -prod --simulator
./scripts/test/test-ios-simulator.sh
```

### Rebirth validation tests

- `scripts/test/test-rebirth-validate-data.sh`
- `scripts/test/test-rebirth-refresh-validation.sh`
- `scripts/test/test-rebirth-toggle-logging.sh`

Notes:

- `test-rebirth-toggle-logging.sh` updates `.f1r-build.env` only.
- After toggling logging, run explicit build commands yourself.

### RME suite

Master runner:

```bash
python3 scripts/test/rme/suite.py quick
python3 scripts/test/rme/suite.py all
```

Modes:

- `quick`
- `patchflow`
- `autofix`
- `full`
- `all`

Fixtures/support data now live under:

- `scripts/test/rme-fixtures/`
- `scripts/test/rme-fixture-tools/`
- `scripts/test/rme-sample-workdir/`

## Common Workflows

### Pre-commit

```bash
./scripts/dev/dev-format.sh
./scripts/dev/dev-check.sh
```

### Build + verify (macOS)

```bash
./scripts/build/build-macos.sh -prod
./scripts/dev/dev-verify.sh --build-dir build-macos
./scripts/test/test-macos.sh
```

### Build + verify (iOS simulator)

```bash
./scripts/build/build-ios.sh -prod --simulator
./scripts/test/test-ios-headless.sh
./scripts/test/test-ios-simulator.sh
```

### Build test-ready artifacts

```bash
./scripts/build/build-macos.sh -test --game-data /path/to/patchedfiles
./scripts/build/build-ios.sh -test --both --game-data /path/to/patchedfiles
```
