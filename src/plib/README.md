# src/plib/

Platform abstraction library providing low-level services.

Originally from Interplay's internal library, now implemented using SDL3.

Last updated: 2026-02-14

## Subdirectories

| Directory | Description |
|-----------|-------------|
| [gnw/](gnw/) | Graphics, input, windowing (Game aNd Window) |
| [db/](db/) | Database/file system abstraction |
| [color/](color/) | Color palette management |
| [assoc/](assoc/) | Associative array data structure |

## gnw/ - Graphics and Input

Core windowing and input system:

| File | Description |
|------|-------------|
| `gnw.cc/h` | Window manager, main initialization |
| `svga.cc/h` | Graphics/video mode handling |
| `grbuf.cc/h` | Graphics buffer operations |
| `input.cc/h` | Input event queue |
| `kb.cc/h` | Keyboard handling |
| `mouse.cc/h` | Mouse handling |
| `touch.cc/h` | Touch input with tap/pan gestures, long-press drag, mouse fallback (iOS/iPadOS) |
| `button.cc/h` | UI button system |
| `text.cc/h` | Text rendering |
| `rect.cc/h` | Rectangle operations |
| `dxinput.cc/h` | DirectInput compatibility layer |
| `winmain.cc/h` | Application entry point |
| `debug.cc/h` | Debug output |
| `memory.cc/h` | Memory allocation |
| `vcr.cc/h` | Input recording/playback |
| `intrface.cc/h` | Interface utilities |

## db/ - File System

| File | Description |
|------|-------------|
| `db.cc/h` | DAT archive and file access |
| `lzss.cc/h` | LZSS decompression |

## color/

| File | Description |
|------|-------------|
| `color.cc/h` | 8-bit palette and color operations |

## assoc/

| File | Description |
|------|-------------|
| `assoc.cc/h` | Key-value associative array |
