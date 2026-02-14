# RME Domain Prompt Pack

Use these prompts to run each domain end-to-end, including development, testing, validation, and documentation updates.

## Global Rules (for every domain prompt)
- Use canonical game data source: `GOG/patchedfiles`.
- Keep `scripts/patch/*` patch-only and `scripts/test/*` test-only.
- Do not commit generated runtime evidence/logs/screenshots/patchlogs.
- Update domain docs after each run:
  - `development/RME/PLAN/domains/<domain>.md`
  - `development/RME/TODO/domains/<domain>.md`
  - `development/RME/OUTCOME/domains/<domain>.md`
  - `development/RME/VALIDATE/domains/<domain>.md`
  - `development/RME/TODO/PROGRESS.MD`

## Prompt Files
1. `development/RME/PROMPTS/domains/01-patch-integrity.md`
2. `development/RME/PROMPTS/domains/02-maps-runtime.md`
3. `development/RME/PROMPTS/domains/03-critters-proto.md`
4. `development/RME/PROMPTS/domains/04-scripts-dialog.md`
5. `development/RME/PROMPTS/domains/05-audio.md`
6. `development/RME/PROMPTS/domains/06-art-ui-fonts.md`
7. `development/RME/PROMPTS/domains/07-text-localization.md`
8. `development/RME/PROMPTS/domains/08-platform-macos.md`
9. `development/RME/PROMPTS/domains/09-platform-ios.md`
10. `development/RME/PROMPTS/domains/10-release-packaging.md`

## Recommended Execution Order
1. patch-integrity
2. maps-runtime
3. critters-proto
4. scripts-dialog
5. audio
6. art-ui-fonts
7. text-localization
8. platform-macos
9. platform-ios
10. release-packaging
