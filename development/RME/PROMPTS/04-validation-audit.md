# Subagent Prompt #4: Validation Status Audit

## Mission

You are an audit agent. Your task is to **brutally honestly assess** what has and has not been validated in the RME integration for Fallout 1 Rebirth. The repository is at `/Volumes/Storage/GitHub/fallout1-rebirth`.

Do NOT accept claims at face value. Cross-check everything against actual evidence.

## What to Do

### Step 1: Read All Planning and Status Documents

Read every document in these locations:

```
# Primary RME docs
find development/RME/ -name "*.md" -type f | sort

# Archived docs (may contain old/moved plans)
find development/archive/ -name "*.md" -type f | sort

# Project-level docs
docs/
ISSUES.md
JOURNAL.md
README.md
```

For each document, note:
- What it CLAIMS was done
- What EVIDENCE it provides (file paths, command output, checksums)
- What it PROMISES will be done

### Step 2: Read All Evidence/Artifact Files

```
# Look for validation artifacts
find development/RME/ -name "*.log" -o -name "*.txt" -o -name "*.csv" | sort
find development/RME/ARTIFACTS/ -type f | sort   # if exists

# Look for test outputs
find development/RME/ -path "*/evidence/*" -o -path "*/results/*" | sort
```

### Step 3: Cross-Check Specific Claims

For each claim you find in the documents, verify it:

#### Claim: "72 maps validated"
- How many `.map` files actually exist in `GOG/patchedfiles/data/maps/`?
  ```
  find GOG/patchedfiles/data/maps/ -name "*.map" | wc -l
  ```
- Is there a CSV or log listing the specific maps checked?
- What does "validated" mean — just that they exist, or that they load in-game?

#### Claim: "1,126 files in RME patch"
- How many files actually differ?
  ```
  diff <(cd GOG/unpatchedfiles && find . -type f | sort) \
       <(cd GOG/patchedfiles && find . -type f | sort) | wc -l
  ```
- Does this count include added AND modified, or just added?

#### Claim: "All prototypes load"
- What evidence exists? A log file? A script that tested this?
- Was this tested on macOS, iOS, or both?

#### Claim: "Case-insensitive lookups work"
- What evidence? Did someone actually test with mixed-case filenames?
- Was this tested on case-sensitive APFS (iOS default)?

#### Claim: "22 mods integrated"
- Are all 22 mods listed somewhere? Which ones?
- Is there per-mod validation, or just "the whole patch applied"?

### Step 4: Check for Gaps

Identify what has NOT been validated:

- [ ] Has the game been played start-to-finish with RME data?
- [ ] Has every map been visited?
- [ ] Have all 22 mods been individually verified?
- [ ] Has iOS been tested at all?
- [ ] Has audio been tested?
- [ ] Have save/load been tested with RME data?
- [ ] Has combat been tested?
- [ ] Have all dialog trees been tested?
- [ ] Has the worldmap been fully tested?

### Step 5: Identify Contradictions

Look for any documents that contradict each other:
- Different file counts
- Different mod lists
- Claims of completion in one doc, TODO items in another
- Dates that don't make sense (claiming completion before work started)
- Plans that were written but never executed

### Step 6: Return Audit Report

Return your results in this format:

```
## Validation Status Summary

| Area | Claimed Status | Actual Status | Evidence |
|------|---------------|---------------|----------|
| Data patching | "Complete" | VERIFIED/UNVERIFIED | [evidence or lack thereof] |
| Map loading | "72 maps pass" | VERIFIED/UNVERIFIED | ... |
| iOS testing | ... | ... | ... |
...

## Claims vs Reality

### VERIFIED Claims (evidence exists)
1. [Claim] — [Evidence location and what it proves]
...

### UNVERIFIED Claims (no evidence found)
1. [Claim from document X] — [What's missing]
...

### FALSE Claims (evidence contradicts)
1. [Claim] — [What the evidence actually shows]
...

## Contradictions Found
1. [Doc A says X] vs [Doc B says Y]
...

## Missing Validation (Never Attempted)
1. ...

## Recommendations
1. ...
```

## Constraints

- Do NOT modify any files. This is read-only audit.
- Be brutally honest. If something hasn't been validated, say so plainly.
- "The script exists" is NOT evidence that it was run.
- "The plan says to do X" is NOT evidence that X was done.
- A TODO checkbox being checked in a markdown file is NOT evidence unless there's corresponding output/logs.
- The absence of evidence is itself evidence — note everything that SHOULD exist but doesn't.
- Do not assume competence — check everything, even obvious things.
