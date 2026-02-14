# RME Subagent Orchestrator Prompt

## Objective
Coordinate domain-specific validation runs to reach 100% RME coverage and 100% gameplay functionality, using canonical patched data only.

## Hard Constraints
- Use `GOG/patchedfiles` for every test/post-build validation task.
- Keep `scripts/patch/*` for patching actions and `scripts/test/*` for validation actions.
- Do not commit generated runtime evidence/logs/screenshots/patchlogs.

## Canonical Command Order
1. `./scripts/test/rme-ensure-patched-data.sh`
2. `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme`
3. `./scripts/patch/rebirth-refresh-validation.sh --unpatched GOG/unpatchedfiles --patched GOG/patchedfiles --rme third_party/rme --out development/RME/validation`
4. Hotspot repeats (`CARAVAN`, `ZDESERT1`, `TEMPLAT1`) with `scripts/test/rme-repeat-map.py`
5. Full sweep with `scripts/test/rme-runtime-sweep.py`
6. Script/proto audit with `scripts/test/rme-audit-script-refs.py`
7. macOS/iOS gates

## Domain Subtasks
- Maps: stabilize failures and verify 72-map sweep completion.
- Critters/Proto: close unresolved script-index/proto-link blockers.
- Scripts/Dialog: verify key quest/dialog transitions in manual pass.
- Audio: verify representative SFX/music events during gameplay.
- Art/UI/Fonts: verify no black-render regressions and UI completeness.
- Platform: ensure macOS and iOS smoke paths use canonical data.

## Domain Prompt Pack
Run domain tasks using the full end-to-end prompts in:
- `development/RME/PROMPTS/domains/README.md`
- `development/RME/PROMPTS/domains/01-patch-integrity.md`
- `development/RME/PROMPTS/domains/02-maps-runtime.md`
- `development/RME/PROMPTS/domains/03-critters-proto.md`
- `development/RME/PROMPTS/domains/04-scripts-dialog.md`
- `development/RME/PROMPTS/domains/05-audio.md`
- `development/RME/PROMPTS/domains/06-art-ui-fonts.md`
- `development/RME/PROMPTS/domains/07-text-localization.md`
- `development/RME/PROMPTS/domains/08-platform-macos.md`
- `development/RME/PROMPTS/domains/09-platform-ios.md`
- `development/RME/PROMPTS/domains/10-release-packaging.md`

## Reporting Requirements
After each execution block, update:
- `development/RME/TODO/PROGRESS.MD`
- `development/RME/TODO/domains/<domain>.md`
- `development/RME/OUTCOME/domains/<domain>.md`
- `development/RME/VALIDATE/domains/<domain>.md`

Include:
- command(s) run
- pass/fail status
- blocker summary
- exact next action
