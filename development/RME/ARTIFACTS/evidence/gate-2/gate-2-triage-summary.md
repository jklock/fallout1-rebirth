# Gate 2 Triage Summary — M-5 Flaky repeats (CARAVAN, ZDESERT1, TEMPLAT1)

**One-line findings:**

- **CARAVAN:** Missing `MAPS/CARAVAN` → autorun load failed; produced `GNW_SHOW_RECT surf_pre>0 && surf_post==0` anomalies and test-timeout. 🔥
- **ZDESERT1:** Missing `MAPS/ZDESERT1` → autorun load failed; two `GNW_SHOW_RECT` anomalies; test-timeout. 🔥
- **TEMPLAT1:** Missing `MAPS/TEMPLAT1` → autorun load failed; two `GNW_SHOW_RECT` anomalies; test-timeout. 🔥

---

## Aggregate root cause hypothesis

All three failures share the same primary symptom: **missing map datafile** (DB_OPEN_FAIL request="MAPS\<MAPNAME>"). The missing data causes autorun to abort (rc=-1) and produces downstream rendering/present anomalies (`GNW_SHOW_RECT` surf_pre>0 && surf_post==0). The harness kills the run after the configured timeout, producing a timeout/failure rather than a clean expected failure.

---

## Recommended fixes (priority order)

1. **P0 — Restore missing map files**
   - Add `MAPS/CARAVAN`, `MAPS/ZDESERT1`, and `MAPS/TEMPLAT1` to the patched data bundle (or confirm they exist in `GOG/patchedfiles/data/MAPS` and are copied into the app bundle during install).
   - Re-run M-5 repeats for these maps and validate pass.

2. **P1 — Avoid timeouts on missing data**
   - Modify the test harness or in-engine autorun flow to detect `AUTORUN_MAP` load failure (rc != 0) and fail fast with clear diagnostic rather than letting the app hang until the external timeout.

3. **P1 — Investigate GNW_SHOW_RECT anomalies if persistent**
   - If GNW anomalies survive after map restoration, open a focused bug (render/memory) with `patchlog.txt`, `patchlog_analyze.txt`, and present-anomaly screenshots. May indicate double free/zeroed buffers or unexpected renderflow.

4. **P2 — Improve test expectations & asset checks**
   - Add a pre-check step in the sweep implementation to verify required `MAPS/` entries exist and report missing assets as a distinct category (expected failure vs flaky hang).

---

## Next action (recommended)

- **Executor:** Restore missing maps in patched data, re-run M-5 repeats for the three maps. If PASS, proceed with M-6. If FAIL, escalate with `patchlog` and screenshot evidence and create a focused bug for rendering.

---

## Artifacts created

- `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-CARAVAN.md`
- `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-ZDESERT1.md`
- `development/RME/ARTIFACTS/evidence/gate-2/gate-2-triage-TEMPLAT1.md`

---

**Short priority checklist:**
1. Restore maps (CARAVAN, ZDESERT1, TEMPLAT1) — P0 ✅
2. Re-run M-5 (repeats) — P0 ✅
3. If still failing, collect logs and open render bug — P1 🔧

---

**Owner / next step:** Executor — implement P0 and re-run M-5
