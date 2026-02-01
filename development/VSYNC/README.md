# VSync & Display Refresh

## Overview

This folder contains the plan for implementing proper VSync and display refresh rate handling.

## Documentation

| File | Purpose |
|------|---------|
| [plan/MASTER_PLAN.md](plan/MASTER_PLAN.md) | Complete implementation plan |
| [tasks/TASK_01_ENABLE_VSYNC.md](tasks/TASK_01_ENABLE_VSYNC.md) | Enable VSync flag |
| [tasks/TASK_02_QUERY_REFRESH_RATE.md](tasks/TASK_02_QUERY_REFRESH_RATE.md) | Query display info |
| [tasks/TASK_03_DYNAMIC_FPS.md](tasks/TASK_03_DYNAMIC_FPS.md) | Configurable FPS limiter |
| [tasks/TASK_04_CONFIGURATION.md](tasks/TASK_04_CONFIGURATION.md) | User settings |

## Current State

- **VSync**: OFF (no flag in `SDL_CreateRenderer`)
- **FPS Limit**: 60fps hardcoded via `SDL_Delay()`

## Quick Summary

| Task | Effort | Priority |
|------|--------|----------|
| Enable VSync | 1 hour | HIGH |
| Query refresh rate | 1 hour | MEDIUM |
| Dynamic FPS limiter | 2-3 hours | MEDIUM |
| Configuration | 2 hours | LOW |

**Total**: ~8 hours

## Key Files

- `src/plib/gnw/svga.cc` — Renderer creation
- `src/fps_limiter.cc` — Software FPS limiting
