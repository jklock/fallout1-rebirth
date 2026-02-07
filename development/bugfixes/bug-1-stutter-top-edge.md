# Bug 1: Cursor-at-top stutter + audio glitches

Last updated: 2026-02-07

## Report
Moving the cursor to the top edge (to scroll the map up) causes stutter/lag,
and audio glitches at the same time.

## Suspected Triggers
- iOS status bar / safe-area reveal when pointer hits the top edge.
- SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED firing repeatedly and triggering
  handleWindowSizeChanged() which destroys/recreates the renderer.
- Excessive win_refresh_all() + mouse_show() when cursor is forced to the edge.

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

## Instrumentation Ideas
- Log SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED frequency and window sizes.
- Log handleWindowSizeChanged() calls to confirm if renderer recreation
  is happening during the stutter.
- Log win_refresh_all calls during edge scrolling.

## Candidate Fixes
- On iOS, debounce handleWindowSizeChanged() to only react when size
  changes persist for N frames.
- Ignore pixel size changes that match the safe-area toggling range.
- Lock status bar visibility (Info.plist / UIKit) so the cursor
  never triggers a resize.

## Notes
This looks like a main-thread stall (audio stutter is a side effect), so
focus on expensive work triggered by top-edge pointer movement.

