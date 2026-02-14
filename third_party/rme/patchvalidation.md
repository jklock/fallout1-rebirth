# RME Patch Validation Mapping

Last updated (UTC): 2026-02-14T23:45:00Z

## Scope
This file ties every patch listed in `third_party/rme/readme.txt:6` to concrete payload artifacts and to the exact patch/validation code paths used in this repository.

## Core implementation references
- Patch list source: `third_party/rme/readme.txt:6`
- Core DAT patch apply (`master.xdelta`, `critter.xdelta`): `scripts/patch/patch-rebirth-data.sh:260`, `scripts/patch/patch-rebirth-data.sh:263`
- Core DATA overlay copy (`third_party/rme/DATA` -> output `data/`): `scripts/patch/patch-rebirth-data.sh:274`
- Filename case normalization for payload portability: `scripts/patch/patch-rebirth-data.sh:283`
- Text line-ending normalization (`.lst/.msg/.txt`): `scripts/patch/patch-rebirth-data.sh:433`
- Overlay integrity validation (all payload files exist + hash match): `scripts/test/test-rebirth-validate-data.sh:172`
- DAT result validation against xdelta output: `scripts/test/test-rebirth-validate-data.sh:258`
- Wrapper entry points that invoke the same core patch flow:
  - `scripts/patch/patch-rebirth-app.sh:66`
  - `scripts/patch/patch-rebirth-ipa.sh:66`

## Per-patch mapping

| Patch from `readme.txt` | Concrete payload evidence (representative files) | Applied/validated by code |
|---|---|---|
| Patch 1.2 (by TeamX) | `third_party/rme/master.xdelta`, `third_party/rme/critter.xdelta` | Apply: `scripts/patch/patch-rebirth-data.sh:260`/`:263`; Validate: `scripts/test/test-rebirth-validate-data.sh:258` |
| Patch 1.2.1 (by TeamX) | `third_party/rme/master.xdelta`, `third_party/rme/critter.xdelta` | Apply: `scripts/patch/patch-rebirth-data.sh:260`/`:263`; Validate: `scripts/test/test-rebirth-validate-data.sh:258` |
| Patch 1.3.5 (by TeamX) | `third_party/rme/master.xdelta`, `third_party/rme/critter.xdelta`, `third_party/rme/DATA/SCRIPTS/SCRIPTS.LST` | Apply: `scripts/patch/patch-rebirth-data.sh:260`/`:263`/`:274`; Validate: `scripts/test/test-rebirth-validate-data.sh:172`/`:258` |
| NPC Mod 3.5 (by TeamX) | `third_party/rme/DATA/MAPS/CHILDRN1.MAP`, `third_party/rme/DATA/MAPS/HUBDWNTN.MAP`, `third_party/rme/DATA/SCRIPTS/CHILDRN1.INT` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay: `scripts/test/test-rebirth-validate-data.sh:172` |
| NPC Mod Fix (by TeamX) | `third_party/rme/DATA/SCRIPTS/CHIDINIT.INT`, `third_party/rme/DATA/SCRIPTS/CHIDSCOL.INT`, `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/CHILDMEM.MSG` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay: `scripts/test/test-rebirth-validate-data.sh:172` |
| NPC Mod No Armor (by TeamX) | `third_party/rme/critter.xdelta`, `third_party/rme/DATA/PROTO/CRITTERS/00000313.PRO`, `third_party/rme/DATA/PROTO/CRITTERS/00000339.PRO` | DAT apply/verify: `scripts/patch/patch-rebirth-data.sh:263`, `scripts/test/test-rebirth-validate-data.sh:258`; overlay verify: `scripts/test/test-rebirth-validate-data.sh:172` |
| Restoration Mod 1.0b1 (by TeamX) | `third_party/rme/DATA/MAPS/JUNKCSNO.MAP`, `third_party/rme/DATA/MAPS/HUBOLDTN.MAP`, `third_party/rme/DATA/SCRIPTS/JUNKENT.INT` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay: `scripts/test/test-rebirth-validate-data.sh:172` |
| Restored Good Endings 2.0 (by Sduibek) | `third_party/rme/DATA/TEXT/ENGLISH/CUTS/NARRATE.TXT`, `third_party/rme/DATA/TEXT/ENGLISH/CUTS/NAR_13.TXT`, `third_party/rme/DATA/TEXT/ENGLISH/CUTS/OVRINTRO.SVE` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay/text normalization: `scripts/test/test-rebirth-validate-data.sh:172`/`:230` |
| Dialog Fixes (by Nimrod) | `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/ARADESH.MSG`, `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/NICOLE.MSG`, `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/MORBID.MSG` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay/text normalization: `scripts/test/test-rebirth-validate-data.sh:172`/`:230` |
| Lenore Script Fix (by Winterheart) | `third_party/rme/DATA/SCRIPTS/LENORE.INT` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay: `scripts/test/test-rebirth-validate-data.sh:172` |
| Morbid Behavior Fix (by Foxx) | `third_party/rme/DATA/SCRIPTS/MORBID.INT`, `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/MORBID.MSG` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay/text normalization: `scripts/test/test-rebirth-validate-data.sh:172`/`:230` |
| Mutant Walk Fix (by Jotisz) | `third_party/rme/DATA/ART/CRITTERS/MAMTNTBE.FR5`, `third_party/rme/DATA/ART/CRITTERS/MAMTNTRJ.FRM`, `third_party/rme/critter.xdelta` | DAT + overlay apply: `scripts/patch/patch-rebirth-data.sh:263`/`:274`; Validate: `scripts/test/test-rebirth-validate-data.sh:172`/`:258` |
| Lou Animations Offset Fix (by Lexx) | `third_party/rme/DATA/ART/CRITTERS/MALIEUKA.FRM`, `third_party/rme/DATA/ART/CRITTERS/MALIEURA.FRM`, `third_party/rme/critter.xdelta` | DAT + overlay apply: `scripts/patch/patch-rebirth-data.sh:263`/`:274`; Validate: `scripts/test/test-rebirth-validate-data.sh:172`/`:258` |
| Improved Death Animations Fix (by Lexx) | `third_party/rme/DATA/ART/CRITTERS/MALIEULD.FRM`, `third_party/rme/DATA/ART/CRITTERS/NACHLDBP.FR5`, `third_party/rme/critter.xdelta` | DAT + overlay apply: `scripts/patch/patch-rebirth-data.sh:263`/`:274`; Validate: `scripts/test/test-rebirth-validate-data.sh:172`/`:258` |
| Combat Armor Rocket Launcher Fix (by Lexx) | `third_party/rme/DATA/ART/CRITTERS/HANPWRLA.FRM`, `third_party/rme/DATA/ART/CRITTERS/HANPWRLB.FRM`, `third_party/rme/DATA/ART/CRITTERS/HANPWRLC.FRM` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay: `scripts/test/test-rebirth-validate-data.sh:172` |
| Metal Armor Hammer Thrust Fix (by x'il) | `third_party/rme/DATA/ART/CRITTERS/HMMETLFF.FRM` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay: `scripts/test/test-rebirth-validate-data.sh:172` |
| Original Childkiller Reputation Art (by Skynet) | `third_party/rme/DATA/ART/CRITTERS/NACHLDRA.FRM`, `third_party/rme/DATA/ART/CRITTERS/NACHLDRB.FRM`, `third_party/rme/DATA/MAPS/CHILDRN1.MAP` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay: `scripts/test/test-rebirth-validate-data.sh:172` |
| Fallout 2 Big Pistol Sound | `third_party/rme/DATA/SOUND/SFX/WAE1XXX1.ACM`, `third_party/rme/DATA/SOUND/SFX/WAE1XXX2.ACM` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay: `scripts/test/test-rebirth-validate-data.sh:172` |
| Fallout 2 Font | `third_party/rme/DATA/FONT3.AAF`, `third_party/rme/DATA/FONT4.AAF` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay: `scripts/test/test-rebirth-validate-data.sh:172` |
| Restored Good Endings Compatibility Fix for Restoration Mod 1.0b1 (by Kyojinmaru) | `third_party/rme/DATA/TEXT/ENGLISH/CUTS/NARRATE.TXT`, `third_party/rme/DATA/TEXT/ENGLISH/CUTS/OVRINTRO.TXT` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay/text normalization: `scripts/test/test-rebirth-validate-data.sh:172`/`:230` |
| Dialog Fixes Compatibility Fix for Patch 1.3.5 and Restoration Mod 1.0b1 (by Kyojinmaru) | `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/ARADESH.MSG`, `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/NICOLE.MSG`, `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/CINDY.MSG` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay/text normalization: `scripts/test/test-rebirth-validate-data.sh:172`/`:230` |
| Further Dialog Fixes (by _Pyran_ and Kyojinmaru) | `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/CINDY.MSG`, `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/JUSTIN.MSG`, `third_party/rme/DATA/TEXT/ENGLISH/DIALOG/WTRTHIEF.MSG` | Apply overlay: `scripts/patch/patch-rebirth-data.sh:274`; Validate overlay/text normalization: `scripts/test/test-rebirth-validate-data.sh:172`/`:230` |

## Notes for community reviewers
- Some historical fixes are bundled together in `master.xdelta`/`critter.xdelta`; that means per-fix isolation at binary level requires reverse diffing those DATs against the exact base DATs.
- The repository proves end-to-end application/verification through deterministic script lines listed above and concrete payload artifacts listed per patch.
