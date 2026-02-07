# Bug 3: Sporadic touch/Pencil click location errors

Last updated: 2026-02-07

## Report
Touch and Apple Pencil clicks are mostly correct now, but location mismatches
still occur sporadically. Right/left/drag work but land slightly off at times.

## Suspected Triggers
- Touch points outside the iOS dest rect being clamped to edges.
- Transient switching between touch and mouse paths via last_input_was_mouse.
- iOS_windowToGameCoords() conversion mismatch during window-size changes.

## Relevant Code
- docs/touch.md, docs/pencil.md, docs/mouse.md
- src/plib/gnw/touch.cc: convert_touch_to_logical(), gesture thresholds.
- src/plib/gnw/svga.cc: iOS_windowToGameCoords(), iOS_screenToGameCoords().
- src/plib/gnw/dxinput.cc: last_input_was_mouse switching and pointer conversion.
- src/plib/gnw/mouse.cc: pending_tap_release, click offsets.

## Repro Checklist
1) iPad with finger + Pencil
2) Tap near edges and in letterboxed regions
3) Observe sporadic offsets in click hit-testing

## Actionable Fix Direction (No Simulator-Only Logging)
1) Ignore out-of-bounds touch starts instead of clamping:
   - In `src/plib/gnw/touch.cc`, have `convert_touch_to_logical()` return
     an `in_bounds` flag from `iOS_windowToGameCoords()`.
   - If a touch starts out-of-bounds, mark it as invalid and skip gesture
     processing for that finger. This prevents taps in letterbox bars from
     snapping to the nearest edge (sporadic offset).
2) Keep drags stable when leaving the dest rect:
   - If a touch starts in-bounds but moves out, clamp *movement* to last
     in-bounds position rather than snapping to the edge.
3) Unify mapping for touch + mouse:
   - Consider a shared helper (window→render→game) that both `touch.cc` and
     `dxinput.cc` use so rounding is consistent across input types.
4) Ensure dest rect stays current:
   - With the iOS window-size fix from Bug 1, keep `iOS_updateDestRect()`
     running on actual size changes so coordinate transforms stay accurate.
