# Bug 2: Screen tearing when using arrow keys to move cursor

Last updated: 2026-02-07

## Report
Using arrow keys to move the cursor causes visible tearing. The tearing goes
away after loading a save.

## Suspected Triggers
- Arrow keys call `map_scroll()` directly (see `src/game/game.cc`).
- `map_scroll()` uses a memmove-based scroll on the display buffer, then
  partial redraw. On iOS this can leave visible shear artifacts until a
  full redraw (loading a save forces a full refresh).

## Relevant Code
- src/game/game.cc: arrow keys → `map_scroll(dx, dy)`.
- src/game/map.cc: `map_scroll()` memmove + partial refresh + `win_draw()`.
- src/plib/gnw/svga.cc: present path via `renderPresent()`.

## Repro Checklist
1) Start game, use arrow keys to move cursor
2) Observe tearing while moving
3) Load a save; observe tearing disappears

## Actionable Fix Direction (No Simulator-Only Logging)
1) Treat keyboard scroll as a *full redraw* on iOS:
   - In `src/game/game.cc`, after `map_scroll(...)` for `KEY_ARROW_*`,
     force a full refresh (e.g. `tile_refresh_display()` + `win_draw(display_win)`).
   - Alternative: add an iOS-only path inside `map_scroll()` that skips the
     memmove optimization and instead does `tile_refresh_display()`.
2) Keep mouse-edge scroll on the fast path:
   - Add a helper `map_scroll_and_full_refresh(dx, dy)` and call it only
     from arrow key handling to avoid penalizing normal mouse scrolling.
3) Ensure the refresh actually presents:
   - If needed, call `renderPresent()` immediately after the forced redraw
     on iOS to avoid a stale frame before the main loop present.
