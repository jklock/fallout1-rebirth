# src/int/

Script interpreter for Fallout's SSL scripting language.

Last updated: 2026-02-07

## Core Components

| File | Description |
|------|-------------|
| `intrpret.cc/h` | Main interpreter, opcode definitions, program execution |
| `intlib.cc/h` | Standard library functions for scripts |
| `export.cc/h` | Script export/import mechanism |
| `dialog.cc/h` | Dialog scripting support |
| `nevs.cc/h` | Named events system |

## Support Subsystem

The `support/` subdirectory contains Fallout-specific script extensions:

| File | Description |
|------|-------------|
| `intextra.cc/h` | Fallout-specific opcode handlers |

### Registering Opcodes

New script opcodes are registered in `intextra.cc` using:

```cpp
interpretAddFunc(OPCODE_VALUE, handlerFunction);
```

## Media and UI

| File | Description |
|------|-------------|
| `audio.cc/h` | Script audio playback |
| `audiof.cc/h` | Audio file handling |
| `sound.cc/h` | Sound effect support |
| `movie.cc/h` | Movie playback from scripts |
| `pcx.cc/h` | PCX image loading |
| `widget.cc/h` | UI widget system |
| `window.cc/h` | Window management |
| `region.cc/h` | Clickable regions |
| `mousemgr.cc/h` | Mouse cursor management |

## Data Handling

| File | Description |
|------|-------------|
| `datafile.cc/h` | Data file access |
| `share1.cc/h` | Shared data structures |
| `memdbg.cc/h` | Memory debugging utilities |

## Opcode Structure

Opcodes are 16-bit values starting at `0x8000`. The interpreter uses a stack-based VM with separate data and return stacks.
