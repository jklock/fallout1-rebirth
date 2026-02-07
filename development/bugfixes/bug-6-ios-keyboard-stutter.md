# Bug 6: iOS on-screen keyboard stutter (text input)

Last updated: 2026-02-07

## Report
When the on-screen keyboard appears for text input, the game stutters/lag
spikes. There are only a few text-input screens, but the stutter is
noticeable during keyboard show/hide transitions.

## Suspected Triggers
- Keyboard appearance changes the view/frame, causing SDL to emit window
  size change events. Our `SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED` handler
  rebuilds the renderer and triggers `win_refresh_all()`, which stalls.
- We do not currently handle `SDL_EVENT_SCREEN_KEYBOARD_SHOWN/HIDDEN`, so
  we treat keyboard-driven size changes as full window resizes.
- Text input might be started/stopped repeatedly, causing multiple keyboard
  transitions and repeated renderer rebuilds.

## Relevant Code / Config
- src/plib/gnw/input.cc:
  - `SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED` calls `handleWindowSizeChanged()`
    and `win_refresh_all()`.
  - `beginTextInput()` / `endTextInput()` wrappers exist but are not
    referenced elsewhere yet.
- src/plib/gnw/svga.cc: `handleWindowSizeChanged()` destroys/recreates the
  renderer and updates the iOS dest rect.
- build-ios/_deps/sdl3-src/src/video/uikit/SDL_uikitviewcontroller.m:
  keyboard show/hide adjusts the view frame and calls
  `SDL_SendScreenKeyboardShown/Hidden()`.

## Repro Checklist
1) iPad with no hardware keyboard attached.
2) Trigger a text input UI (save name, character name, etc.).
3) Observe stutter during keyboard show/hide and/or while typing.

## Investigation Tasks
- Identify where text input is started in-game and ensure
  `beginTextInput()` / `endTextInput()` are paired around actual input
  prompts (no extra toggles).
- Log SDL events during keyboard transitions to see which events fire:
  `SDL_EVENT_SCREEN_KEYBOARD_SHOWN/HIDDEN`, `SDL_EVENT_WINDOW_RESIZED`,
  `SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED`.
- Measure how many size-change events fire during the keyboard animation.

## Candidate Fix Directions
1) On iOS, treat keyboard-driven size changes as lightweight: update the
   dest rect and debounce refresh instead of rebuilding the renderer.
2) Track a `keyboard_visible` flag via `SDL_EVENT_SCREEN_KEYBOARD_*` and
   suppress repeated `handleWindowSizeChanged()` calls during transitions.
3) Ensure text input is only active during real input prompts to avoid
   multiple keyboard show/hide cycles.
