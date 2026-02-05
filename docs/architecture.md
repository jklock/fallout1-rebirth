# Architecture

Codebase structure, engine internals, and development patterns for Fallout 1 Rebirth.

## Table of Contents

- [High-Level Overview](#high-level-overview)
- [Directory Structure](#directory-structure)
- [Engine Architecture](#engine-architecture)
- [Script Interpreter System](#script-interpreter-system)
- [Platform Layer](#platform-layer)
- [Key Entry Points](#key-entry-points)
- [How Files Work Together](#how-files-work-together)
- [Adding New Features](#adding-new-features)
- [Code Conventions](#code-conventions)

---

## High-Level Overview

Fallout 1 Rebirth is a C++17 re-implementation of the original Fallout engine. The codebase is organized into three main layers:

```
+--------------------------------------------------+
|                   Game Layer                     |
|   (src/game/) - Combat, Dialog, Inventory, etc.  |
+--------------------------------------------------+
|               Interpreter Layer                  |
|   (src/int/) - Script VM, Opcodes, Windows       |
+--------------------------------------------------+
|               Platform Layer                     |
|   (src/plib/) - Graphics, Input, Audio, DB       |
+--------------------------------------------------+
|                     SDL3                         |
+--------------------------------------------------+
```

### Key Characteristics

- **C++17 Standard**: Modern C++ with C-style memory management
- **Namespace**: All code resides in the `fallout` namespace
- **Platform**: Apple-only (macOS 11.0+, iOS/iPadOS 15.0+)
- **Graphics**: SDL3-based rendering with GPU-accelerated scaling
- **Audio**: SDL3 audio streams with custom ACM decoder

---

## Directory Structure

### Root Level

| Directory | Purpose |
|-----------|---------|
| `src/` | Main source code |
| `os/` | Platform-specific resources (Info.plist, icons, storyboards) |
| `cmake/` | CMake toolchains and configuration |
| `third_party/` | Bundled dependencies (SDL3, adecode, fpattern) |
| `dist/` | Distribution files for packaging |
| `scripts/` | Build and development automation scripts |
| `gameconfig/` | Platform-specific configuration templates (iOS and macOS) |
| `development/` | Internal development documentation (not user-facing) |

### Source Code (`src/`)

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| `src/game/` | Core game logic | `main.cc`, `game.cc`, `combat.cc`, `map.cc` |
| `src/int/` | Script interpreter | `intrpret.cc`, `intlib.cc`, `support/intextra.cc` |
| `src/plib/` | Platform abstraction | `gnw/`, `db/`, `color/`, `assoc/` |
| `src/platform/` | Platform-specific code | Platform abstractions |

### Top-Level Source Files

| File | Purpose |
|------|---------|
| `audio_engine.cc/h` | SDL-based audio engine wrapper |
| `fps_limiter.cc/h` | Frame rate limiting with configurable FPS |
| `movie_lib.cc/h` | MVE video playback library |
| `platform_compat.cc/h` | Cross-platform compatibility utilities |
| `pointer_registry.cc/h` | Pointer tracking for serialization |

---

## Engine Architecture

### Game Loop

The main game loop is in `src/game/main.cc`:

```
main()
  -> main_init_system()     # Initialize subsystems
  -> main_menu_loop()       # Main menu
  -> main_game_loop()       # Core game loop
  -> main_exit_system()     # Cleanup
```

The core game loop (`main_game_loop`) handles:

1. **Input Processing**: Keyboard, mouse, touch events via GNW
2. **Script Execution**: Run active scripts and check triggers
3. **Animation Updates**: Process animation frames and combat sequences
4. **World Updates**: Handle timed events, queued actions
5. **Rendering**: Compose scene and present to screen

### Initialization Sequence

```cpp
main_init_system()
  -> GNW95_init_mode()      # Initialize graphics mode
  -> init_input()           # Setup input handling
  -> soundInit()            # Initialize audio
  -> game_init()            # Initialize game subsystems
    -> proto_init()         # Load prototypes
    -> skill_init()         # Initialize skills
    -> perk_init()          # Initialize perks
    -> intface_init()       # Initialize interface
    -> scripts_init()       # Initialize script system
```

### Rendering Pipeline

1. **Background**: Map tiles rendered to backbuffer
2. **Objects**: Sprites sorted by position and rendered
3. **Interface**: HUD elements overlaid
4. **Cursor**: Mouse cursor drawn last
5. **Present**: Frame presented via SDL

The rendering uses palette-based graphics (256 colors) with GPU-accelerated texture scaling.

**Frame Timing**:
- VSync is enabled by default via `SDL_SetRenderVSync()`
- `FpsLimiter` class in `fps_limiter.cc` handles frame rate control
- Display refresh rate is logged at startup
- SDL3 provides native Metal rendering on Apple platforms

Key files:

- `src/plib/gnw/svga.cc` - Screen management
- `src/plib/gnw/grbuf.cc` - Graphics buffer operations
- `src/game/display.cc` - Game scene composition
- `src/game/tile.cc` - Isometric tile rendering

### Input Handling

Input flows through the GNW (Game Nucleus Windowing) system:

```
SDL Events -> GNW Input Queue -> Game Handlers
```

Key files:
- `src/plib/gnw/input.cc` - Input queue management
- `src/plib/gnw/gnw.cc` - Window and event management
- `src/game/gmouse.cc` - Game mouse handling

#### Touch Input (iOS/iPadOS)

- `src/plib/gnw/touch.cc` handles touch input for iOS/iPadOS
- Uses `SDL_RenderWindowToLogical` for coordinate transformation
- Touch coordinates are normalized (0.0-1.0) by SDL, then converted to logical coordinates
- Same transformation path as mouse input in `dxinput.cc`

#### Apple Pencil Support (iOS/iPadOS)

Apple Pencil is **fully supported** as of version 1.0:

- `src/platform/ios/pencil.h` and `pencil.mm` provide native iOS detection
- Pencil-specific input path in `src/plib/gnw/mouse.cc` using `UITouch.type`
- Distinguishes pencil from finger via iOS-specific APIs (SDL2 cannot detect this natively)
- Configurable behaviors via `f1_res.ini` `[PENCIL]` section
- Gesture support: tap, drag, long-press, double-tap (body), squeeze (Pro)

See [setup_guide.md](../docs/setup_guide.md) for Apple Pencil configuration options.

### Audio System

```
Game Sound Calls -> gsound.cc -> audio_engine.cc -> SDL3 Audio Streams
                                   |
                                   v
                              ACM Decoder (for music)
```

---

## Script Interpreter System

The `src/int/` directory contains the script virtual machine that executes Fallout's SSL (Script Source Language) compiled scripts.

### Architecture

```
+-------------------+     +-------------------+
|   Game Scripts    |     |  Dialog Scripts   |
|   (.int files)    |     |   (.int files)    |
+-------------------+     +-------------------+
           |                       |
           v                       v
+------------------------------------------+
|          Script Interpreter              |
|              (intrpret.cc)               |
|  - Stack-based VM                        |
|  - ~342 opcodes                          |
|  - Multiple concurrent programs          |
+------------------------------------------+
           |
           v
+------------------------------------------+
|            Opcode Handlers               |
|           (support/intextra.cc)          |
|  - Game-specific operations              |
|  - Registered via interpretAddFunc()    |
+------------------------------------------+
```

### Key Files

| File | Purpose |
|------|---------|
| `intrpret.cc` | Core interpreter loop and VM |
| `intlib.cc` | Standard library functions |
| `support/intextra.cc` | Fallout-specific opcodes |
| `export.cc` | Export/import system |

### Adding a New Opcode

1. Define the handler function in `intextra.cc`:

```cpp
static void op_my_new_function(Program* program)
{
    // Pop arguments from stack (in reverse order)
    int arg = programStackPopInteger(program);
    
    // Do work
    int result = someGameFunction(arg);
    
    // Push result
    programStackPushInteger(program, result);
}
```

2. Register the opcode in `intExtraInit()`:

```cpp
interpretAddFunc(0x80XX, op_my_new_function);
```

---

## Platform Layer

The `src/plib/` directory provides platform abstraction through several subsystems:

### GNW (Game Nucleus Windowing)

| File | Purpose |
|------|---------|
| `gnw/gnw.cc` | Window management |
| `gnw/input.cc` | Input queue |
| `gnw/svga.cc` | Screen/display management |
| `gnw/grbuf.cc` | Graphics buffer operations |
| `gnw/text.cc` | Text rendering |
| `gnw/memory.cc` | Memory allocation wrappers |
| `gnw/debug.cc` | Debug output |

### Database Layer

| File | Purpose |
|------|---------|
| `db/db.cc` | File access and DAT archive handling |

### Color System

| File | Purpose |
|------|---------|
| `color/color.cc` | Palette and color management |

---

## Key Entry Points

### Application Entry

- **`src/game/main.cc`**: Contains `main()` and the main loop
  - `main_init_system()` - Initialize all subsystems
  - `main_game_loop()` - Core game loop
  - `main_exit_system()` - Cleanup

### Game State Management

- **`src/game/game.cc`**: Game state initialization and management
  - `game_init()` - Initialize game subsystems
  - `game_reset()` - Reset for new game
  - `game_exit()` - Cleanup game state

### Map/World

- **`src/game/map.cc`**: Map loading and management
- **`src/game/worldmap.cc`**: World map (travel between locations)

### Combat

- **`src/game/combat.cc`**: Turn-based combat system
- **`src/game/combatai.cc`**: AI decision making

### Interface

- **`src/game/intface.cc`**: Main game interface (HUD)
- **`src/game/inventry.cc`**: Inventory screen
- **`src/game/gdialog.cc`**: Dialog system

---

## How Files Work Together

### Example: Loading a Map

```
User clicks location on world map
    |
    v
worldmap.cc: wmAreaMarkVisitedState()
    |
    v
map.cc: map_load()
    |
    +-> db.cc: Load map file from data/maps/
    +-> tile.cc: Initialize tile grid
    +-> object.cc: Create map objects
    +-> scripts.cc: Initialize map scripts
    |
    v
display.cc: Render new map
```

### Example: Combat Turn

```
combat.cc: combat_turn()
    |
    +-> combatai.cc: AI decides action (if NPC)
    +-> actions.cc: Execute action (move, attack, use item)
    +-> anim.cc: Play animation
    +-> gsound.cc: Play sound effects
    +-> display.cc: Update display
```

---

## Adding New Features

### Adding a New Source File

1. Create the `.cc` and `.h` files in the appropriate directory
2. Add to `CMakeLists.txt` under `target_sources`:

```cmake
target_sources(${EXECUTABLE_NAME} PUBLIC
    # ... existing files ...
    "src/game/my_new_file.cc"
    "src/game/my_new_file.h"
)
```

3. Use the standard header guard pattern:

```cpp
#ifndef FALLOUT_GAME_MY_NEW_FILE_H_
#define FALLOUT_GAME_MY_NEW_FILE_H_

namespace fallout {

// Your code here

} // namespace fallout

#endif // FALLOUT_GAME_MY_NEW_FILE_H_
```

### Adding a New Game Feature

1. **Identify affected subsystems**: Which files need changes?
2. **Implement core logic**: Add to appropriate `src/game/` file
3. **Add script support**: If scriptable, add opcodes to `intextra.cc`
4. **Update interface**: Modify UI files as needed
5. **Test thoroughly**: Use simulator and device testing

### Modifying Existing Behavior

1. Search for the relevant function using grep or IDE
2. Understand the call chain (use `list_code_usages` or grep)
3. Make minimal, targeted changes
4. Test for regressions

---

## Code Conventions

### File Naming

- Lowercase with underscores: `my_new_file.cc`
- Header and implementation pairs: `file.h`, `file.cc`
- Header guards: `FALLOUT_<PATH>_H_`

### Code Style

The project uses WebKit-based formatting (see `.clang-format`):

```cpp
namespace fallout {

// Constants
#define MY_CONSTANT 42

// Functions
static int myHelperFunction(int arg)
{
    if (arg > 0) {
        return arg * 2;
    }
    return 0;
}

// Public function
int publicFunction(int value)
{
    return myHelperFunction(value);
}

} // namespace fallout
```

### Memory Management

- C-style memory allocation (`malloc`, `free`, `mem_malloc`, `mem_free`)
- Extensive use of global state and `extern` declarations
- Avoid complex RAII patterns without thorough testing

### Debugging

Use the built-in debug functions:

```cpp
#include "plib/gnw/debug.h"

// Debug output (development only)
debug_printf("Value is: %d\n", value);

// Error conditions
if (error_condition) {
    dbg_error("game", "Something went wrong: %d", error_code);
}

// Fatal errors
if (fatal_condition) {
    GNWSystemError("Fatal error message");
}
```

### Logging Levels

| Function | Usage |
|----------|-------|
| `debug_printf()` | Development debug output |
| `dbg_error()` | Non-fatal errors |
| `GNWSystemError()` | Fatal errors (terminates) |
---

## Proof of Work

- **Timestamp**: February 5, 2026
- **Files verified**:
  - `CMakeLists.txt` - Confirmed iOS deployment target 15.0, macOS 11.0
  - `third_party/sdl3/CMakeLists.txt` - Confirmed SDL3 3.2.4
  - `src/plib/gnw/svga.cc` - Confirmed SDL3 includes and `SDL_SetRenderVSync()` usage
- **Updates made**:
  - Changed SDL2 → SDL3 throughout document
  - Updated iOS deployment target from 14.0 to 15.0
  - Updated rendering description (GPU-accelerated vs software blitting)
  - Updated VSync implementation details (`SDL_SetRenderVSync()` vs `SDL_RENDERER_PRESENTVSYNC`)
  - Updated audio system description (SDL3 Audio Streams)
  - Added Metal rendering note for Apple platforms
