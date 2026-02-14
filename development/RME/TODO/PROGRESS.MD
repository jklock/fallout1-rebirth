# RME Progress Matrix (Domain Split)

Last updated: 2026-02-14

## Domain Status
- patch-integrity: complete (2026-02-14)
- maps-runtime: complete (2026-02-14)
- critters-proto: complete (2026-02-14)
- scripts-dialog: complete (2026-02-14)
- audio: complete (2026-02-14)
- art-ui-fonts: complete (2026-02-14)
- text-localization: complete (2026-02-14)
- platform-macos: complete (2026-02-14)
- platform-ios: complete (2026-02-14)
- release-packaging: complete (2026-02-14)

## Recent Updates
- 2026-02-14T14:35:54Z: `maps-runtime` regression-control retest after domain `06` harness updates.
- Command: `python3 scripts/test/rme-repeat-map.py JUNKDEMO 1 --timeout 120 --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"`
- Result: pass (`EC=0`).
- Evidence: `development/RME/validation/runtime/02-regression-junkdemo-20260214T143554Z.log`.
- Next action: none.

- 2026-02-14T14:35:03Z: Completion criteria aligned to automated load/no-crash validation for previously manual-gated domains.
- `scripts-dialog` commands: `python3 scripts/test/rme-audit-script-refs.py --patched-dir GOG/patchedfiles --out-dir development/RME/validation/raw`
- `scripts-dialog` result: pass after remediation (`TypeError` write-path fix in `scripts/test/rme-audit-script-refs.py`).
- `scripts-dialog` evidence:
- `development/RME/validation/scripts-dialog/04-audit-script-refs-20260214T131729Z.log`
- `development/RME/validation/scripts-dialog/04-audit-script-refs-rerun-20260214T131757Z.log`

- 2026-02-14T13:18:10Z: `audio` rerun completed.
- Commands:
- `./scripts/test/rme-ensure-patched-data.sh`
- `./scripts/test/test-macos.sh`
- `./scripts/test/test-ios-simulator.sh`
- Result: pass (`EC1=0`, `EC2=0`, `EC3=0`), canonical simulator data copy and app launch confirmed.
- Evidence:
- `development/RME/validation/audio/05-preflight-20260214T131810Z.log`
- `development/RME/validation/audio/05-test-macos-20260214T131810Z.log`
- `development/RME/validation/audio/05-test-ios-simulator-20260214T131810Z.log`

- 2026-02-14T13:31:47Z: `art-ui-fonts` rerun completed after remediation.
- Initial failure class: harness/tooling issue (`BRODEAD.MAP` timeout caused by missing canonical working-dir).
- Fixes: `scripts/test/rme-repeat-map.py` and `scripts/test/rme-runtime-sweep.py` now enforce `RME_WORKING_DIR=GOG/patchedfiles`.
- Commands:
- `python3 scripts/test/rme-repeat-map.py BRODEAD 1 --timeout 120 --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth"`
- `python3 scripts/test/rme-runtime-sweep.py --exe "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/MacOS/fallout1-rebirth" --timeout 120 --out-dir development/RME/validation/runtime`
- `python3 scripts/dev/patchlog_analyze.py development/RME/validation/runtime/patchlogs/*.patchlog.txt`
- Result: pass (72/72 sweep, analyzer clean).
- Evidence:
- `development/RME/validation/art-ui-fonts/06-runtime-sweep-20260214T131955Z.log`
- `development/RME/validation/art-ui-fonts/06-repeat-brodead-postfix2-20260214T133101Z.log`
- `development/RME/validation/art-ui-fonts/06-runtime-sweep-rerun-20260214T133147Z.log`
- `development/RME/validation/art-ui-fonts/06-patchlog-analyze-rerun-20260214T133147Z.log`
- `development/RME/validation/runtime/runtime_map_sweep.csv`

- 2026-02-14T14:30:52Z: `text-localization` rerun completed.
- Command: `./scripts/patch/rebirth-validate-data.sh --patched GOG/patchedfiles --base GOG/unpatchedfiles --rme third_party/rme`
- Result: pass (`EC=0`).
- Evidence: `development/RME/validation/text-localization/07-rebirth-validate-data-20260214T143052Z.log`.

- 2026-02-14T14:32:18Z: `platform-macos` rerun completed.
- Commands:
- `./scripts/test/rme-ensure-patched-data.sh --target-app "build-macos/RelWithDebInfo/Fallout 1 Rebirth.app"`
- `./scripts/test/test-macos-headless.sh`
- `./scripts/test/test-macos.sh`
- Result: pass (`EC1=0`, `EC2=0`, `EC3=0`), no-crash headless launch check passed.
- Evidence:
- `development/RME/validation/macos/08-preflight-20260214T143218Z.log`
- `development/RME/validation/macos/08-test-macos-headless-20260214T143218Z.log`
- `development/RME/validation/macos/08-test-macos-20260214T143218Z.log`

- 2026-02-14T06:09:17Z: `platform-ios` completed.
- Evidence:
- `development/RME/validation/ios/09-test-ios-headless-20260214T060917Z.log`
- `development/RME/validation/ios/09-test-ios-simulator-20260214T060917Z.log`

- 2026-02-14T06:14:37Z: `release-packaging` completed after remediation.
- Evidence:
- `development/RME/validation/release/10-build-releases-20260214T061259Z.log`
- `development/RME/validation/release/10-dev-format-20260214T061429Z.log`
- `development/RME/validation/release/10-build-releases-rerun-20260214T061437Z.log`

- 2026-02-14T05:53:57Z: `critters-proto` completed.
- 2026-02-14T05:02:00Z: `maps-runtime` completed after initial remediation.
- 2026-02-14T03:06:12Z: `patch-integrity` completed.

## Remaining Blockers
- None.

## Source Documents
- Plans: `development/RME/PLAN/domains/*.md`
- TODOs: `development/RME/TODO/domains/*.md`
- Outcomes: `development/RME/OUTCOME/domains/*.md`
- Validation: `development/RME/VALIDATE/domains/*.md`

## Update Rule
After each domain run, update the corresponding files in all four sets:
1. `PLAN/domains/<domain>.md`
2. `TODO/domains/<domain>.md`
3. `OUTCOME/domains/<domain>.md`
4. `VALIDATE/domains/<domain>.md`
