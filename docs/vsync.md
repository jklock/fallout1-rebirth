# VSync and Display Settings

This document explains VSync and display settings for Fallout 1 Rebirth.

## Overview

VSync (vertical synchronization) is **enabled by default** in Fallout 1 Rebirth. This provides:

- **Eliminates screen tearing** — No visual artifacts from frame buffer misalignment
- **Matches frame rate to display refresh rate** — Smooth, consistent frame delivery
- **ProMotion support** — Automatically adapts to 120Hz iPads for buttery-smooth gameplay

VSync synchronizes the game's rendering with your display's refresh cycle, ensuring each frame is displayed completely before the next one begins.

## How It Works

### SDL2 Renderer

The game creates the SDL2 renderer with the `SDL_RENDERER_PRESENTVSYNC` flag when VSync is enabled:

```c
SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
```

### Display Refresh Rate Detection

At startup, the game logs the detected display refresh rate:

```
Display refresh rate: 120 Hz
VSync: enabled
```

This information helps verify proper configuration.

### FpsLimiter Integration

The `FpsLimiter` class provides additional frame timing control:

- With VSync **on**, the FPS limiter is mostly redundant since the GPU driver handles timing
- With VSync **off**, the FPS limiter prevents excessive frame rates and CPU/GPU usage
- The limiter can also cap frames below the display refresh rate for battery savings

## Configuration

Display settings are configured in the `[DISPLAY]` section of `f1_res.ini`:

```ini
[DISPLAY]
VSYNC=1          ; 0=off, 1=on (default)
FPS_LIMIT=-1     ; -1=match display, 0=unlimited, 60/120=fixed
```

### VSYNC Options

| Value | Effect |
|-------|--------|
| `0` | Disabled — May cause screen tearing, but lowest input latency |
| `1` | Enabled (default) — Smooth visuals, synced to display |

### FPS_LIMIT Options

| Value | Effect |
|-------|--------|
| `-1` | Match display refresh rate (default) — 60Hz or 120Hz depending on device |
| `0` | Unlimited — No frame cap (use with VSync off for benchmarking) |
| `60` | Lock to 60fps — Original game speed, good for battery savings |
| `120` | Lock to 120fps — Smooth on ProMotion displays |

### Recommended Configurations

**Default (best quality):**
```ini
VSYNC=1
FPS_LIMIT=-1
```

**Battery saver (120Hz devices):**
```ini
VSYNC=1
FPS_LIMIT=60
```

**Lowest latency (competitive):**
```ini
VSYNC=0
FPS_LIMIT=0
```

## Battery Considerations

Frame rate directly impacts power consumption:

| Configuration | Battery Impact | Notes |
|--------------|----------------|-------|
| 60Hz display | Baseline | Standard refresh rate |
| 120Hz ProMotion | Higher usage | More frames = more work |
| VSync + FPS_LIMIT=60 | Lower usage | Caps at 60fps even on 120Hz displays |

### Tips for Extended Play

1. **On 120Hz iPads**: Set `FPS_LIMIT=60` to significantly reduce battery drain
2. **Fallout was designed for 60fps**: Running at 120fps is optional and purely cosmetic
3. **VSync overhead is minimal**: Keep it enabled for visual quality

## Troubleshooting

### Screen Tearing
**Symptom:** Horizontal lines or "torn" images during scrolling

**Solution:** Ensure VSync is enabled:
```ini
VSYNC=1
```

### High Battery Drain
**Symptom:** Device gets hot, battery depletes quickly

**Solution:** Cap frame rate to 60fps:
```ini
FPS_LIMIT=60
```

### Animation Issues
**Symptom:** Animations stutter or feel inconsistent

**Solution:** Return to default settings:
```ini
VSYNC=1
FPS_LIMIT=-1
```

### Game Feels Sluggish
**Symptom:** Input feels delayed or unresponsive

**Solution:** This may be VSync input latency. If it bothers you:
```ini
VSYNC=0
FPS_LIMIT=60
```

Note: You may notice minor screen tearing with VSync disabled.

## Technical Details

### Implementation Files

| File | Purpose |
|------|---------|
| `src/plib/gnw/svga.cc` | SDL2 renderer creation, VSync flag handling |
| `src/fps_limiter.cc` | Frame timing and rate limiting logic |
| `src/fps_limiter.h` | FpsLimiter class interface |

### Development History

For implementation details and design decisions, see:

```
development/VSYNC/
```

This directory contains the VSync implementation history, testing notes, and ProMotion optimization details.

### Related Configuration

VSync settings work alongside other display options:

- **Resolution settings** — `SCREENWIDTH` / `SCREENHEIGHT` in `[MAIN]`
- **Fullscreen mode** — `FULLSCREEN` in `[MAIN]`
- **Scaling mode** — Handled by SDL2's renderer scaling
