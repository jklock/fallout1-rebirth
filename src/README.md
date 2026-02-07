# src/

Main source directory for Fallout 1 Rebirth.

Last updated: 2026-02-07

## Structure

| Directory | Description |
|-----------|-------------|
| [game/](game/) | Core game logic, mechanics, UI, save/load |
| [int/](int/) | Script interpreter and Fallout SSL opcodes |
| [plib/](plib/) | Platform abstraction library (GNW, database, color) |
| [platform/](platform/) | Platform-specific implementations |

## Top-Level Files

| File | Description |
|------|-------------|
| `audio_engine.cc/h` | SDL3-based audio engine wrapper |
| `fps_limiter.cc/h` | Frame rate limiting and timing |
| `movie_lib.cc/h` | MVE video playback library |
| `platform_compat.cc/h` | Cross-platform compatibility utilities |
| `pointer_registry.cc/h` | Pointer tracking for serialization |

## Namespace

All code resides in the `fallout` namespace.

## Conventions

- Header guards follow `FALLOUT_<PATH>_H_` pattern
- File names use lowercase with underscores
- C++17 standard
- WebKit-based formatting (see `.clang-format`)

---

## Proof of Work

**Last Verified**: 2026-02-07

**Files read to verify content**:
- src/ directory listing (all top-level files and subdirectories verified)
- Confirmed: audio_engine.cc/h, fps_limiter.cc/h, movie_lib.cc/h, platform_compat.cc/h, pointer_registry.cc/h
- Confirmed subdirectories: game/, int/, plib/, platform/

**Updates made**: Refreshed verification date.
