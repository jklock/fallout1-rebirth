# Mouse Input

## Overview
Mouse and trackpad input are handled through SDL events and translated into Fallout’s internal mouse state. On macOS the mouse is relative (deltas); on iOS mouse/trackpad is absolute, then converted into game coordinates. The mouse path is separate from touch gestures and is selected when `dxinput_is_using_mouse()` is true.

## Event Flow
1. SDL events are polled in `GNW95_process_message()` (src/plib/gnw/input.cc).
2. Mouse events call `dxinput_notify_mouse()` and `handleMouseEvent()`.
3. `mouse_info()` (src/plib/gnw/mouse.cc) runs each tick:
   - If `dxinput_is_using_mouse()` is true, it calls `dxinput_get_mouse_state()` and forwards deltas/buttons to `mouse_simulate_input()`.
   - If false, it consumes touch gestures (see touch.md).
  - The `last_input_was_mouse` flag is flipped by `dxinput_notify_mouse()` and `dxinput_notify_touch()` [src/plib/gnw/dxinput.cc#L272-L304](src/plib/gnw/dxinput.cc#L272-L304), so a touch event switches the path to gestures until another real mouse event arrives.

## Key Functions
- `GNW95_process_message()`
  - Routes SDL mouse events to the mouse subsystem.
- `handleMouseEvent(SDL_Event*)`
  - Tracks wheel deltas and button-down/up state on iOS.
- `dxinput_get_mouse_state(MouseData*)`
  - macOS: uses `SDL_GetRelativeMouseState()` to get deltas.
  - iOS: uses `SDL_GetMouseState()` (absolute), converts window coordinates to render pixels via `SDL_RenderCoordinatesFromWindow()` or window-pixel scaling, then maps into game coordinates using `iOS_screenToGameCoords()`.
- `mouse_info()`
  - Central per-frame update: pulls mouse state or touch gestures.
- `mouse_simulate_input(int dx, int dy, int buttons)`
  - Updates internal cursor position and button edge flags (`MOUSE_EVENT_LEFT_BUTTON_DOWN/UP/REPEAT`, etc.).
   - Button/edge computation now runs even when the cursor is hidden; only rendering/blitting is skipped while hidden so hidden-drag state still updates [src/plib/gnw/mouse.cc#L748-L858](src/plib/gnw/mouse.cc#L748-L858).
- `mouse_click_in(...)`, `mouse_in(...)`, `mouse_get_position(...)`, `mouse_set_position(...)`
  - Hit-test and cursor query helpers used across UI/game logic.

## Important State
- `mouse_x`, `mouse_y`, `mouse_hotx`, `mouse_hoty`: cursor position and hotspot.
- `mouse_buttons`, `raw_buttons`, `last_buttons`: button state and edge-triggered events.
- `gMouseWheelDeltaX/Y` (dxinput) and `gMouseWheelX/Y` (mouse.cc).
- `last_input_was_mouse`: set by `dxinput_notify_mouse()` and `dxinput_notify_touch()`.

## Settings and Defaults
Configuration is loaded from f1_res.ini (see gameconfig/ios/f1_res.ini).
- `CLICK_OFFSET_X`, `CLICK_OFFSET_Y`
  - Applied in `mouse_click_in()` for touch calibration.
- `CLICK_OFFSET_MOUSE_X`, `CLICK_OFFSET_MOUSE_Y`
  - Applied in `mouse_click_in()` when `dxinput_is_using_mouse()` is true on iOS.
- `ALT_MOUSE_INPUT`, `EXTRA_WIN_MSG_CHECKS`, `SCROLLWHEEL_FOCUS_PRIMARY_MENU`
  - Present in config; currently treated as legacy/compatibility keys in the iOS config.

## Platform-Specific Behavior
- iOS disables SDL synthetic touch-to-mouse events (set in src/plib/gnw/winmain.cc), so touch input only flows through the gesture system.
- iOS mouse/trackpad uses absolute coordinates and is mapped through the iOS render destination rect (see iOS helpers in svga.cc).
 - Hidden cursor: state updates (buttons, position, edge flags) still process; drawing is skipped when hidden. Tap releases that arrive on the next frame are therefore not dropped when the cursor hides mid-frame.

## Rationale
- Separate mouse and touch paths avoid double-processing and inconsistent state.
- Distinct click offsets for touch vs mouse prevent double compensation on iOS.
- Edge-triggered button events in `mouse_simulate_input()` mirror classic Fallout input handling and are relied on by UI code for click detection.
