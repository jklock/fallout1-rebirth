# JOURNAL: iOS Toolchain

Last Updated: 2026-02-15

## Purpose

CMake toolchain file for iOS and iOS Simulator cross-compilation. Based on the popular ios-cmake project (BSD-3-Clause license).

## Recent Activity

### 2026-02-07
- Created JOURNAL.md to track toolchain usage
- Toolchain sourced from https://github.com/leetal/ios-cmake
- Key settings: PLATFORM=OS64 (device), SIMULATORARM64 (Apple Silicon sim)
- ENABLE_BITCODE=0 (bitcode deprecated by Apple in Xcode 14+)

## Key Files

| File | Purpose |
|------|---------|
| [ios.toolchain.cmake](ios.toolchain.cmake) | iOS/tvOS/watchOS cross-compilation toolchain |
| [README.md](README.md) | Toolchain documentation |

## Platform Options

| PLATFORM Value | Target |
|----------------|--------|
| `OS64` | arm64 iOS device |
| `SIMULATORARM64` | arm64 iOS Simulator (Apple Silicon) |
| `SIMULATOR64` | x86_64 iOS Simulator (Intel) |
| `MAC_ARM64` | Apple Silicon macOS |
| `MAC` | x86_64 macOS |

## Common Usage

### iOS Device Build
```bash
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D PLATFORM=OS64 \
  -D ENABLE_BITCODE=0 \
  -G Xcode
```

### iOS Simulator Build (Apple Silicon)
```bash
cmake -B build-ios-sim \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D PLATFORM=SIMULATORARM64 \
  -D ENABLE_BITCODE=0 \
  -G Xcode
```

## Development Notes

- **Always use `-G Xcode`** - Makefiles don't work for iOS cross-compilation
- Toolchain is 1000+ lines - maintained by upstream ios-cmake project
- Automatically detects SDK paths via `xcodebuild -showsdks`
- Deployment target controlled by root CMakeLists.txt, not toolchain
- Project uses SIMULATORARM64 for test scripts (test-ios-simulator.sh)

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.
