# JOURNAL: src/

Last Updated: 2026-02-15

## Purpose

Main source code directory for Fallout 1 Rebirth. Contains the core game engine, script interpreter, platform abstraction layer, and UI/graphics subsystems.

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `game/` | Core game logic (combat, maps, saves, UI) |
| `int/` | Script interpreter and Fallout script opcodes |
| `plib/` | Platform & UI layer (graphics, input via SDL3) |
| `platform/` | Platform-specific abstractions (iOS/macOS) |

## Recent Activity

### 2026-02-14
- Added compile-time diagnostic logging toggle support (`F1R_DISABLE_RME_LOGGING`) for release builds.
- Updated source-level audit comments for RME logging/patch diagnostics pathways.
- Added `F1R AUDIT NOTE` rationale comments in all `src/` files changed since branch divergence from `origin/main`.

### 2026-02-07
- SDL3 migration completed - all audio and video now using SDL3 APIs
- Touch input refinements in plib/gnw/touch.cc
- Frame rate limiter improvements for consistent 60fps

### Previous
- Removed all Android/Windows/Linux code (Apple-only fork)
- VSync enabled by default for tear-free rendering

## Key Files

| File | Purpose |
|------|---------|
| `audio_engine.cc` | SDL3 audio backend, sound mixing |
| `fps_limiter.cc` | Frame rate control and timing |
| `movie_lib.cc` | MVE video playback |
| `platform_compat.cc` | Cross-platform compatibility shims |
| `pointer_registry.cc` | Safe pointer tracking for save/load |

## Development Notes

### For AI Agents

1. **Build System**: Files must be added to `CMakeLists.txt` under `target_sources()`
2. **SDL3 Migration**: This project uses SDL3 (not SDL2) - check third_party/sdl3/
3. **Apple Only**: No Windows/Linux/Android code - use iOS/macOS specific APIs freely
4. **Formatting**: WebKit style via .clang-format - run `./scripts/dev/dev-format.sh`

### Architecture Overview

- Entry point: `game/main.cc` → `game/game.cc`
- Rendering: `plib/gnw/svga.cc` (SDL3 renderer)
- Input flow: SDL events → `plib/gnw/dxinput.cc` → `plib/gnw/mouse.cc` / `plib/gnw/touch.cc`
- Audio: `audio_engine.cc` → SDL3 audio device

### Testing Changes

```bash
./scripts/test/test-macos.sh           # macOS
./scripts/test/test-ios-simulator.sh   # iOS Simulator
```

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.
