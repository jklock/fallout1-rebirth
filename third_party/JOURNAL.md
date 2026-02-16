# JOURNAL: Third-Party Dependencies

Last Updated: 2026-02-14

## Purpose

External dependencies managed via CMake FetchContent. All dependencies are pinned via GIT_TAG to ensure reproducible builds.

## Directory Structure

| Directory | Library | Version | Description |
|-----------|---------|---------|-------------|
| `sdl3/` | SDL3 | 3.4.0 | Cross-platform multimedia library |
| `adecode/` | adecode | 1.0.0 | ACM audio decoder for Fallout sounds |
| `fpattern/` | fpattern | 1.9 | Filename pattern matching |
| `rme/` | RME | 1.1e | Restoration Mod Enhanced data payload |

## Recent Activity

### 2026-02-14
- Refreshed RME dependency audit material (`third_party/rme/patchvalidation.md`) for community traceability.

### 2026-02-07
- Created JOURNAL.md to track dependency changes
- SDL3 at version 3.4.0 (upgraded from 2.30.10 → 3.2.4 → 3.4.0)
- RME patch pipeline fully integrated with scripts/patch/
- All dependencies building successfully on Apple platforms

### Previous
- First Fallout CE fork to upgrade from SDL2 to SDL3
- SDL3 migration enabled pixel-perfect scaling and ProMotion support
- adecode and fpattern unchanged from upstream fallout1-ce

## Key Files

| File | Purpose |
|------|---------|
| `sdl3/CMakeLists.txt` | SDL3 FetchContent configuration |
| `adecode/CMakeLists.txt` | adecode FetchContent configuration |
| `fpattern/CMakeLists.txt` | fpattern FetchContent configuration |
| `rme/manifest.json` | RME payload manifest and validation |
| `README.md` | Dependency overview and update instructions |

## Development Notes

### For AI Agents

1. **Updating Dependencies**: Edit `GIT_TAG` in the relevant CMakeLists.txt
2. **Build Location**: Dependencies are fetched to `build/_deps/` during build
3. **Static Linking**: All dependencies are built as static libraries
4. **SDL3 Migration**: This project uses SDL3 (not SDL2) - check API changes carefully

### SDL3 Upgrade Path

```
SDL2 2.30.10 → SDL3 3.2.4 → SDL3 3.4.0
```

Key SDL3 improvements:
- Pixel-perfect scaling with GPU rendering
- Better high-DPI and ProMotion display support
- Improved audio API with device callbacks
- Enhanced touch input handling

### Dependency Pinning

All dependencies use explicit GIT_TAG values to ensure reproducible builds:

```cmake
FetchContent_Declare(sdl3
    GIT_REPOSITORY "https://github.com/libsdl-org/SDL"
    GIT_TAG "release-3.4.0"
)
```

### Testing After Updates

```bash
./scripts/dev/dev-verify.sh    # Full build verification
./scripts/test/test-macos.sh   # macOS validation
./scripts/test/test-ios-simulator.sh  # iOS validation
```
