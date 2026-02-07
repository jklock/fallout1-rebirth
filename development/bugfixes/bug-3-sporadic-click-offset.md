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

## Instrumentation Ideas
- Log in-bounds vs clamped conversions in convert_touch_to_logical().
- Track last_input_was_mouse transitions around touch events.
- Log dest rect values on each window-size change to confirm stability.

## Candidate Fixes
- Treat touches outside the dest rect as no-op (do not clamp to edge),
  or provide visual feedback that tap was out-of-bounds.
- Harden last_input_was_mouse transitions: avoid switching to mouse path
  mid-gesture.
- Verify any remaining click offsets (CLICK_OFFSET_X/Y, CLICK_OFFSET_MOUSE_X/Y)
  are applied only once per path.

