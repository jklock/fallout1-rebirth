# RME Integration Risks (Per Mod)

This document lists technical risks of each RME component against the current codebase and runtime behavior.
Assumption: fresh installs only (no save migration).

## Risk Levels
- Low: unlikely to break engine behavior; data-only changes with known scope.
- Medium: script or content changes that can alter quest flow or edge-case behavior.
- High: changes that can affect core gameplay loops or introduce missing asset references.

## Mod-by-Mod Risks

### Patch 1.2 (TeamX)
- Risk level: Medium
- Surface area: scripts, text, proto, maps.
- Risks:
  - Overrides may conflict with existing loose data if users already modded their base data.
  - Some scripts assume specific map or proto states.
- Mitigations:
  - Require patching a clean base data set.
  - Verify critical scripts load (Shady Sands, Junktown, Hub).

### Patch 1.2.1 (TeamX)
- Risk level: Low
- Surface area: small script fixes.
- Risks:
  - Minor script changes could conflict with custom overrides if present.
- Mitigations:
  - Keep 1.2.1 in RME order (already merged in RME).

### Patch 1.3.5 (TeamX)
- Risk level: Medium
- Surface area: large script and dialog overrides.
- Risks:
  - New script behavior can change quest state flows.
- Mitigations:
  - Validate quest flow for major hubs (Shady Sands, Junktown, Hub, Boneyard, Vault 13).

### NPC Mod 3.5 (TeamX)
- Risk level: Medium
- Surface area: NPC scripts, dialog, proto changes.
- Risks:
  - NPC state machine changes can affect combat pacing and script triggers.
  - Armor equip logic can expose inventory edge cases.
- Mitigations:
  - Verify companion leveling and armor switching.

### NPC Mod Fix (TeamX)
- Risk level: Low
- Surface area: NPC script fixes.
- Risks:
  - Assumes NPC Mod 3.5 files are present.
- Mitigations:
  - Ensure NPC Mod 3.5 + Fix are applied together.

### NPC Mod No Armor (TeamX)
- Risk level: Medium
- Surface area: NPC scripts.
- Risks:
  - Mutually exclusive with NPC Mod 3.5 + Fix.
- Mitigations:
  - Exclude No Armor variant from patch set.

### Restoration Mod 1.0b1 (TeamX)
- Risk level: Medium
- Surface area: scripts, dialog, maps.
- Risks:
  - Restored content may reference assets or conditions not present in base data.
  - Quest timing changes can alter pacing expectations.
- Mitigations:
  - Validate restored quests and endings.
  - Verify map transitions and encounter triggers.

### Restored Good Endings 2.0 (Sduibek)
- Risk level: Low to Medium
- Surface area: endings scripts and assets.
- Risks:
  - Ending slide conditions may conflict with other restoration scripts.
- Mitigations:
  - Validate endgame slides after multiple completion paths.

### Dialog Fixes (Nimrod)
- Risk level: Low
- Surface area: dialog `.msg` files.
- Risks:
  - Overwrites can conflict with later dialog edits.
- Mitigations:
  - Verify key dialog entries in major NPCs.

### Lenore Script Fix (Winterheart)
- Risk level: Low
- Surface area: single quest/script.
- Risks:
  - Localized quest flow changes may affect specific endings.
- Mitigations:
  - Validate Lenore quest path.

### Morbid Behavior Fix (Foxx)
- Risk level: Low
- Surface area: a small subset of scripts.
- Risks:
  - None expected beyond localized behavior change.
- Mitigations:
  - Sanity test for the related NPCs/areas.

### Mutant Walk Fix (Jotisz)
- Risk level: Low
- Surface area: animation settings, scripts.
- Risks:
  - Animation references could fail if art overrides are missing.
- Mitigations:
  - Verify mutant animations in relevant zones.

### Lou Animations Offset Fix (Lexx)
- Risk level: Low
- Surface area: art/anim offsets.
- Risks:
  - Art mismatch if overrides are incomplete.
- Mitigations:
  - Verify Lou animation in Boneyard.

### Improved Death Animations Fix (Lexx)
- Risk level: Low
- Surface area: art/anim files.
- Risks:
  - Art mismatch if overrides are incomplete.
- Mitigations:
  - Verify death animations during combat.

### Combat Armor Rocket Launcher Fix (Lexx)
- Risk level: Low
- Surface area: art/anim or proto.
- Risks:
  - Incorrect proto references if base data is mismatched.
- Mitigations:
  - Verify combat armor + rocket launcher animations.

### Metal Armor Hammer Thrust Fix (x'il)
- Risk level: Low
- Surface area: art/anim or proto.
- Risks:
  - Art mismatch if overrides are incomplete.
- Mitigations:
  - Verify hammer thrust animations.

### Original Childkiller Reputation Art (Skynet)
- Risk level: Low
- Surface area: art assets.
- Risks:
  - Requires correct art path overrides.
- Mitigations:
  - Verify reputation icon is visible in Pip-Boy.

### Fallout 2 Big Pistol Sound
- Risk level: Low
- Surface area: sound assets.
- Risks:
  - Missing sound files if overrides are incomplete.
- Mitigations:
  - Verify pistol sound playback.

### Fallout 2 Font
- Risk level: Low
- Surface area: font files (`font3.aaf`, `font4.aaf`).
- Risks:
  - Font mismatch if load order or case is incorrect.
- Mitigations:
  - Verify UI font rendering in dialogs and menus.

### Restored Good Endings Compatibility Fix (Kyojinmaru)
- Risk level: Low
- Surface area: scripts and endings.
- Risks:
  - Depends on restored endings and restoration scripts being present.
- Mitigations:
  - Validate endgame paths with restored content enabled.

### Dialog Fixes Compatibility Fix (Kyojinmaru)
- Risk level: Low
- Surface area: dialog overrides.
- Risks:
  - Order-of-application issues if dialog fixes are missing.
- Mitigations:
  - Apply full RME stack in a single patch run.

### Further Dialog Fixes (Pyran, Kyojinmaru)
- Risk level: Low
- Surface area: dialog `.msg` files.
- Risks:
  - Overwrites may mask other dialog variants.
- Mitigations:
  - Validate key NPC dialog lines.

## Global Integration Risks
- Base data mismatch: xdelta patches require a known base DAT version.
- Case sensitivity: lowercasing is required on case-sensitive file systems.
- In-place patching: if users already modded their data, outcomes are unpredictable.
