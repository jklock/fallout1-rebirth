# Bugfixes Workspace

Last updated: 2026-02-07

This folder contains plans, research, and working notes for completed bugfixes.
All bugs identified in Phase 6 (Engine Fixes) have been resolved.

## Completed Bugfixes

| # | Issue | Status | Details |
|---|-------|--------|---------|
| 1 | Cursor-at-top stutter and audio glitches | ✅ FIXED | [bug-1-stutter-top-edge.md](bug-1-stutter-top-edge.md) |
| 2 | Screen tearing when moving cursor via arrow keys | ✅ FIXED | [bug-2-tearing-arrow-keys.md](bug-2-tearing-arrow-keys.md) (VSync enabled) |
| 3 | Sporadic touch/Pencil click location errors | ✅ FIXED | [bug-3-sporadic-click-offset.md](bug-3-sporadic-click-offset.md) |
| 4 | Vault 15 (and other ladder transitions) self-attack combat bug | ✅ FIXED | [bug-4-vault15-self-attack.md](bug-4-vault15-self-attack.md) |
| 5 | iPad dock reveal stutter (bottom edge) in fullscreen | ✅ FIXED | [bug-5-ios-dock-bottom-edge.md](bug-5-ios-dock-bottom-edge.md) |
| 6 | iOS on-screen keyboard stutter (text input) | ✅ FIXED | [bug-6-ios-keyboard-stutter.md](bug-6-ios-keyboard-stutter.md) |

## Key Fixes Summary

- **VSync**: Enabled by default to eliminate tearing (bug 2)
- **Touch coordinates**: Calibration fixes for accurate input (bug 3)
- **Survivalist perk**: Combat targeting bug resolved (bug 4)

## Research and Cross-Refs

- Upstream issue scan: [upstream-issues.md](upstream-issues.md)
- Work plan: [PLAN.md](PLAN.md)
- Full audit: [RESEARCH.md](RESEARCH.md)

## Docs reviewed for input context

- [docs/touch.md](../../docs/touch.md)
- [docs/pencil.md](../../docs/pencil.md)
- [docs/mouse.md](../../docs/mouse.md)
- [docs/input.md](../../docs/input.md)
