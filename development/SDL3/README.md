# SDL3 Migration

> **Status**: DEFERRED — Not recommended at this time

## Overview

This folder contains the migration plan from SDL2 to SDL3.

**SDL3 is NOT currently recommended** because:
1. SDL2 works well and is stable
2. SDL3 migration requires a complete audio engine rewrite
3. SDL3's pen API still doesn't provide double-tap/squeeze gestures (needs native UIKit anyway)
4. Significant engineering effort (~24-48 hours) for limited benefit

## When to Consider SDL3

- SDL2 becomes deprecated
- SDL3 pen API becomes essential
- ProMotion 120Hz requires SDL3 support

## Documentation

| File | Purpose |
|------|---------|
| [plan/MASTER_PLAN.md](plan/MASTER_PLAN.md) | Complete migration assessment |
| [tasks/TASK_01_BRANCH_SETUP.md](tasks/TASK_01_BRANCH_SETUP.md) | Initial branch and build setup |
| [tasks/TASK_02_AUDIO_REWRITE.md](tasks/TASK_02_AUDIO_REWRITE.md) | Complete audio engine rewrite |
| [tasks/TASK_03_INPUT_EVENTS.md](tasks/TASK_03_INPUT_EVENTS.md) | Event type updates |
| [tasks/TASK_04_RENDERER.md](tasks/TASK_04_RENDERER.md) | Renderer changes |

## Quick Summary

| Aspect | Effort |
|--------|--------|
| Symbol renames | Low (scripts available) |
| Audio rewrite | HIGH (complete redesign) |
| Input events | Medium (many files) |
| Renderer | Low |
| Total | 24-48 hours |
