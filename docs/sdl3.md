# SDL3 Migration

Fallout 1 Rebirth was the **first Fallout CE derivative to upgrade from SDL2 to SDL3**. This document explains why SDL3 was chosen, what changed from SDL2, and the technical implementation details.

## Why SDL3?

### Modern API Improvements

SDL3 represents a major evolution of the Simple DirectMedia Layer, providing:

- **Cleaner, more consistent API**: Function naming and parameter ordering are more logical
- **Better error handling**: Functions return bool or specific error types instead of magic numbers
- **Simplified event system**: Window events are now separate event types instead of a nested struct
- **Native GPU rendering**: Built-in support for modern graphics APIs (Metal, Vulkan, Direct3D 12)

### Better Apple Platform Support

SDL3 was specifically chosen for its improved Apple platform integration:

- **Native Metal renderer**: First-class Metal support on macOS and iOS
- **ProMotion display support**: Better high-refresh-rate display handling
- **Improved high-DPI handling**: Native support for Retina displays
- **Modern iOS lifecycle events**: Proper handling of app suspend/resume
- **Apple Silicon optimization**: Native ARM64 support

### GPU Rendering Capabilities

SDL3 introduces significant rendering improvements:

- **Per-texture scale modes**: `SDL_SetTextureScaleMode()` for pixel-perfect nearest neighbor scaling
- **Render logical presentation**: Better control over letterboxing and aspect ratio
- **Improved VSync control**: `SDL_SetRenderVSync()` for proper frame pacing
- **Float-based rectangles**: `SDL_FRect` for sub-pixel precision

### Simplified Input Handling

- **Flattened keyboard events**: Direct access to scancodes without nested structs
- **Better touch coordinate handling**: `SDL_RenderCoordinatesFromWindow()` for proper touch-to-logical conversion
- **Improved cursor control**: Separate `SDL_HideCursor()` and `SDL_ShowCursor()` functions
- **Per-window relative mouse mode**: `SDL_SetWindowRelativeMouseMode()`

---

## What Changed from SDL2

### Include Path Changes

```c
// SDL2
#include <SDL.h>
#include <SDL_main.h>

// SDL3
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
```

### Initialization Changes

The initialization process remains similar, but some flags have changed:

```c
// SDL2
SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER);

// SDL3 - SDL_INIT_TIMER removed (always available)
SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO);
```

### Renderer Creation

```c
// SDL2 - index-based driver selection
SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

// SDL3 - driver name (NULL = auto), VSync set separately
SDL_CreateRenderer(window, NULL);
SDL_SetRenderVSync(renderer, 1);
```

### Texture Scaling (Key Change for Retro Graphics)

```c
// SDL2 - hint-based (affects all textures)
SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

// SDL3 - per-texture API
SDL_SetTextureScaleMode(texture, SDL_SCALEMODE_NEAREST);
```

This change enables pixel-perfect rendering essential for Fallout's retro graphics.

### Event Type Renames

SDL3 uses a consistent `SDL_EVENT_*` naming scheme:

| SDL2 | SDL3 |
|------|------|
| `SDL_KEYDOWN` | `SDL_EVENT_KEY_DOWN` |
| `SDL_KEYUP` | `SDL_EVENT_KEY_UP` |
| `SDL_QUIT` | `SDL_EVENT_QUIT` |
| `SDL_MOUSEWHEEL` | `SDL_EVENT_MOUSE_WHEEL` |
| `SDL_MOUSEMOTION` | `SDL_EVENT_MOUSE_MOTION` |
| `SDL_MOUSEBUTTONDOWN` | `SDL_EVENT_MOUSE_BUTTON_DOWN` |
| `SDL_MOUSEBUTTONUP` | `SDL_EVENT_MOUSE_BUTTON_UP` |
| `SDL_FINGERDOWN` | `SDL_EVENT_FINGER_DOWN` |
| `SDL_FINGERUP` | `SDL_EVENT_FINGER_UP` |
| `SDL_FINGERMOTION` | `SDL_EVENT_FINGER_MOTION` |
| `SDL_WINDOWEVENT` | Individual `SDL_EVENT_WINDOW_*` events |
| `SDL_APP_WILLENTERBACKGROUND` | `SDL_EVENT_WILL_ENTER_BACKGROUND` |
| `SDL_APP_DIDENTERBACKGROUND` | `SDL_EVENT_DID_ENTER_BACKGROUND` |
| `SDL_APP_WILLENTERFOREGROUND` | `SDL_EVENT_WILL_ENTER_FOREGROUND` |
| `SDL_APP_DIDENTERFOREGROUND` | `SDL_EVENT_DID_ENTER_FOREGROUND` |

### Window Event Handling

```c
// SDL2 - nested switch
if (event.type == SDL_WINDOWEVENT) {
    switch (event.window.event) {
        case SDL_WINDOWEVENT_EXPOSED:
        case SDL_WINDOWEVENT_FOCUS_GAINED:
    }
}

// SDL3 - flat event types
switch (event.type) {
    case SDL_EVENT_WINDOW_EXPOSED:
    case SDL_EVENT_WINDOW_FOCUS_GAINED:
    case SDL_EVENT_WINDOW_FOCUS_LOST:
    case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
}
```

### Render Functions

| SDL2 | SDL3 |
|------|------|
| `SDL_RenderCopy()` | `SDL_RenderTexture()` |
| `SDL_RenderCopyEx()` | `SDL_RenderTextureRotated()` |
| `SDL_RenderSetLogicalSize()` | `SDL_SetRenderLogicalPresentation()` |
| `SDL_RenderWindowToLogical()` | `SDL_RenderCoordinatesFromWindow()` |
| `SDL_RenderLogicalToWindow()` | `SDL_RenderCoordinatesToWindow()` |

### Surface Functions

| SDL2 | SDL3 |
|------|------|
| `SDL_CreateRGBSurface()` | `SDL_CreateSurface()` |
| `SDL_CreateRGBSurfaceFrom()` | `SDL_CreateSurfaceFrom()` |
| `SDL_CreateRGBSurfaceWithFormat()` | `SDL_CreateSurface()` |
| `SDL_FreeSurface()` | `SDL_DestroySurface()` |

### Audio System (Major Rewrite)

SDL3 replaces the callback-based audio with a stream-based API:

```c
// SDL2 - callback-based
SDL_AudioSpec want;
want.freq = 22050;
want.format = AUDIO_S16;
want.channels = 2;
want.samples = 1024;
want.callback = audioCallback;
SDL_AudioDeviceID device = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
SDL_PauseAudioDevice(device, 0);

// SDL3 - stream-based with callback
SDL_AudioSpec spec = { SDL_AUDIO_S16, 2, 22050 };
SDL_AudioStream* stream = SDL_OpenAudioDeviceStream(
    SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, audioCallback, userdata);
SDL_ResumeAudioStreamDevice(stream);
```

Audio format constants also changed:

| SDL2 | SDL3 |
|------|------|
| `AUDIO_S16` | `SDL_AUDIO_S16` |
| `AUDIO_S8` | `SDL_AUDIO_S8` |
| `AUDIO_U8` | `SDL_AUDIO_U8` |
| `AUDIO_F32` | `SDL_AUDIO_F32` |

Volume handling changed from integer (0-128) to float (0.0-1.0):

```c
// SDL2
SDL_MixAudioFormat(dst, src, format, len, volume);  // volume 0-128

// SDL3
SDL_MixAudio(dst, src, format, len, volume);  // volume 0.0-1.0
```

### Mouse/Cursor Functions

| SDL2 | SDL3 |
|------|------|
| `SDL_ShowCursor(SDL_DISABLE)` | `SDL_HideCursor()` |
| `SDL_ShowCursor(SDL_ENABLE)` | `SDL_ShowCursor()` |
| `SDL_SetRelativeMouseMode(SDL_TRUE)` | `SDL_SetWindowRelativeMouseMode(window, true)` |
| `SDL_NUM_SCANCODES` | `SDL_SCANCODE_COUNT` |

### Time Functions

```c
// SDL2
Uint64 ticks = SDL_GetTicks64();  // Returns Uint64

// SDL3
Uint64 ticks = SDL_GetTicks();  // Now always returns Uint64
```

---

## Benefits for This Project

### Better macOS/iOS Support

- **Native Metal rendering**: Automatic use of Apple's Metal API for optimal performance
- **Proper notch/safe area handling**: Better adaptation to modern iPhone/iPad displays
- **Improved app lifecycle**: Correct handling of iOS app suspend/resume states
- **High-DPI scaling**: Native Retina support without manual calculations

### Improved Touch/Pencil Input

The SDL3 migration enabled better touch handling:

- **Coordinate conversion**: `SDL_RenderCoordinatesFromWindow()` properly converts touch coordinates to game logical coordinates
- **Timestamp precision**: Event timestamps now in nanoseconds for more precise gesture detection
- **Multi-touch reliability**: Better finger tracking for iOS gesture recognition
- **Click offset calibration**: `CLICK_OFFSET_X`/`CLICK_OFFSET_Y` settings in `f1_res.ini` allow fine-tuning where clicks register (iOS default: Y=-12 to compensate for touch offset)

From [touch.cc](src/plib/gnw/touch.cc):
```c
// Helper to convert SDL3 event timestamp (nanoseconds) to milliseconds
static inline Uint64 timestamp_to_ms(Uint64 timestamp_ns) {
    return timestamp_ns / 1000000ULL;
}

// Using SDL3's coordinate conversion
SDL_RenderCoordinatesFromWindow(gSdlRenderer, pixel_x, pixel_y, &logical_x, &logical_y);
```

### Performance Improvements

- **Pixel-perfect scaling**: `SDL_SCALEMODE_NEAREST` for crisp retro graphics without blur
- **Efficient GPU rendering**: Modern renderer takes advantage of GPU acceleration
- **Better VSync**: Proper frame pacing reduces tearing and improves smoothness
- **Reduced CPU usage**: More efficient event handling and rendering paths

---

## Technical Implementation Details

### FetchContent Integration

SDL3 is integrated via CMake FetchContent in [third_party/sdl3/CMakeLists.txt](third_party/sdl3/CMakeLists.txt):

```cmake
# Build static lib only
set(BUILD_SHARED_LIBS OFF)
set(SDL_SHARED OFF)
set(SDL_STATIC ON)

# Fixes _ftol2_sse already defined
set(SDL_LIBC ON)

include(FetchContent)

FetchContent_Declare(sdl3
    GIT_REPOSITORY "https://github.com/libsdl-org/SDL"
    GIT_TAG "release-3.2.4"
)

FetchContent_MakeAvailable(sdl3)

set(SDL3_INCLUDE_DIRS ${sdl3_SOURCE_DIR}/include PARENT_SCOPE)
set(SDL3_LIBRARIES SDL3::SDL3-static PARENT_SCOPE)
```

### Build Configuration

In the main [CMakeLists.txt](CMakeLists.txt):

```cmake
# SDL3 - always use bundled version for Apple
add_subdirectory("third_party/sdl3")

target_link_libraries(${EXECUTABLE_NAME} ${SDL3_LIBRARIES})
target_include_directories(${EXECUTABLE_NAME} PRIVATE ${SDL3_INCLUDE_DIRS})
```

### Platform-Specific Considerations

#### iOS

```cmake
# Silence SDL3 OpenGL ES deprecation warnings
target_compile_options(${EXECUTABLE_NAME} PRIVATE
    -DGLES_SILENCE_DEPRECATION
    -Wno-deprecated-declarations
)
```

iOS uses Metal by default, but OpenGL ES deprecation warnings are silenced for compatibility.

#### macOS

- Universal binary support (x86_64 and arm64)
- Minimum deployment target: macOS 11.0
- Metal renderer automatic selection

### Files Using SDL3

The following source files include SDL3 headers:

| File | SDL Usage |
|------|-----------|
| [svga.cc](src/plib/gnw/svga.cc) | Window, renderer, textures, scaling |
| [input.cc](src/plib/gnw/input.cc) | Keyboard/mouse/touch events |
| [touch.cc](src/plib/gnw/touch.cc) | Touch gesture handling |
| [dxinput.cc](src/plib/gnw/dxinput.cc) | Input system initialization |
| [kb.cc](src/plib/gnw/kb.cc) | Keyboard scancodes |
| [audio_engine.cc](src/audio_engine.cc) | Audio streams, mixing |
| [fps_limiter.cc](src/fps_limiter.cc) | `SDL_GetTicks()`, `SDL_Delay()` |
| [movie.cc](src/int/movie.cc) | Movie playback |
| [sound.cc](src/int/sound.cc) | Sound system |
| [winmain.cc](src/plib/gnw/winmain.cc) | Main entry, SDL_main |
| [debug.cc](src/plib/gnw/debug.cc) | Debug output |
| [platform_compat.cc](src/platform_compat.cc) | Platform detection |

### Version

**Current SDL3 Version**: 3.2.4 (as of February 2026)

To update:
1. Edit `third_party/sdl3/CMakeLists.txt`
2. Update `GIT_TAG` to new release tag
3. Rebuild and test thoroughly

---

## Migration Reference

For the complete SDL2 → SDL3 migration details, including the step-by-step process and all API changes, see:

- [development/SDL3/PLAN.MD](development/SDL3/PLAN.MD) - Original migration plan
- [SDL3 Migration Guide](https://wiki.libsdl.org/SDL3/README/migration) - Official documentation

---

## Proof of Work

**Timestamp**: February 5, 2026

**Files read to create this document**:
- [third_party/sdl3/CMakeLists.txt](third_party/sdl3/CMakeLists.txt) - SDL3 FetchContent configuration
- [third_party/README.md](third_party/README.md) - Third-party dependency documentation
- [development/SDL3/PLAN.MD](development/SDL3/PLAN.MD) - Complete migration plan (660 lines)
- [CMakeLists.txt](CMakeLists.txt) - Build system SDL3 integration
- [src/plib/gnw/svga.cc](src/plib/gnw/svga.cc) - Graphics/rendering implementation
- [src/plib/gnw/touch.cc](src/plib/gnw/touch.cc) - Touch handling with SDL3 APIs
- [src/plib/gnw/input.cc](src/plib/gnw/input.cc) - Event handling with SDL3 event types
- [src/audio_engine.cc](src/audio_engine.cc) - SDL3 audio stream implementation
- grep search for `#include.*SDL3` - Identified all 12 files using SDL3

**Summary of what was documented**:
- Rationale for choosing SDL3 over SDL2 (modern API, Apple support, GPU rendering)
- Complete API change reference (events, rendering, audio, input)
- Platform-specific benefits for macOS and iOS
- Technical integration details (FetchContent, build configuration)
- List of all source files using SDL3
- Migration resources and version information
