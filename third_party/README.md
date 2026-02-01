# third_party/

Third-party dependencies managed via CMake FetchContent.

Each subdirectory contains a CMakeLists.txt that fetches the dependency from its upstream repository at a pinned commit or tag.

## Dependencies

| Directory | Library | Version | Description |
|-----------|---------|---------|-------------|
| [sdl2/](sdl2/) | SDL2 | 2.30.10 | Cross-platform multimedia library |
| [adecode/](adecode/) | adecode | 1.0.0 | ACM audio decoder |
| [fpattern/](fpattern/) | fpattern | 1.9 | Filename pattern matching |

## SDL2

Simple DirectMedia Layer provides:
- Window creation and management
- OpenGL/Metal rendering context
- Audio output
- Keyboard, mouse, and touch input
- Game controller support

Built as a static library for this project.

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
FetchContent_Declare(sdl2
    GIT_REPOSITORY "https://github.com/libsdl-org/SDL"
    GIT_TAG "release-2.30.10"  # Update this line
)
```

## Build Artifacts

During build, dependencies are fetched into `build/_deps/`:
- `*-src/` - Source code
- `*-build/` - Build output
- `*-subbuild/` - FetchContent staging
