# JOURNAL: CMake Configuration

Last Updated: 2026-02-15

## Purpose

CMake build system support files. Contains toolchain files for cross-compilation to iOS.

## Recent Activity

### 2026-02-07
- Created JOURNAL.md to track CMake configuration changes
- SDL3 FetchContent integration active
- Apple-only targets (macOS, iOS/iPadOS)
- Bitcode disabled (ENABLE_BITCODE=0) - deprecated by Apple

## Key Files

| File | Purpose |
|------|---------|
| [toolchain/](toolchain/) | Cross-compilation toolchain files |
| [toolchain/ios.toolchain.cmake](toolchain/ios.toolchain.cmake) | iOS/Simulator cross-compilation |
| [README.md](README.md) | CMake usage documentation |

## Build Targets

| Platform | Generator | Toolchain |
|----------|-----------|-----------|
| macOS | Xcode or Makefiles | None (native) |
| iOS Device | Xcode | ios.toolchain.cmake (PLATFORM=OS64) |
| iOS Simulator | Xcode | ios.toolchain.cmake (PLATFORM=SIMULATORARM64) |

## Root CMakeLists.txt Features

- C++17 standard requirement
- Source file enumeration under `src/`
- FetchContent for SDL3, adecode, fpattern
- Platform conditionals for Apple-specific settings
- CPack configuration for DMG (macOS) and IPA (iOS)

## Development Notes

- Always use `-G Xcode` for iOS builds (required by toolchain)
- macOS can use Makefiles for faster iteration: `cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo`
- iOS 15.0 minimum set in root CMakeLists.txt (DEPLOYMENT_TARGET)
- macOS 11.0 minimum set in root CMakeLists.txt
- Code signing disabled for local builds: `-D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''`

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.
