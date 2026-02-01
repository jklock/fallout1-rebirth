# Development Documentation

This folder contains technical documentation for ongoing and planned development work on Fallout 1 Rebirth.

## Project Folders

| Folder | Purpose | Status |
|--------|---------|--------|
| [applepencil/](applepencil/) | Apple Pencil support implementation | Active |
| [SDL3/](SDL3/) | SDL3 migration assessment | Deferred |
| [VSYNC/](VSYNC/) | VSync and display refresh handling | Planned |

## Reference Documents

| Document | Description |
|----------|-------------|
| [SCREEN_DIMENSIONS.md](SCREEN_DIMENSIONS.md) | Apple Silicon device screen dimensions |
| [HIGH_RESOLUTION.md](HIGH_RESOLUTION.md) | High-res patch analysis and improvement opportunities |

## Current Development Priorities

### 1. Apple Pencil Support (Active)
Enable playing the game entirely with Apple Pencil:
- **Phase 1**: Absolute positioning + long-press right-click (no native code)
- **Phase 2**: Native UIKit bridge for pencil detection, double-tap, squeeze

See [applepencil/plan/MASTER_PLAN.md](applepencil/plan/MASTER_PLAN.md)

### 2. VSync & Display (Planned)
- Enable hardware VSync (currently off)
- ProMotion 120Hz support
- Configurable FPS limiting

See [VSYNC/plan/MASTER_PLAN.md](VSYNC/plan/MASTER_PLAN.md)

### 3. SDL3 Migration (Deferred)
Not recommended currently. Complete audio rewrite required.

See [SDL3/plan/MASTER_PLAN.md](SDL3/plan/MASTER_PLAN.md)

## Getting Started

See the main [README.md](../README.md) for build instructions.

For contribution guidelines, see [docs/contributing.md](../docs/contributing.md).
