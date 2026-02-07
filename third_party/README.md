# third_party/

Third-party dependencies managed via CMake FetchContent.

Last updated: 2026-02-07

Each subdirectory contains a CMakeLists.txt that fetches the dependency from its upstream repository at a pinned commit or tag.

## Dependencies

| Directory | Library | Version | Description |
|-----------|---------|---------|-------------|
| [sdl3/](sdl3/) | SDL3 | 3.4.0 | Cross-platform multimedia library (upgraded from SDL2) |
| [adecode/](adecode/) | adecode | 1.0.0 | ACM audio decoder |
| [fpattern/](fpattern/) | fpattern | 1.9 | Filename pattern matching |

## SDL3

Simple DirectMedia Layer 3 provides:
- Window creation and management
- GPU-accelerated rendering with pixel-perfect scaling
- Audio output
- Keyboard, mouse, and touch input
- Game controller support
- Improved high-DPI and ProMotion display support

Built as a static library for this project. This fork was the first Fallout CE derivative to upgrade from SDL2 to SDL3.

## adecode

Decoder for ACM audio format used in Fallout's sound files.

## fpattern

Wildcard pattern matching for filenames, used when loading game assets.

## Updating Dependencies

To update a dependency:

1. Edit the relevant `CMakeLists.txt` in the subdirectory
2. Update `GIT_TAG` to the new commit hash or tag
3. Rebuild to fetch the new version
4. Test thoroughly before committing

Example:

```cmake
FetchContent_Declare(sdl3
    GIT_REPOSITORY "https://github.com/libsdl-org/SDL"
    GIT_TAG "release-3.4.0"  # Update this line
)
```

## Build Artifacts

During build, dependencies are fetched into `build/_deps/`:
- `*-src/` - Source code
- `*-build/` - Build output
- `*-subbuild/` - FetchContent staging

---

## Proof of Work

**Last Verified**: 2026-02-07

**Files read to verify content**:
- third_party/ directory listing (sdl3/, adecode/, fpattern/ confirmed)
- third_party/sdl3/CMakeLists.txt (GIT_TAG "release-3.4.0" confirmed)

**Updates made**:
- Updated SDL3 version references and CMake example to release-3.4.0
- Refreshed verification date
