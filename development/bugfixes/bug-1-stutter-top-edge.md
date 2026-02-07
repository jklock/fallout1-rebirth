# Bug 1: Cursor-at-top stutter + audio glitches

Last updated: 2026-02-07

## Report
Moving the cursor to the top edge (to scroll the map up) causes stutter/lag,
and audio glitches at the same time.

## Suspected Triggers
- iOS status bar / safe-area reveal when pointer hits the top edge.
- SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED firing repeatedly and triggering
  handleWindowSizeChanged() which destroys/recreates the renderer and stalls.
- win_refresh_all() on each size-change event when the status bar toggles.

## Relevant Code
- src/plib/gnw/input.cc: handles SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED and
  calls handleWindowSizeChanged() + win_refresh_all().
- src/plib/gnw/svga.cc: handleWindowSizeChanged() destroys and recreates
  the renderer and updates iOS dest rect.
- src/plib/gnw/mouse.cc: mouse_simulate_input() calls win_refresh_all()
  and mouse_show() when cursor moves.

## Repro Checklist
1) iPad + trackpad/mouse
2) Move cursor to top edge repeatedly
3) Observe frame stutter and audio glitches
4) Note if the status bar shows/hides while reproducing

## Actionable Fix Direction (No Simulator-Only Logging)
1) Make iOS window-size changes *lightweight* (no renderer rebuilds):
   - In `src/plib/gnw/svga.cc`, change `handleWindowSizeChanged()` so that
     iOS only updates the dest rect (and optionally caches last pixel size),
     instead of calling `destroyRenderer()`/`createRenderer()`.
   - Renderer + texture are sized to game resolution and do not need to
     rebuild when the fullscreen window size changes.
2) Debounce refresh on iOS:
   - Track `last_window_pw/ph` and only act when pixel size actually changes.
   - In `src/plib/gnw/input.cc` for `SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED`,
     avoid `win_refresh_all()` every time; only refresh if the dest rect
     changed or schedule a single refresh on the next frame.
3) Optional UIKit fix if needed:
   - Lock status bar visibility in the iOS app (Info.plist / view controller)
     so top-edge pointer movement does not trigger safe-area changes.

## Notes
Audio stutter points to a main-thread stall; renderer rebuild + full refresh
on repeated size-change events is the most likely offender.
