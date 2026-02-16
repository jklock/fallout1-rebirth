# JOURNAL: src/int/

Last Updated: 2026-02-15

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

## 2026-02-15 Repository Sync
- Synced this journal to current repository state after deterministic SDL3 input hardening.
- Core input implementation commit: `c1accdf27927603e1d6b4c115dded9bac08c0a72`.
- LLM handoff summary commit: `fdc0f05f559c1d2f79706d395b6eae4b9ae4d48d`.
- Automated input evidence is recorded in `dev/state/latest-summary.tsv` and `dev/state/history.tsv` (latest PASS row: `2026-02-15T20:48:57Z`).
- iOS scripted touch evidence: `dev/state/logs/round-2-input-ios_headless-rerun.log`, `dev/state/logs/ios-touch-autotest-20260215T204516Z.patchlog.txt`, and screenshot `dev/state/logs/screens/ios-headless-com-fallout1rebirth-game-20260215T204510Z.png`.
