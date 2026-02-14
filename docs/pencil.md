# Apple Pencil Input

## Overview
Apple Pencil is supported on iOS via native UIKit hooks. The pencil is detected separately from finger touches, and pencil body gestures (double-tap/squeeze) are mapped to right-click behavior.

## Event Flow
1. `pencil_init()` is called in `svga_init()` on iOS (src/plib/gnw/svga.cc).
2. A custom `PencilObserver` gesture recognizer tracks UITouch events and sets pencil state (src/platform/ios/pencil.mm).
3. Pencil body gestures are captured via `UIPencilInteraction` and queued.
4. Each frame, `GNW95_process_message()` polls `pencil_poll_gesture()` and triggers a right-click if enabled (src/plib/gnw/input.cc).
5. `mouse_info()` uses `pencil_is_active()` to adjust touch drag behavior when the pencil is the current input device.
 6. Screen contact from Pencil flows through the same touch-gesture path as fingers; taps/long-press/pans are converted in `mouse_info()` with the same deferred-release model for taps and continuous drag handling for pans/long-press [src/plib/gnw/mouse.cc#L482-L744](src/plib/gnw/mouse.cc#L482-L744).

## Native Implementation (pencil.mm)
- `PencilObserver` (UIGestureRecognizer)
  - Observes all touches without blocking SDL.
  - Sets `g_last_touch_was_pencil`, `g_pencil_touching`, `g_pencil_position`, and pressure.
- `UIPencilInteraction`
  - Double-tap and squeeze gestures enqueue `PENCIL_GESTURE_DOUBLE_TAP` or `PENCIL_GESTURE_SQUEEZE`.

## Public C API (pencil.h)
- `pencil_init(void* sdl_window)`
- `pencil_shutdown()`
- `pencil_is_active()`
- `pencil_is_touching()`
- `pencil_get_position(int* x, int* y)`
- `pencil_get_pressure()`
- `pencil_poll_gesture()`
- `pencil_update_position(float x, float y)` (currently not used by the input path)

## Settings and Defaults
- `pencil_right_click` (fallout.cfg / game_config)
  - Engine default is 1 (enabled) in `src/game/gconfig.cc`.
  - Shipped iOS template sets `pencil_right_click=0` for precision-first default behavior.
  - When enabled, pencil body gestures trigger a right-click at the current cursor position.
 - Screen-contact behavior is unaffected by this toggle: Pencil pans always start a drag, and releases follow the gesture `kEnded` path even if the cursor hides while dragging, because button state is processed while hidden [src/plib/gnw/mouse.cc#L748-L858](src/plib/gnw/mouse.cc#L748-L858).

## Rationale
- Pencil detection via UIKit is required because SDL does not distinguish Apple Pencil from finger touches.
- Pencil body gestures are mapped to right-click so users can access the same cursor mode switching as a mouse right-click.
- Pencil input uses the same gesture-to-cursor path as touch for consistent coordinate mapping.
