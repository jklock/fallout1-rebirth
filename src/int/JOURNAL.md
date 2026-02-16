# JOURNAL: src/int/

Last Updated: 2026-02-14

## Purpose

Script interpreter for Fallout's compiled script format. Handles executing `.int` script files that control game events, dialogue, and world interactions.

## Recent Activity

### 2026-02-07
- Stable - no recent changes
- Opcode registrations unchanged

### Previous
- All opcodes verified compatible with RME scripts

## Key Files

| File | Purpose |
|------|---------|
| `intrpret.cc` | Core interpreter loop, bytecode execution |
| `intrpret.h` | Opcode definitions, interpreter state |
| `support/intextra.cc` | **Fallout-specific opcode handlers** |
| `support/intextra.h` | Opcode registration declarations |
| `dialog.cc` | Script-driven dialogue handling |
| `sound.cc` | Script-triggered sound effects |
| `movie.cc` | Script-triggered movie playback |
| `window.cc` | Script UI window management |
| `export.cc` | Script variable export/import |

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `support/` | Fallout-specific extensions to base interpreter |

## Development Notes

### For AI Agents

1. **Adding Opcodes**: Register in `support/intextra.cc` using `interpretAddFunc(OPCODE, handler)`
2. **Opcode Format**: Functions take `Program*` parameter, use stack for args/returns
3. **Stability**: This code is mature and rarely needs changes
4. **Script Debugging**: Use `debug_printf()` to trace script execution

### Opcode Registration Pattern

```cpp
// In intextra.cc
static void opMyNewFunction(Program* program) {
    // Pop arguments from stack (reverse order)
    int arg1 = programStackPopInteger(program);
    
    // Do work...
    
    // Push return value if needed
    programStackPushInteger(program, result);
}

// Register during initialization
interpretAddFunc(0x80XX, opMyNewFunction);
```

### Script Interpreter Flow

1. Script loaded from `.int` file
2. `intrpret.cc` executes bytecode
3. Opcodes dispatch to handlers in `intextra.cc`
4. Handlers interact with game systems in `src/game/`

### Debugging Scripts

Scripts are compiled - no source available. To debug:
- Add logging in opcode handlers
- Check `scripts.lst` for script mappings
- Use script decompiler tools externally
