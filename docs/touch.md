# Touch Input

## Overview
Touch input is handled by a dedicated gesture system, then converted into mouse-like actions. SDL finger events are translated into tap, pan, and long-press gestures, which `mouse_info()` consumes to move the cursor, click, drag, and scroll.

## Event Flow
1. SDL touch events are polled in `GNW95_process_message()` (src/plib/gnw/input.cc):
   - `SDL_EVENT_FINGER_DOWN` → `touch_handle_start()`
   - `SDL_EVENT_FINGER_MOTION` → `touch_handle_move()`
   - `SDL_EVENT_FINGER_UP` → `touch_handle_end()`
2. `touch_process_gesture()` analyzes active touches and pushes gestures into a queue.
3. `mouse_info()` consumes gestures via `touch_get_gesture()` and simulates cursor actions.
4. Input path selection is governed by `last_input_was_mouse` (set in `dxinput_notify_mouse/touch`): when false, gestures are consumed; when true, dxinput mouse is read instead. See [src/plib/gnw/dxinput.cc#L244-L303](src/plib/gnw/dxinput.cc#L244-L303) and [src/plib/gnw/input.cc#L1093-L1165](src/plib/gnw/input.cc#L1093-L1165).

## Coordinate Conversion
Touch coordinates are normalized by SDL (0..1). `convert_touch_to_logical()` converts these into game coordinates:
- Uses `SDL_GetWindowSize()` and `SDL_GetWindowSizeInPixels()` to obtain window points and pixel sizes.
- On iOS, uses `iOS_windowToGameCoords()` and `iOS_screenToGameCoords()` to account for the custom render destination rect and letterboxing (svga.cc).
 - If a touch lands outside the dest rect, the coordinates are clamped into game bounds to avoid out-of-range positions. See [src/plib/gnw/touch.cc#L98-L156](src/plib/gnw/touch.cc#L98-L156).

## Gesture Recognition
Implemented in src/plib/gnw/touch.cc.

### Thresholds
- `TAP_MAXIMUM_DURATION` = 200 ms
- `TAP_MAXIMUM_DURATION_MULTI` = 350 ms
- `PAN_MINIMUM_MOVEMENT` = 12 pixels
- `PAN_MINIMUM_MOVEMENT_MULTI` = 16 pixels
- `LONG_PRESS_MINIMUM_DURATION` = 500 ms

### Gesture Mapping (mouse_info)
- One-finger tap → move cursor to tap position, then LEFT-click (DOWN now, UP next tick).
- Two-finger tap → move cursor, then RIGHT-click (DOWN now, UP next tick). Used to switch cursor mode.
- Three-finger tap → move cursor, then LEFT-click.
- One-finger pan → reposition cursor; if pan starts near cursor, it drags with left button held.
- Two-finger pan → scroll wheel.
- One-finger long press → left-click drag.
- Two-finger long press → left-click drag.
 - Tap UP is deferred one frame via `pending_tap_release` in `mouse_info()` [src/plib/gnw/mouse.cc#L482-L744](src/plib/gnw/mouse.cc#L482-L744); the release now executes even if the cursor becomes hidden because `mouse_simulate_input` processes button state while hidden [src/plib/gnw/mouse.cc#L748-L858](src/plib/gnw/mouse.cc#L748-L858).

## Important Functions and State
- `touch_handle_start()`, `touch_handle_move()`, `touch_handle_end()`
  - Track per-finger state and update positions.
- `touch_process_gesture()`
  - Classifies gestures and queues them.
- `touch_get_gesture()`
  - Pops the next gesture (LIFO stack).
- `mouse_info()`
  - Converts gestures into cursor movement and clicks.
 - `mouse_simulate_input()`
   - Computes edge-triggered button state and now processes it even when the cursor is hidden; rendering is skipped when hidden to avoid double blits [src/plib/gnw/mouse.cc#L748-L858](src/plib/gnw/mouse.cc#L748-L858).

## Settings and Defaults
Touch clicks use click offsets from f1_res.ini (gameconfig/ios/f1_res.ini):
- `CLICK_OFFSET_X`, `CLICK_OFFSET_Y` are applied in `mouse_click_in()`.
 - SDL synthetic touch→mouse events are disabled (`SDL_HINT_TOUCH_MOUSE_EVENTS=0`), so touch always flows through this gesture path [src/plib/gnw/winmain.cc#L17-L38](src/plib/gnw/winmain.cc#L17-L38).

## Rationale
- Dedicated gesture handling avoids SDL synthetic touch-to-mouse events and keeps cursor mapping accurate.
- Taps generate a distinct DOWN then UP across frames to ensure UI click detection works reliably.
- Multi-touch timing and pan thresholds are tuned to avoid accidental pans and missed two-finger taps.
