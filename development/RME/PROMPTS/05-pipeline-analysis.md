# Subagent Prompt #5: Patching & Validation Pipeline Analysis

## Mission

You are a DevOps analysis agent. Your task is to **document every script and pipeline** related to RME patching and validation in the Fallout 1 Rebirth project. The repository is at `/Volumes/Storage/GitHub/fallout1-rebirth`.

## What to Do

### Step 1: Read Every Script

Read the **complete contents** of every script in these directories:

**Patch scripts:**
```
find scripts/patch/ -type f | sort
```
Read each one fully. These handle applying RME patches to vanilla game data.

**Dev/validation scripts:**
```
find scripts/dev/ -type f | sort
```
Read each one fully. These handle formatting, linting, building, and verification.

**Build scripts:**
```
find scripts/build/ -type f | sort
```
Read each one fully. These handle macOS and iOS builds.

**Test scripts:**
```
find scripts/test/ -type f | sort
```
Read each one fully. These handle simulator testing and verification.

**Root-level scripts:**
```
ls scripts/*.sh
```

### Step 2: Document Each Script

For every script, record:

| Field | Description |
|-------|------------|
| **Path** | Full path from repo root |
| **Purpose** | What it does in one sentence |
| **Inputs** | What arguments/env vars it takes |
| **Outputs** | What it produces (files, exit codes) |
| **Dependencies** | What tools/scripts it calls |
| **Side Effects** | What it modifies (filesystems, simulators, etc.) |

### Step 3: Map the Full Pipeline

Document the complete end-to-end flow for each workflow:

#### Workflow A: Patch Vanilla Data → Playable macOS Build
```
Step 1: [script] [args] — what it does
Step 2: [script] [args] — what it does
...
```

#### Workflow B: Patch Vanilla Data → Playable iOS Simulator Build
```
Step 1: ...
```

#### Workflow C: Validate Patched Data (Static)
```
Step 1: ...
```

#### Workflow D: Pre-Commit Checks
```
Step 1: ...
```

#### Workflow E: Full Release Build (macOS DMG + iOS IPA)
```
Step 1: ...
```

### Step 4: Provide Exact Command Sequences

For each workflow above, provide the **exact copy-pasteable commands** to run from the repo root:

```bash
cd /Volumes/Storage/GitHub/fallout1-rebirth

# Workflow A: Patch + macOS Build
[exact commands here]

# Workflow B: Patch + iOS Simulator
[exact commands here]

# etc.
```

Include any required environment variables, prerequisites, and expected output.

### Step 5: Identify Gaps

Report any of the following:

1. **Missing scripts** — workflows described in docs but no script exists
2. **Undocumented scripts** — scripts that exist but aren't referenced anywhere
3. **Broken dependencies** — scripts that call other scripts/tools that don't exist
4. **Missing error handling** — scripts that don't check for failures
5. **Hardcoded paths** — scripts with absolute paths that won't work on other machines
6. **Missing workflows** — obvious workflows that should exist but don't (e.g., "clean everything and rebuild")
7. **Ordering issues** — scripts that must run in a specific order but don't enforce it

### Step 6: Check Script Quality

For each script, briefly assess:
- Does it use `set -e` / `set -o pipefail`?
- Does it validate inputs?
- Does it clean up after itself?
- Does it handle interrupts (trap)?
- Are there race conditions (especially simulator scripts)?

### Step 7: Return Analysis

Return your results in this format:

```
## Script Inventory

### scripts/patch/
| Script | Purpose | Inputs | Outputs |
|--------|---------|--------|---------|
| rebirth-patch.sh | ... | ... | ... |
...

### scripts/build/
...

### scripts/test/
...

### scripts/dev/
...

## Pipeline Workflows

### Workflow A: Patch + macOS Build
```
[exact commands]
```
**Prerequisites:** ...
**Expected output:** ...
**Time estimate:** ...

### Workflow B: Patch + iOS Simulator
...

## Gaps and Issues

### Missing Scripts
1. ...

### Broken Dependencies
1. ...

### Quality Issues
1. ...

## Recommendations
1. ...
```

## Constraints

- Do NOT modify any files. This is read-only analysis.
- Read every script COMPLETELY — do not skim.
- Test no commands — just read and analyze.
- If a script references another script, verify that script exists.
- If a script references a tool (e.g., `clang-format`, `cmake`), note the dependency but don't check if it's installed.
- Pay special attention to the iOS simulator scripts — they manage hardware resources (booting/shutting down simulators) and errors here can leave the system in a bad state.
- Note any scripts that are macOS-only vs scripts that could theoretically work on other platforms (even though this is an Apple-only project).
