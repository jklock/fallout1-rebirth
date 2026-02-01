# Copilot / AI Agent Guide for Fallout CE Rebirth ✅

**Apple-Only Fork** - This project targets macOS and iOS/iPadOS exclusively.

Short, actionable instructions to help an AI coding agent get productive quickly.

## Quick high-level architecture (big picture)
- Core gameplay: `src/game/` (game logic, save/load, world/map, UI hooks). See `src/game/game.h` and `src/game/main.cc` for startup and main loop.
- Script engine: `src/int/` (interpreter + Fallout script opcodes). Script handlers live in `src/int/support/intextra.cc` and are registered via `interpretAddFunc(...)`.
- Platform & UI layer: `src/plib/` (`plib/gnw` implements graphics/input/dialogs via SDL/OS APIs).
- Platform-specific bits: `src/platform/` and `os/ios/`, `os/macos/`.
- Third-party: `third_party/` (SDL2, adecode, fpattern). These use CMake FetchContent and pinned commits.

## Build & run (concrete commands) 💻

### macOS (Xcode)
```bash
cmake -B build-macos -G Xcode -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-macos --config RelWithDebInfo -j $(sysctl -n hw.physicalcpu)
cd build-macos && cpack -C RelWithDebInfo  # creates DMG
```

### macOS (Makefiles - faster iteration)
```bash
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j $(sysctl -n hw.physicalcpu)
./build/fallout-ce
```

### iOS/iPadOS
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

### Quick rebuild
```bash
./scripts/build-macos.sh   # or build-ios.sh
```

## CI & checks (what to make green) ✅
- See `.github/workflows/ci-build.yml`:
  - Static analysis: `cppcheck --std=c++17 src/`
  - Formatting: `find src -type f -name "*.cc" -o -name "*.h" | xargs clang-format --dry-run --Werror` (use `clang-format -i` to fix locally).
  - macOS and iOS builds only.
- Release artifacts are produced by `.github/workflows/release.yml` and uploaded to GitHub Releases.
- Run `./scripts/check.sh` locally before committing.

## Project-specific conventions & patterns (do these precisely) 🔧
- Add new C++ sources: update `CMakeLists.txt` — sources are enumerated under `target_sources(${EXECUTABLE_NAME} PUBLIC ...)`. Forgetting to add files → build failure.
- Script opcodes: implement handler in `src/int/support/intextra.cc` and register with `interpretAddFunc(OPCODE, handler)`. Use `dbg_error(...)` and `debug_printf(...)` for consistent script error logging.
- Formatting: `.clang-format` (BasedOnStyle: WebKit) + `.editorconfig`. Run `clang-format -i` on changed files before PR.
- Memory & error handling: codebase uses C-style memory and global state (many `extern`s). Be cautious with ownership/pointers and avoid introducing complex RAII changes without tests.
- Naming: file names and headers use lowercase + underscores; header guards follow `FALLOUT_<PATH>_H_`; most sources are in namespace `fallout`.

## Dependencies & integration notes ⚠️
- SDL2: bundled via `third_party/sdl2` using FetchContent (currently release-2.30.10).
- Third-party libraries are pinned in `third_party/*` via FetchContent (update GIT_TAG when upgrading and add a brief PR note).
- Xcode and Command Line Tools required for all builds.

## Debugging & sanitizers 🐞
- Useful helpers: `debug_printf(...)`, `GNWSystemError(...)`, `dbg_error(...)` for script/runtime errors.
- ASAN/UBSAN: enable using CMake options: `-DASAN=ON` / `-DUBSAN=ON` while configuring.

## Assets & licensing (very important) ⚖️
- You MUST NOT add original game assets (`master.dat`, `critter.dat`, `data/`) to the repo or commits. See `README.md` and `LICENSE.md` (Sustainable Use License). Tests that require assets must include clear local reproduction steps and not ship binaries.
- Asset filename case matters on case-sensitive file systems; config keys are in `fallout.cfg` (`master_dat`, `critter_dat`) and default to `master.dat`/`critter.dat` in `src/game/gconfig.cc`.

## Tests & PR checklist (what to include in PRs) ✅
- Run `clang-format` and `cppcheck` locally and fix issues.
- Ensure CI builds for at least the platform(s) your change affects.
- If you add sources, update `CMakeLists.txt` and (if needed) platform packaging steps.
- Document manual reproduction steps and required assets (if any) in the PR description.
- Never include secrets or signing keys in PRs—CI uses repository secrets for signing/notarization.

## Where to look for examples ⛏️
- Source struct: `src/game/`, `src/int/`, `src/plib/`.
- Opcode registration: `src/int/support/intextra.cc` (look for `interpretAddFunc(...)`).
- Build & CI examples: `.github/workflows/ci-build.yml`, `.github/workflows/release.yml`.
- iOS platform: `os/ios/` and `cmake/toolchain/ios.toolchain.cmake`.
- Packaging (macOS/iOS): `CMakeLists.txt` CPACK setup.

## Testing 🧪
- Automated: `./scripts/test.sh` runs build verification and static checks.
- Manual testing required for gameplay - see `FCE/TODO/PHASE_4_TESTING_POLISH.md`.
- Game data files (master.dat, critter.dat) are NOT included - obtain from GOG/Steam.

### iOS Simulator Testing (PRIMARY TARGET) 📱
**iPad is the primary use case for this project.** Always use the dedicated script:
```bash
./scripts/test-ios-simulator.sh              # Full flow: build + install + launch
./scripts/test-ios-simulator.sh --build-only # Just build
./scripts/test-ios-simulator.sh --launch     # Launch existing install
./scripts/test-ios-simulator.sh --shutdown   # Shutdown all simulators
./scripts/test-ios-simulator.sh --list       # Show available iPad sims
```

**CRITICAL RULES:**
- **ONE SIMULATOR AT A TIME** — multiple simulators cause severe memory pressure and system instability
- Always run `--shutdown` before starting a new simulator
- Check for running simulators: `xcrun simctl list devices | grep Booted`
- Default target: `iPad Pro 13-inch (M4)` (configurable via `SIMULATOR_NAME` env var)
- Game data goes in the app's **data container**, not the app bundle (read-only at runtime)

**DO NOT** manually run `xcrun simctl boot` on multiple devices or use raw CMake commands for simulator builds — use the script.

## Fork Enhancements (Rebirth) 🍎
This fork includes cherry-picked improvements:
- iPad mouse/trackpad + F-key support (evaera)
- Touch control optimization (zverinapavel)
- Borderless window mode (radozd)
- QoL features + bugfixes (korri123)
- TeamX Patch 1.3.5 compatibility
- RME 1.1e data integration

See `FCE/` directory for project documentation and phase guides.

---
For other platforms, use upstream: https://github.com/alexbatalov/fallout1-ce
