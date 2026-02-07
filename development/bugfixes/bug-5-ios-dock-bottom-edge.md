# Bug 5: iPad dock reveal stutter (bottom edge) in fullscreen

Last updated: 2026-02-07

## Report
On iPad in fullscreen, moving the cursor/finger/Pencil to the bottom edge
reveals the dock. This causes stutter/lag and makes downward scrolling
hard unless the pointer is moved away from the dock region. This does not
appear when iOS Game Mode is active.

## Suspected Triggers
- iPadOS system gestures at the bottom edge are not being deferred.
- SDL's UIKit view controller defers system gestures based on
  `SDL_HINT_IOS_HIDE_HOME_INDICATOR` and fullscreen/borderless flags, but
  we are not setting the hint or the view controller is not honoring it.
- The app might not be in true fullscreen (Stage Manager / multitasking),
  so dock gestures still take priority.

## Relevant Code / Config
- src/plib/gnw/svga.cc: sets iOS window flags (fullscreen + borderless).
- os/ios/Info.plist: iOS config (status bar hidden; no UIRequiresFullScreen).
- build-ios/_deps/sdl3-src/src/video/uikit/SDL_uikitviewcontroller.m:
  uses `preferredScreenEdgesDeferringSystemGestures` and
  `SDL_HINT_IOS_HIDE_HOME_INDICATOR` to control dock/home indicator behavior.
- build-ios/_deps/sdl3-src/include/SDL3/SDL_hints.h:
  `SDL_HINT_IOS_HIDE_HOME_INDICATOR` values ("2" defers system gestures).

## Repro Checklist
1) iPad in fullscreen build, trackpad/mouse or finger.
2) Move pointer to bottom edge while trying to scroll down.
3) Observe dock reveal and stutter.
4) Compare behavior when iOS Game Mode is active vs inactive.

## Investigation Tasks
- Confirm whether the app is in true fullscreen (no Stage Manager) and
  whether adding `UIRequiresFullScreen` changes dock behavior.
- Set `SDL_HINT_IOS_HIDE_HOME_INDICATOR` to "2" before SDL init on iOS and
  verify `preferredScreenEdgesDeferringSystemGestures` returns all edges.
- Verify whether trackpad/mouse pointer edges are treated differently than
  finger touches with respect to system gesture deferring.

## Candidate Fix Directions
1) Set `SDL_HINT_IOS_HIDE_HOME_INDICATOR` to "2" at startup on iOS.
2) Add `UIRequiresFullScreen` to `os/ios/Info.plist` if multitasking is
   allowing dock gestures to override fullscreen gameplay.
3) If SDL hint is insufficient, add an iOS shim to force
   `preferredScreenEdgesDeferringSystemGestures` to `.all`.
