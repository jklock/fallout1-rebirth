# Copilot / AI Agent Guide for Fallout 1 Rebirth

**Apple-Only Fork** — This project targets macOS and iOS/iPadOS exclusively.

Short, actionable instructions to help an AI coding agent get productive quickly.

## ⚠️ CRITICAL: Use Project Scripts

**ALWAYS use the provided scripts for testing and building. Do NOT run raw cmake/xcodebuild commands.**

| Task | Script | NOT This |
|------|--------|----------|
| Test iOS | `./scripts/test/test-ios-simulator.sh` | ❌ `cmake ...` or `xcrun simctl` directly |
| Test macOS | `./scripts/test/test-macos.sh` | ❌ `./build/fallout1-rebirth` |
| Build iOS | `./scripts/build/build-ios.sh` | ❌ `cmake -B build-ios ...` |
| Build macOS | `./scripts/build/build-macos.sh` | ❌ `cmake -B build-macos ...` |
| Pre-commit | `./scripts/dev/dev-check.sh` | ❌ `clang-format` manually |

The scripts handle simulator management, proper build configs, and cleanup. Ignoring them causes test failures and wastes time.

## Project Status

All development phases are complete:

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Environment Setup | COMPLETED |
| 1 | Vanilla Build | COMPLETED |
| 2 | Fork Integration | COMPLETED |
| 3 | RME Integration | COMPLETED |
| 4 | Testing Infrastructure | COMPLETED |
| 5 | Distribution Structure | COMPLETED |
| 6 | Engine Fixes | COMPLETED |
| 7 | Platform Cleanup | COMPLETED |

Key completions:
- All Android/Windows/Linux code removed — Apple platforms only
- Local builds only (no CI/CD) — use GitHub Releases for distribution
- Distribution structure in `dist/macos/` and `dist/ios/`
- Engine fixes verified (Survivalist perk, bug fixes)
- Testing infrastructure in place with simulator support
- VSync enabled by default, touch coordinate fixes applied

## Architecture Overview

| Directory | Purpose |
|-----------|---------|
| `src/game/` | Core gameplay (game logic, save/load, world/map, UI hooks) |
| `src/int/` | Script engine (interpreter + Fallout script opcodes) |
| `src/plib/` | Platform & UI layer (graphics/input/dialogs via SDL) |
| `src/platform/` | Platform-specific abstractions |
| `os/ios/`, `os/macos/` | Platform resources (Info.plist, icons, storyboards) |
| `third_party/` | Dependencies (SDL2, adecode, fpattern) via FetchContent |
| `dist/` | Distribution files for packaging |
| `docs/` | Project documentation |
| `development/` | Internal development docs and research |

Entry points: `src/game/game.h` and `src/game/main.cc` for startup and main loop.
Script handlers: `src/int/support/intextra.cc` registered via `interpretAddFunc(...)`.

## Build Commands

### macOS (Xcode)
```bash
cmake -B build-macos -G Xcode -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-macos --config RelWithDebInfo -j $(sysctl -n hw.physicalcpu)
cd build-macos && cpack -C RelWithDebInfo  # creates DMG
```

### macOS (Makefiles — faster iteration)
```bash
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j $(sysctl -n hw.physicalcpu)
./build/fallout1-rebirth
```

### iOS/iPadOS (Device)
```bash
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=OS64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-ios --config RelWithDebInfo -j $(sysctl -n hw.physicalcpu)
cd build-ios && cpack -C RelWithDebInfo  # creates .ipa
```

### Quick Build Scripts
```bash
./scripts/build/build-macos.sh   # Build for macOS
./scripts/build/build-ios.sh     # Build for iOS device
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `./scripts/build/build-macos.sh` | Build for macOS |
| `./scripts/build/build-ios.sh` | Build for iOS device |
| `./scripts/test/test-ios-simulator.sh` | Build and test on iOS Simulator |
| `./scripts/test/test-macos.sh` | Build and verify macOS app |
| `./scripts/test/test-macos-headless.sh` | Headless macOS app validation |
| `./scripts/test/test-ios-headless.sh` | Headless iOS Simulator validation |
| `./scripts/dev/dev-verify.sh` | Run verification (build + static checks) |
| `./scripts/dev/dev-check.sh` | Pre-commit checks (format + lint) |
| `./scripts/dev/dev-format.sh` | Format code with clang-format |
| `./scripts/dev/dev-clean.sh` | Clean all build artifacts |

## Local Development (No CI)

**This project is built locally only.** CI/CD workflows have been removed.

Run validation before every commit:
```bash
./scripts/dev/dev-check.sh    # Pre-commit format + lint checks
./scripts/dev/dev-verify.sh   # Full build verification + static analysis
```

### Releasing

Builds are created locally and uploaded to GitHub Releases:
```bash
./scripts/build/build-macos-dmg.sh   # Creates macOS DMG
./scripts/build/build-ios.sh && cd build-ios && cpack -C RelWithDebInfo  # Creates iOS IPA
```

Then upload artifacts to GitHub Releases manually.

## Distribution Structure

The `dist/` directory contains platform-specific distribution files:

```
dist/
├── macos/
│   ├── README.md
│   ├── README.txt
│   ├── f1_res.ini
│   └── fallout.cfg
└── ios/
    ├── README.md
    ├── README.txt
    ├── f1_res.ini
    └── fallout.cfg
```

These files are bundled with the app during packaging (DMG for macOS, IPA for iOS).

## Project Conventions

- **Adding sources**: Update `CMakeLists.txt` under `target_sources(${EXECUTABLE_NAME} PUBLIC ...)`. Missing files cause build failures.
- **Script opcodes**: Implement in `src/int/support/intextra.cc`, register with `interpretAddFunc(OPCODE, handler)`.
- **Formatting**: `.clang-format` (BasedOnStyle: WebKit) + `.editorconfig`. Run `clang-format -i` on changed files.
- **Memory handling**: C-style memory with global state (many `extern`s). Avoid complex RAII without tests.
- **Naming**: Lowercase + underscores for files; header guards `FALLOUT_<PATH>_H_`; namespace `fallout`.
- **Logging**: Use `debug_printf(...)`, `dbg_error(...)`, `GNWSystemError(...)` for runtime errors.

## Dependencies

- **SDL2**: Bundled via `third_party/sdl2` using FetchContent (release-2.30.10)
- **adecode**: Audio decoding library in `third_party/adecode`
- **fpattern**: File pattern matching in `third_party/fpattern`

All dependencies are pinned via FetchContent GIT_TAG. Update tags when upgrading.

**Requirements**: Xcode and Command Line Tools for all builds.

## Debugging

- **Helpers**: `debug_printf(...)`, `GNWSystemError(...)`, `dbg_error(...)` for runtime errors
- **ASAN**: Enable with `-DASAN=ON` during CMake configuration
- **UBSAN**: Enable with `-DUBSAN=ON` during CMake configuration

## Assets & Licensing

- **Never commit** original game assets (`master.dat`, `critter.dat`, `data/`) to the repo
- See `README.md` and `LICENSE.md` (Sustainable Use License)
- Asset filename case matters on case-sensitive file systems
- Config keys in `fallout.cfg`: `master_dat`, `critter_dat`
- Obtain game data from your Fallout 1 copy

## Testing

### Automated Testing
```bash
./scripts/dev/dev-verify.sh   # Build verification + static checks
./scripts/dev/dev-check.sh    # Pre-commit format + lint checks
```

### iOS Simulator Testing (Primary Target)

**iPad is the primary use case.** Use the dedicated script:
```bash
./scripts/test/test-ios-simulator.sh              # Full flow: build + install + launch
./scripts/test/test-ios-simulator.sh --build-only # Just build
./scripts/test/test-ios-simulator.sh --launch     # Launch existing install
./scripts/test/test-ios-simulator.sh --shutdown   # Shutdown all simulators
./scripts/test/test-ios-simulator.sh --list       # Show available iPad sims
```

**Critical rules:**
- **One simulator at a time** — multiple simulators cause memory pressure
- Run `--shutdown` before starting a new simulator
- Check running: `xcrun simctl list devices | grep Booted`
- Default: `iPad Pro 13-inch (M4)` (override via `SIMULATOR_NAME` env var)
- Game data goes in app's data container, not app bundle

**Do not** manually run `xcrun simctl boot` on multiple devices or use raw CMake for simulator builds.

## Commit Checklist

- [ ] Run `./scripts/dev/dev-check.sh` (format + lint)
- [ ] Run `./scripts/dev/dev-verify.sh` (full build verification)
- [ ] Update `CMakeLists.txt` if adding sources
- [ ] Document manual reproduction steps if assets required
- [ ] Never include secrets or signing keys

## Code Examples

| What | Where |
|------|-------|
| Source structure | `src/game/`, `src/int/`, `src/plib/` |
| Opcode registration | `src/int/support/intextra.cc` (`interpretAddFunc(...)`) |
| iOS platform | `os/ios/`, `cmake/toolchain/ios.toolchain.cmake` |
| Packaging | `CMakeLists.txt` CPACK setup |

## Fork Enhancements

This fork includes cherry-picked improvements from community contributors:
- iPad mouse/trackpad + F-key support (evaera)
- Touch control optimization (zverinapavel)
- Borderless window mode (radozd)
- QoL features + bugfixes (korri123)
- TeamX Patch 1.3.5 compatibility
- RME 1.1e data integration

See `docs/` for user documentation and `development/` for internal development docs.

---
For other platforms, use upstream: https://github.com/alexbatalov/fallout1-ce
