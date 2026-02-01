# Fallout CE Rebirth - AI Agent Skill

## Overview
This skill provides guidance for working with the Fallout CE Rebirth project, an Apple-only fork of Fallout 1 Community Edition.

## Capabilities
- Build macOS and iOS versions
- Run automated tests and static analysis
- Understand project architecture
- Navigate C++ game engine codebase

## Build Commands
```bash
# Quick macOS build
./scripts/build-macos.sh

# Quick iOS build  
./scripts/build-ios.sh

# Run tests
./scripts/test.sh

# Format code
./scripts/format.sh

# Pre-commit checks
./scripts/check.sh
```

## Architecture Quick Reference

### Core Directories
| Directory | Purpose |
|-----------|---------|
| `src/game/` | Game logic, main loop, save/load |
| `src/int/` | Script interpreter, opcodes |
| `src/plib/` | Graphics, input, dialogs (SDL) |
| `src/platform/` | Platform abstraction |
| `os/ios/`, `os/macos/` | Platform-specific code |
| `third_party/` | SDL2, dependencies |

### Key Files
| File | Purpose |
|------|---------|
| `src/game/main.cc` | Entry point, main loop |
| `src/game/game.h` | Core game definitions |
| `src/int/support/intextra.cc` | Script opcode handlers |
| `CMakeLists.txt` | Build configuration |

## Adding New Features

### New Source File
1. Create `.cc` and `.h` in appropriate `src/` subdirectory
2. Add to `CMakeLists.txt` under `target_sources`
3. Run `./scripts/check.sh` before committing

### New Script Opcode
1. Implement handler in `src/int/support/intextra.cc`
2. Register with `interpretAddFunc(OPCODE, handler)`
3. Use `dbg_error()` for error logging

## Platform Notes
- **macOS**: Uses Cocoa, Metal rendering
- **iOS/iPadOS**: Touch controls, external keyboard support
- **NOT supported**: Windows, Linux, Android (use upstream for those)

## Project Documentation
See `FCE/` directory for:
- `TODO/PHASE_*.md` - Implementation guides
- `analysis/` - Research and fork analysis
