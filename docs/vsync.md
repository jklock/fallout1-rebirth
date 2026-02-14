# VSync and Frame Pacing

This document describes the current runtime behavior for VSync and frame pacing.

## Current Behavior

- SDL renderer VSync is enabled at renderer initialization (`src/plib/gnw/svga.cc`).
- The shared `FpsLimiter` object exists and is used by many game loops.
- Current runtime does **not** parse `VSYNC`/`FPS_LIMIT` keys from `f1_res.ini`.

## Where It Is Set

Renderer setup enables VSync:

```c
SDL_SetRenderVSync(gSdlRenderer, 1);
```

## Configuration Reality

`f1_res.ini` currently controls:

- `[MAIN]`: `SCR_WIDTH`, `SCR_HEIGHT`, `WINDOWED`, `EXCLUSIVE`, `SCALE_2X`
- `[INPUT]`: `CLICK_OFFSET_X`, `CLICK_OFFSET_Y`, `CLICK_OFFSET_MOUSE_X`, `CLICK_OFFSET_MOUSE_Y`

There is no runtime parser for a `[DISPLAY]` section today.

## Notes

- If you need configurable frame pacing in the future, it requires code changes to parse and apply user settings at runtime.
- For complete configuration coverage, see `docs/configuration.md`.
