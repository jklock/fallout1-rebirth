# Master Orchestration Prompt: RME Integration Validation

> **Usage:** Copy this entire prompt into a new chat session to orchestrate the full RME validation workflow.
> **Prerequisites:** The repo must be checked out at `/Volumes/Storage/GitHub/fallout1-rebirth` with the current branch.

---

## Prompt

You are working on the **Fallout 1 Rebirth** project — an Apple-only (macOS/iOS) fork of Fallout 1 Community Edition. The project integrates **RME (Restoration Mod Enhanced) 1.1e**, which bundles 22 community mods into 1,126 data overlay files.

**All planning documents already exist** in `development/RME/`. Your job is to **execute** the validation plan and produce provable evidence that every RME change works at runtime.

### Current Ground Truth

- **Data pipeline**: SOLID — patching, checksums, case normalization all work.
- **Runtime validation**: ~4% — only 3/72 maps ever tested; the rest is ZERO.
- **Goal**: All RME updates integrated, validated working, tested in a provable way. I should be able to generate a new `.app` / `.ipa`, load the patched data, and run without issues.

### Reference Documents

Read these files FIRST to understand the full scope — do NOT re-derive anything that is already documented:

| File | Purpose |
|------|---------|
| `development/RME/plan/PLAN.md` | Master plan — 22-mod inventory, 10 file categories, 5-phase validation, risk matrix |
| `development/RME/OUTCOME/OUTCOME.md` | 5 validation gates with 29 pass/fail criteria and evidence requirements |
| `development/RME/TASKS/TODO.infrastructure.md` | Tasks I-0 through I-5: build, patch, validate, install prerequisites |
| `development/RME/TASKS/TODO.maps.md` | Tasks M-1 through M-7: 72-map sweep, patchlog, flaky maps, big-endian |
| `development/RME/TASKS/TODO.art.md` | Tasks A-1 through A-10: 375+12 FRM files, LST integrity, visual tests |
| `development/RME/TASKS/TODO.prototypes.md` | Tasks P-1 through P-10: 95+4 PRO files, FID cross-ref, companion armor |
| `development/RME/TASKS/TODO.scripts.md` | Tasks S-1 through S-8: 205 INT files, SCRIPTS.LST, quest/companion tests |
| `development/RME/TASKS/TODO.dialog.md` | Tasks D-1 through D-15: 370+ MSG validation, format checker, NPC tests |
| `development/RME/TASKS/TODO.sound-fonts-config.md` | Tasks SF-1 through SF-12: ACM/AAF, configs, VAULT13.GAM |
| `development/RME/TASKS/TODO.ios.md` | Tasks IO-1 through IO-11: IPA build, simulator, touch, case sensitivity |
| `development/RME/TASKS/TODO.release.md` | Tasks R-1 through R-5: DMG/IPA packaging, smoke tests, GitHub Release |

### Execution Order

Execute the TODO files in this order. Each phase depends on the previous one succeeding:

```
Phase 1: Infrastructure (TODO.infrastructure.md)
   └─ Build engine, patch data, validate static pipeline, install data

Phase 2: Runtime — Categories (run in parallel where possible)
   ├─ TODO.maps.md          ← highest risk, do first
   ├─ TODO.art.md           ← visual breakage
   ├─ TODO.prototypes.md    ← gameplay breakage
   ├─ TODO.scripts.md       ← logic breakage
   ├─ TODO.dialog.md        ← text/conversation breakage
   └─ TODO.sound-fonts-config.md  ← minor but must verify

Phase 3: iOS Validation (TODO.ios.md)
   └─ Repeat key tests on iOS Simulator

Phase 4: Release Builds (TODO.release.md)
   └─ Package DMG + IPA, run smoke tests

Phase 5: Sign-Off (OUTCOME.md)
   └─ Verify all 5 gates pass, collect evidence, update status
```

### Rules

1. **Use project scripts** — `./scripts/build/build-macos.sh`, `./scripts/test/test-ios-simulator.sh`, etc. Do NOT run raw cmake/xcodebuild commands.
2. **No git rebases** — read-only git ops only unless explicitly told otherwise.
3. **Be honest** — if a test fails, report it. Do not fabricate pass results. Previous agents falsified "72/0/0" map results. That is unacceptable.
4. **Evidence required** — every claim of "PASS" must have a corresponding artifact (log, screenshot, CSV row, checksum file) saved to `development/RME/ARTIFACTS/evidence/`.
5. **Update as you go** — after completing each TODO task, update the checkbox in the TODO file (`[ ]` → `[x]`) and note the date. After completing a full gate, update `OUTCOME.md`.
6. **One simulator at a time** — for iOS testing, run `--shutdown` before booting a new sim.

### Subagent Prompts (Optional)

If you need to delegate deep research to subagents, pre-written prompts are available:

| Prompt | Use When |
|--------|----------|
| `PROMPTS/01-inventory.md` | You need a fresh audit of all RME files in the repo |
| `PROMPTS/02-patch-analysis.md` | You need deep analysis of what the 1,126 files actually change |
| `PROMPTS/03-source-review.md` | You need to understand engine code changes for RME compatibility |
| `PROMPTS/04-validation-audit.md` | You need to audit existing validation evidence for honesty |
| `PROMPTS/05-pipeline-analysis.md` | You need to understand the patching/validation script pipeline |

These are reference material — you do NOT need to run all 5 before starting. The TODO files already contain all the information extracted from these research prompts.

### Definition of Done

From `OUTCOME.md`, all 5 gates must be GREEN:

1. **Gate 1 — Static Pipeline** (6 criteria): Patch applies, checksums match, case correct, LSTs valid, protos load, configs present
2. **Gate 2 — macOS Runtime** (8 criteria): All 72 maps load, art renders, protos function, scripts execute, dialogs display, sound plays, fonts render, no crashes
3. **Gate 3 — iOS Runtime** (6 criteria): IPA builds, app launches, data loads, touch works, maps render, no crashes
4. **Gate 4 — Gameplay** (5 criteria): New quests completable, companion armor works, restored locations accessible, endgame slides correct, no major regressions
5. **Gate 5 — Release** (4 criteria): DMG packages correctly, IPA packages correctly, clean install works, README/config included

**Start with Phase 1 (TODO.infrastructure.md) now.**
