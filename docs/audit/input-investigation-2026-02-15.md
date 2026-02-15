# Input Investigation - 2026-02-15

## Status Update (Post-Implementation)

This document started as an investigation snapshot. Several items listed below are now resolved:

- Baseline config compatibility is complete and validated:
  - `fallout.cfg`: `55/55 PASS`
  - `f1_res.ini`: `6/6 PASS`
  - Combined: `61/61 PASS`
- `VSYNC` and `FPS_LIMIT` are now wired and verified via per-key runtime-effect tests.
- Release artifact status is now current:
  - `releases/prod/macOS/Fallout 1 Rebirth.app` exists and is refreshed.
  - `releases/prod/iOS/fallout1-rebirth.ipa` is refreshed and now includes `fallout.cfg` + `f1_res.ini`.
- Template/package alignment is enforced by:
  - `scripts/test/test-rme-config-packaging.sh`
  - `docs/audit/config-packaging-alignment-2026-02-15.md`

Authoritative pass/fail evidence is tracked in:
- `docs/audit/results.md`
- `docs/audit/config-key-coverage-matrix-2026-02-15.md`
- `dev/state/latest-summary.tsv`
- `dev/state/history.tsv`

## 1) Historical Snapshot at Investigation Start

### Repository and build state
- Branch/head: `RME-DEV` at `571d15d`.
- Local modified file: `src/plib/gnw/winmain.cc` (iOS missing-files path exits via `exit(EXIT_FAILURE)` after the alert).
- At investigation start, iOS artifact was `releases/prod/iOS/fallout1-rebirth.ipa` (SHA-256 `86bf8e721bc1ad1ba187598f6d8a758afd72b47f3e6629c2635159baed3da70c`).
- At investigation start, macOS release folder had no packaged `.app` in `releases/prod/macOS/`.

### User-facing issues currently tracked
- iPad input regression: after latest IPA, user reports all input paths (touchpad, pencil, touch) non-functional.
- Pencil-specific instability before full input failure: intermittent jump toward upper-left quadrant and occasional click at stale previous position during drag.
- Prior iOS preflight behavior gap: missing-game-files alert showed, but app did not terminate cleanly.
- Config/expectation mismatch: several keys exposed in distributed `dist/*/f1_res.ini` are not consumed by runtime code, causing settings to appear ignored.

### Concrete proof points
- iOS preflight and explicit termination path is implemented in `src/plib/gnw/winmain.cc:99` and `src/plib/gnw/winmain.cc:116`.
- Synthetic touch->mouse and mouse->touch are disabled at startup in `src/plib/gnw/winmain.cc:87` and `src/plib/gnw/winmain.cc:88`.
- iOS mouse event filtering excludes both `SDL_TOUCH_MOUSEID` and `SDL_PEN_MOUSEID` in `src/plib/gnw/input.cc:1110`, `src/plib/gnw/input.cc:1121`, `src/plib/gnw/input.cc:1132`, `src/plib/gnw/input.cc:1143`.
- iOS coordinate mapping and out-of-bounds suppression occur in `src/plib/gnw/dxinput.cc:144` and `src/plib/gnw/dxinput.cc:166`.
- Gesture queue implementation is LIFO (`std::stack`) at `src/plib/gnw/touch.cc:50`; retrieval uses `top()/pop()` at `src/plib/gnw/touch.cc:407`.
- Dist config drift:
  - Unused keys in `dist/macos/f1_res.ini` and `dist/ios/f1_res.ini`: `VSYNC`, `FPS_LIMIT`, `IFACE_BAR_*` (no runtime consumers found).
  - Unused `[PENCIL]` section keys in `dist/ios/f1_res.ini` (`ENABLE_PENCIL`, `CLICK_RADIUS`, `LONG_PRESS_ACTION`, `DOUBLE_TAP_ACTION`, `SQUEEZE_ACTION`, `LONG_PRESS_DURATION`) have no matching runtime reads.

## 2) Exact Configuration-to-Code Mapping

### `f1_res.ini` keys that are actually consumed

| File/key | Read in code | Runtime effect |
|---|---|---|
| `[MAIN] SCR_WIDTH` | `src/game/game.cc:214` | Sets requested output width (min 640), then contributes to logical surface sizing. |
| `[MAIN] SCR_HEIGHT` | `src/game/game.cc:219` | Sets requested output height (min 480), then contributes to logical surface sizing. |
| `[MAIN] WINDOWED` | `src/game/game.cc:224` | Inverts to `video_options.fullscreen`. |
| `[MAIN] EXCLUSIVE` | `src/game/game.cc:229` | Sets `video_options.exclusive` flag. |
| `[MAIN] SCALE_2X` | `src/game/game.cc:234` | Clamped to 0/1 then converted to scale factor 1/2. |
| `[INPUT] CLICK_OFFSET_X` | `src/plib/gnw/mouse.cc:159` | Touch click calibration offset. |
| `[INPUT] CLICK_OFFSET_Y` | `src/plib/gnw/mouse.cc:162` | Touch click calibration offset. |
| `[INPUT] CLICK_OFFSET_MOUSE_X` | `src/plib/gnw/mouse.cc:167` | Mouse/trackpad click calibration offset. |
| `[INPUT] CLICK_OFFSET_MOUSE_Y` | `src/plib/gnw/mouse.cc:170` | Mouse/trackpad click calibration offset. |

### `fallout.cfg` keys relevant to current input/display issues

| File/key | Read in code | Runtime effect |
|---|---|---|
| `[input] pencil_right_click` | `src/plib/gnw/input.cc:1245`, `src/plib/gnw/mouse.cc:540` | Controls whether Pencil body gestures become right-click and whether Pencil runs precise left-only mode. |
| `[input] map_scroll_delay` | `src/game/map.cc:1075` | Throttles map edge scroll cadence in ms. |
| `[preferences] mouse_sensitivity` | `src/game/options.cc:1764`, applied at `src/game/options.cc:1936` | Multiplies pointer delta in `mouse_info` (`src/plib/gnw/mouse.cc:729`). |
| `[system] master_dat` | `src/game/game.cc:1346` | Data archive file name for master DB open. |
| `[system] master_patches` | `src/game/game.cc:1351` | Patch directory path for master resources. |
| `[system] critter_dat` | `src/game/game.cc:1362` | Data archive file name for critter DB open. |
| `[system] critter_patches` | `src/game/game.cc:1367` | Patch directory path for critter resources. |

### Config load location and precedence
- `fallout.cfg` defaults are initialized in `src/game/gconfig.cc:61` onward, then file values override defaults via `config_load` at `src/game/gconfig.cc:142`.
- `f1_res.ini` is loaded in `src/game/game.cc:190`, with fallback probing for bundle-local paths at `src/game/game.cc:203` and `src/game/game.cc:206`.
- Working directory selection on macOS (to make bundle Resources visible) is in `src/plib/gnw/winmain.cc:271` and `src/plib/gnw/winmain.cc:331`.
- On iOS startup, cwd is switched to app Documents in `src/plib/gnw/winmain.cc:89` through `src/plib/gnw/winmain.cc:92`.

## 3) SDL3 Input System Deep Dive (Current Implementation)

### Event intake and filtering
- Main pump: `GNW95_process_message` in `src/plib/gnw/input.cc:1098`.
- Mouse events are accepted for physical mice/trackpads, but synthetic mouse events from touch/pen are filtered on iOS via `which == SDL_TOUCH_MOUSEID || SDL_PEN_MOUSEID` in `src/plib/gnw/input.cc:1110`, `src/plib/gnw/input.cc:1121`, `src/plib/gnw/input.cc:1132`, `src/plib/gnw/input.cc:1143`.
- Finger events are always routed to gesture layer:
  - start: `src/plib/gnw/input.cc:1156`
  - move: `src/plib/gnw/input.cc:1163`
  - end: `src/plib/gnw/input.cc:1169`

### Gesture recognizer path
- Touch normalization + window/logical conversion starts in `convert_touch_to_logical` (`src/plib/gnw/touch.cc:103`).
- iOS conversion uses `iOS_windowToGameCoords` in `src/plib/gnw/touch.cc:128`.
- Gesture sequence building is in `src/plib/gnw/touch.cc:253`.
- Output container is currently `std::stack<Gesture>` (`src/plib/gnw/touch.cc:50`) and consumption is LIFO (`src/plib/gnw/touch.cc:407`).

### Mouse synthesis path
- `mouse_info` in `src/plib/gnw/mouse.cc:472` is the bridge that converts gesture intents into mouse operations (`mouse_simulate_input`).
- Tap and drag behaviors are emitted through explicit button down/up synthesis:
  - tap press: `src/plib/gnw/mouse.cc:571`
  - deferred tap release: `src/plib/gnw/mouse.cc:482` and `src/plib/gnw/mouse.cc:486`
  - drag down/move/up across pan/long-press branches (e.g. `src/plib/gnw/mouse.cc:620`, `src/plib/gnw/mouse.cc:678`, `src/plib/gnw/mouse.cc:665`).

### Physical mouse/trackpad path
- iOS absolute pointer state comes from `SDL_GetMouseState` in `src/plib/gnw/dxinput.cc:87`.
- Coordinates convert window->pixel and then pixel->game via `iOS_screenToGameCoords` (`src/plib/gnw/dxinput.cc:144`).
- When outside active content rect, motion is suppressed (zero delta) at `src/plib/gnw/dxinput.cc:170`.

### Coordinate system and windowing
- iOS destination rect (pillarbox/letterbox) is computed in `src/plib/gnw/svga.cc:80`.
- Conversion from screen pixels to logical game coords is implemented in `src/plib/gnw/svga.cc:947`.
- Window resize/pixel-size updates refresh rect via `handleWindowSizeChanged` in `src/plib/gnw/svga.cc:793` through `src/plib/gnw/svga.cc:814`.

### Native Pencil side-channel
- Pencil/finger discrimination comes from UIKit `UITouch.type` in `src/platform/ios/pencil.mm:57`.
- Pencil body gestures (double tap/squeeze) are exposed via `UIPencilInteraction` in `src/platform/ios/pencil.mm:128` and `src/platform/ios/pencil.mm:136`.
- Runtime polls body gestures in `src/plib/gnw/input.cc:1247`.

## 4) External Research (SDL3 + iPadOS + Multi-touch Patterns)

### SDL3 primary guidance
- `SDL_HINT_TOUCH_MOUSE_EVENTS` (default `1`) and `SDL_HINT_MOUSE_TOUCH_EVENTS` (mobile default `1`) can generate synthetic cross-device events:
  - https://wiki.libsdl.org/SDL3/SDL_HINT_TOUCH_MOUSE_EVENTS
  - https://wiki.libsdl.org/SDL3/SDL_HINT_MOUSE_TOUCH_EVENTS
- Pen synthesis defaults are also enabled:
  - `SDL_HINT_PEN_MOUSE_EVENTS` default `1`
  - `SDL_HINT_PEN_TOUCH_EVENTS` default `1`
  - https://wiki.libsdl.org/SDL3/SDL_HINT_PEN_MOUSE_EVENTS
  - https://wiki.libsdl.org/SDL3/SDL_HINT_PEN_TOUCH_EVENTS
- SDL headers explicitly recommend filtering synthetic IDs if app handles touch/pen separately:
  - `build-ios/_deps/sdl3-src/include/SDL3/SDL_mouse.h:50` through `build-ios/_deps/sdl3-src/include/SDL3/SDL_mouse.h:54`
- SDL event timestamps are in nanoseconds from `SDL_GetTicksNS()`:
  - `build-ios/_deps/sdl3-src/include/SDL3/SDL_events.h:364`

### SDL on iOS specifics
- SDL iOS README documents iOS-specific app behavior and filesystem container expectations:
  - https://wiki.libsdl.org/SDL3/README-ios
- Orientation control is via `SDL_HINT_ORIENTATIONS`:
  - https://wiki.libsdl.org/SDL3/SDL_HINT_ORIENTATIONS

### iPadOS windowing references
- Apple docs indicate fullscreen requirement settings affect multitasking/windowing behavior (`UIRequiresFullScreen`) and have changed over time:
  - https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen?changes=latest_major
- Apple technical note index for iOS input/event handling:
  - https://developer.apple.com/documentation/technotes/tn3192-understanding-the-ui-application-scene-multitasking-architecture

### Comparable multi-touch systems
- ScummVM touch control docs show explicit mapping layers between gestures and legacy mouse-centric actions:
  - https://docs.scummvm.org/en/v2.9.0/other_platforms/android.html#touch-controls
- Unity Input System docs separate touch pointers from mouse/pen pointer behavior (single vs multi-pointer semantics):
  - https://docs.unity3d.com/Packages/com.unity.inputsystem%401.2/manual/Settings.html#pointer-behavior

## Findings and Working Hypotheses

### High-confidence findings
- The runtime currently mixes three input layers: SDL mouse, SDL touch gestures, and native Pencil state.
- Synthetic event generation is globally disabled for touch<->mouse, but pen synthesis hints are not explicitly forced off in app code.
- Gesture events are stored in a LIFO container, which is a poor fit for temporal input streams and can reorder bursts.
- Distributed config files expose keys that do not map to runtime code, creating false expectations during testing and tuning.

### Most likely contributors to current iPad failures
- Event-source inconsistency after recent iOS input refactors (`571d15d`) in `dxinput` and synthetic-event filters.
- Non-FIFO gesture dispatch under burst conditions (drag/tap overlap) leading to stale-position click artifacts.
- Coordinate clamping/out-of-bounds suppression interacting with pen/touch transitions (especially when entering/leaving content bars).

## Proposed Plan (No Further Risky Input Changes Until This Sequence)

### Phase 0 - Freeze and baseline
- Tag current failing state and preserve reproducible binary/log bundle.
- Add a deterministic input trace mode (single log line per frame with source, mapped coordinates, button state, gesture state, and pen state).
- Acceptance: same repro run produces stable, parseable traces.

### Phase 1 - Normalize event ownership
- Adopt strict ownership model:
  - mouse/trackpad path: SDL mouse events + `dxinput` only.
  - finger path: SDL finger events -> gesture translator only.
  - pencil path: either (A) pure SDL pen/touch pipeline or (B) native UIKit path, but not mixed implicit synthesis.
- Explicitly set pen synthesis hints (`SDL_HINT_PEN_MOUSE_EVENTS`, `SDL_HINT_PEN_TOUCH_EVENTS`) to match chosen model.
- Acceptance: no duplicate down/up sequences and no source switching within same pointer stream.

### Phase 2 - Fix gesture ordering and temporal semantics
- Replace `std::stack<Gesture>` with FIFO queue semantics.
- Keep a monotonic, single time base across gesture recognition and long-press checks.
- Acceptance: down/move/up ordering remains correct under rapid input bursts.

### Phase 3 - Coordinate contract hardening
- Define one canonical conversion function for all iOS pointer types.
- Instrument and assert bounds transitions (inside content, on bars, out-of-content) to prevent snap-to-corner artifacts.
- Acceptance: no spontaneous jumps when crossing bars or resizing scenes.

### Phase 4 - Configuration and docs cleanup
- Make distributed config templates match actual consumed keys only.
- Move non-runtime/tuning notes to docs, not active templates.
- Acceptance: every key in shipped `f1_res.ini`/`fallout.cfg` has at least one runtime consumer.

### Phase 5 - Verification matrix
- Run scripted and manual checks for:
  - finger tap, long-press drag, two-finger scroll
  - trackpad pointer + click/drag
  - Pencil tap/drag + body gestures
  - orientation changes and window resizing (fullscreen and Stage Manager/windowed)
- Acceptance: no cursor jumping, no stale-position clicks, no dead-input states, and consistent mapping in all modes.

## Immediate Recommendation
- Do not add more heuristic/hint toggles first.
- Implement Phase 0 and Phase 1 instrumentation/ownership cleanup first, then retest on simulator and physical iPad before any behavioral tuning.

## Requirement Update (2026-02-15)
The initial recommendation in this document to keep templates to "runtime-consumed keys only" is superseded by current product requirement:
- baseline unpatched config keys must be functional, not merely present.
- follow-up execution is tracked in `docs/audit/config-compat-project-plan-2026-02-15.md`.
