# Subagent Prompt #2: RME Patch Content Analysis

## Mission

You are an analysis agent. Your task is to determine **exactly what the RME 1.1e patches change** in Fallout 1 game data. The repository is at `/Volumes/Storage/GitHub/fallout1-rebirth`.

RME (Restoration Mod Extended) 1.1e bundles 22 community mods that modify Fallout 1's game data files.

## What to Do

### Step 1: Read the RME Documentation

Read these files to understand what RME claims to include:

```
third_party/rme/README.md
third_party/rme/rme_readme.txt    (if exists)
```

Search for the mod list — there should be 22 mods listed. Record every mod name.

### Step 2: Read the Cross-Reference Data

These CSVs compare patched vs unpatched game data:

```
# Patched file analysis
GOG/rme_xref_patched/          — all CSV files here
GOG/rme_xref_unpatched/        — all CSV files here

# Look for summary files
find GOG/ -name "*.csv" -o -name "*summary*" -o -name "*xref*" | sort
find development/RME/ -name "*.csv" -o -name "*crossref*" -o -name "*xref*" | sort
```

Read each CSV. Key files to look for:
- `added_files.csv` — files added by RME that don't exist in vanilla
- `modified_files.csv` — files changed by RME vs vanilla
- `removed_files.csv` — files removed (if any)
- Any crossref summary documents in `development/RME/`

### Step 3: Analyze the Diff Between Patched and Unpatched

```
# Compare directory structures
diff <(cd GOG/unpatchedfiles && find . -type f | sort) \
     <(cd GOG/patchedfiles && find . -type f | sort)

# Count files
find GOG/unpatchedfiles/ -type f | wc -l
find GOG/patchedfiles/ -type f | wc -l
```

Check for these file types and what changed:
- `.pro` files (prototype definitions — items, critters, scenery)
- `.map` files (game maps)
- `.msg` files (dialog/text strings)
- `.ssl` / `.int` files (scripts — compiled and source)
- `.frm` / `.fr0`-`.fr5` files (frame animations/sprites)
- `.pal` files (color palettes)
- `.lst` files (list manifests)
- `.gam` files (game config)
- `.sve` files (save data)
- `.fon` files (fonts)
- `.acm` / `.wav` files (audio)

### Step 4: Categorize All 1,126 Files

For each changed/added file, categorize by:

| Category | Description | Examples |
|----------|------------|---------|
| **MAP** | Map/level data | `.map` files |
| **PROTO** | Prototype definitions (items, critters, tiles, scenery, walls) | `.pro` files in `proto/` |
| **SCRIPT** | Game scripts | `.int` files in `scripts/` |
| **DIALOG** | Dialog and message text | `.msg` files |
| **ART** | Graphics/sprites | `.frm`, `.fr0`-`.fr5` files |
| **FONT** | Font replacements | `.fon` files, `font*.aaf` |
| **CONFIG** | Game configuration | `.cfg`, `.ini`, `.lst` files |
| **AUDIO** | Sound/music | `.acm`, `.wav` files |
| **DATA** | Misc data | `.gam`, `.sve`, `.pal` files |

### Step 5: Map Changes to Mods

For each of the 22 mods in RME, try to identify which files it changes. Cross-reference:
- The RME readme's mod descriptions
- The file categories above
- Any notes in `development/RME/` about specific mods

### Step 6: Return Analysis

Return your results in this format:

```
## RME 1.1e Mod List (22 mods)
1. [Mod Name] — one-line description
...

## File Change Summary
| Category | Added | Modified | Total |
|----------|-------|----------|-------|
| MAP | X | Y | Z |
| PROTO | X | Y | Z |
...
| TOTAL | X | Y | Z |

## Detailed File List by Category

### MAP files
| File | Status (added/modified) | Likely Mod Source |
|------|------------------------|-------------------|
...

### PROTO files
...

## Mod-to-File Mapping
| Mod | Files Changed | Categories |
|-----|--------------|------------|
...

## Key Observations
- ...
```

## Constraints

- Do NOT modify any files. This is read-only research.
- If you can't read binary files (`.pro`, `.map`, `.frm`), note their existence and size but don't try to parse them.
- Focus on file counts, categories, and structure — not on interpreting binary content.
- If the total doesn't add up to 1,126, note the discrepancy and explain what you actually found.
- Read any existing analysis documents in `development/RME/` first to avoid duplicating work.
