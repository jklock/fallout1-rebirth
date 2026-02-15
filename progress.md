# Progress - 2026-02-15

## Completed
- [x] Captured current input failure state and root-cause hypotheses.
- [x] Produced SDL3/iPadOS input investigation with evidence.
- [x] Located canonical unpatched config sources in `fallout1-rebirth-gamefiles/unpatchedfiles`.
- [x] Confirmed requirement change: do not trim templates; make unpatched config keys work.

## In Progress
- [x] Build and publish full config-compatibility project plan (implementation + validation gates).
- [x] Generate key manifests from unpatched baseline files.

## Next
- [x] Add initial key-coverage baseline snapshot.
- [ ] Expand key-by-key runtime coverage matrix to full per-key verification status.
- [ ] Implement compatibility layer for missing keys in priority order.
- [ ] Add automated key-effect validation harness.

## Notes
- Input investigation: `docs/audit/input-investigation-2026-02-15.md`
- Config compatibility plan: `docs/audit/config-compat-project-plan-2026-02-15.md`
- Initial coverage baseline: `docs/audit/config-key-coverage-baseline-2026-02-15.md`
- Key manifests: `docs/audit/key-manifests/unpatched-f1_res.keys`, `docs/audit/key-manifests/unpatched-fallout.cfg.keys`, `docs/audit/key-manifests/gog-f1_res.keys`
