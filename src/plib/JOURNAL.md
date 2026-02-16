# JOURNAL: src/plib/

Last Updated: 2026-02-14

## Purpose

Platform and UI layer using SDL3. Provides graphics rendering, input handling (mouse, keyboard, touch), window management, and low-level system abstractions.

## Recent Activity

### 2026-02-14
- Added compile-time no-op patch logging macros in `db/patchlog.h` under `F1R_DISABLE_RME_LOGGING` so release builds can disable diagnostics cleanly.
- Added audit comment explaining why patch logging callsites are preserved while disabled in release mode.
- Added explicit `F1R AUDIT NOTE` rationale comments in `db.cc`, `gnw.cc`, `memory.cc`, `svga.cc`, and `winmain.cc`.

### 2026-02-07
- Extensive touch input refinements in `gnw/touch.cc`
- Tap/pan threshold tuning for better responsiveness
- Long-press drag implementation
- Mouse fallback system for hybrid input
- SDL3 renderer optimizations in `gnw/svga.cc`

### Previous
- SDL3 migration completed (from SDL2)
- VSync enabled by default
- Touch coordinate mapping fixes for iOS

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `gnw/` | Graphics, input, windowing (main UI layer) |
| `color/` | Color palette management |
| `db/` | Database/file access |
| `assoc/` | Associative data structures |

## Key Files

| File | Purpose |
|------|---------|
| `gnw/svga.cc` | SDL3 rendering, window management |
| `gnw/mouse.cc` | Mouse input, cursor management |
| `gnw/touch.cc` | Touch input processing |
| `gnw/dxinput.cc` | SDL3 event polling, input dispatch |
| `gnw/input.cc` | Input queue management |
| `gnw/kb.cc` | Keyboard handling |
| `gnw/gnw.cc` | Window system, UI framework |
| `gnw/button.cc` | UI button handling |
| `gnw/text.cc` | Text rendering |

## Development Notes

### For AI Agents

1. **Input Flow**: SDL events → `dxinput.cc` → `mouse.cc` / `touch.cc` → `input.cc`
2. **Touch System**: Complex state machine in `touch.cc` - read carefully before changes
3. **SDL3 APIs**: This uses SDL3 (not SDL2) - API differences exist
4. **Coordinate Systems**: Screen coords ≠ game coords - watch for scaling

### Touch Input Architecture (gnw/touch.cc)

```
Touch Event Flow:
SDL_EVENT_FINGER_DOWN → Track finger, start timer
  ↓
Movement detected?
  ├─ Small movement + short time → TAP (click)
  ├─ Large movement → PAN (drag/scroll)
  └─ Long press → LONG_PRESS_DRAG
  ↓
SDL_EVENT_FINGER_UP → Finalize gesture, emit mouse events
```

Key thresholds (tune in touch.cc):
- `TAP_DISTANCE_THRESHOLD` - max movement for tap
- `TAP_TIME_THRESHOLD` - max duration for tap
- `LONG_PRESS_THRESHOLD` - time before long-press drag

### Mouse Fallback System

When touch is released, mouse position is preserved for UI elements that expect continuous cursor presence. This prevents "lost cursor" issues.

### Rendering (gnw/svga.cc)

- Uses SDL3 GPU-accelerated rendering
- VSync controlled via SDL_RENDERER_VSYNC
- Frame buffer scaled to window size
- Game renders at 640x480 internal resolution

### Testing Touch Changes

```bash
./scripts/test/test-ios-simulator.sh
```

Touch testing requires iOS Simulator - use Option+click to simulate touch.
