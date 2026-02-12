# Subagent Prompt #3: Engine Source Code Review

## Mission

You are a code review agent. Your task is to review **every engine source code change** related to RME integration in the Fallout 1 Rebirth project. The repository is at `/Volumes/Storage/GitHub/fallout1-rebirth`.

This is a C++ game engine (originally C-style) that uses SDL for platform abstraction. The project is Apple-only (macOS + iOS/iPadOS).

## What to Do

### Step 1: Identify All Modified Source Files

Read these files that are known to have RME-related changes:

**Core game engine:**
```
src/game/proto.cc          — Prototype loading (items, critters, scenery)
src/game/proto.h
src/game/map.cc            — Map loading and rendering
src/game/map.h
src/game/tile.cc           — Tile engine
src/game/tile.h
src/game/object.cc         — Game object handling
src/game/object.h
src/game/main.cc           — Game initialization and main loop
```

**Platform/graphics layer:**
```
src/plib/gnw/svga.cc       — Graphics/display (VSync, resolution)
src/plib/gnw/svga.h
src/plib/gnw/gnw.cc        — GNU Windowing system
src/plib/gnw/winmain.cc    — Window/app entry point
```

**Database/file access:**
```
src/game/db.cc             — File database (DAT file access, case-insensitive lookups)
src/game/db.h
```

**RME-specific additions:**
```
src/game/patchlog.cc       — Patch logging (if exists)
src/game/patchlog.h        — Patch logging header (if exists)
```

**Also search for any other modified files:**
```
grep -rl "rme\|RME\|patchlog\|case.insensitive\|case_insensitive\|tolower\|CASE" src/ --include="*.cc" --include="*.h" | sort
```

### Step 2: Read Each File Completely

For each file identified above, read the **entire file**. Do not skim. You need to understand:
- What was changed and why
- Whether the change is correct
- Whether it could cause issues

### Step 3: Categorize Each Change

For every change or addition, classify it:

| Category | Meaning | Action |
|----------|---------|--------|
| **REQUIRED** | Necessary for RME data to load correctly | Keep, verify correct |
| **FIX** | Bug fix (Survivalist perk, VSync, etc.) | Keep, verify correct |
| **DEBUG** | Debug/logging code | Verify not noisy, consider guarding with `#ifdef DEBUG` |
| **PLATFORM** | Apple-specific adaptation | Keep, verify correct for both macOS and iOS |
| **CLEANUP** | Code style / dead code removal | Keep if clean, flag if risky |

### Step 4: Check for Issues

For each file, answer:

1. **Correctness**: Does the code do what it claims? Any off-by-one errors, null pointer risks, buffer overflows?
2. **Compatibility**: Will this work on both macOS and iOS/iPadOS? Any platform assumptions?
3. **Performance**: Any changes that could cause performance issues (especially on iPad)?
4. **Case sensitivity**: iOS uses case-sensitive APFS. Are all file lookups properly case-insensitive?
5. **Memory**: Any memory leaks introduced? (C-style malloc/free patterns)
6. **Thread safety**: Any shared state accessed without synchronization?

### Step 5: Review `db.cc` Case-Insensitive Lookups Specifically

This is the most critical RME change. The original game assumed Windows (case-insensitive FS). RME data may have mixed case. Read `db.cc` carefully and verify:
- All file open/lookup paths go through case-insensitive resolution
- The implementation handles nested directories
- Performance is acceptable (not doing a full directory scan on every file open)
- Edge cases: empty paths, paths with trailing slashes, paths with `..`

### Step 6: Return Review

Return your results in this format:

```
## Files Reviewed
| File | Lines | Changes Found | Categories |
|------|-------|--------------|------------|
| src/game/proto.cc | XXXX | N | REQUIRED, FIX |
...

## Change Detail

### src/game/proto.cc
**What changed:** ...
**Category:** REQUIRED
**Correctness:** OK / ISSUE: ...
**Platform:** OK / ISSUE: ...
**Notes:** ...

### src/game/map.cc
...

## Critical Issues (Must Fix)
1. ...

## Warnings (Should Fix)
1. ...

## Observations (Note for Future)
1. ...

## Case-Insensitive File Lookup Review
- Implementation location: ...
- Approach: ...
- Correctness: ...
- Performance: ...
- Edge cases: ...
```

## Constraints

- Do NOT modify any files. This is read-only review.
- Read files COMPLETELY — do not skim or summarize without reading.
- Be specific about line numbers when reporting issues.
- If a file doesn't exist (e.g., `patchlog.cc` was removed), note that.
- Compare against git history if available: `git log --oneline -20 -- src/game/proto.cc`
- Focus on correctness over style — this is a C-style codebase, don't flag every `malloc` as a problem.
