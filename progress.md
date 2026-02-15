# Progress - 2026-02-15

## Completed
- [x] Captured current input failure state and root-cause hypotheses.
- [x] Produced SDL3/iPadOS input investigation with evidence.
- [x] Located canonical unpatched config sources in `fallout1-rebirth-gamefiles/unpatchedfiles`.
- [x] Confirmed requirement change: do not trim templates; make unpatched config keys work.
- [x] Reworked config surface validator to enforce baseline key coverage from manifests.
- [x] Expanded `gameconfig/*` and `dist/*` templates to include unpatched baseline keys.
- [x] Wired `f1_res.ini` `[DISPLAY]` keys (`VSYNC`, `FPS_LIMIT`) into runtime apply path.
- [x] Fixed Python compatibility bug in `test-rebirth-refresh-validation.sh` (`Path.write_text(..., newline=...)`).
- [x] Added platform-config enforcement in iOS build and simulator staging scripts (`gameconfig/ios` now wins over stale `patchedfiles` config).
- [x] Updated unattended runner env propagation so input-track steps always receive `BASE_DIR/PATCHED_DIR/GAME_DATA`.
- [x] Re-ran full unattended validation (`track=both`) to a fresh 100% pass.

## In Progress
- [x] Build and publish full config-compatibility project plan (implementation + validation gates).
- [x] Generate key manifests from unpatched baseline files.
- [x] Run unattended `both` track to full green.

## Next
- [x] Add initial key-coverage baseline snapshot.
- [ ] Expand key-by-key runtime coverage matrix to full per-key verification status.
- [ ] Continue input state-machine migration and simulator scenario gates.
- [ ] Add automated key-effect validation harness for remaining legacy compatibility keys.

## Latest Validation
- Unattended command:
  - `bash dev/run-unattended-until-100.sh --track both --max-rounds 1 --sleep 1 --runtime-timeout 45 --base /Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/unpatchedfiles --patched /Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/patchedfiles`
- Result:
  - `dev/state/latest-summary.tsv`: all four steps `PASS` (`rme_quick`, `rme_full`, `macos_headless`, `ios_headless`)
  - `dev/state/history.tsv`: latest row `1	both	2	2	100	PASS	2026-02-15T08:00:11Z`

## Notes
- Input investigation: `docs/audit/input-investigation-2026-02-15.md`
- Config compatibility plan: `docs/audit/config-compat-project-plan-2026-02-15.md`
- Initial coverage baseline: `docs/audit/config-key-coverage-baseline-2026-02-15.md`
- Key manifests: `docs/audit/key-manifests/unpatched-f1_res.keys`, `docs/audit/key-manifests/unpatched-fallout.cfg.keys`, `docs/audit/key-manifests/gog-f1_res.keys`
