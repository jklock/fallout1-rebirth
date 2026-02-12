# Gate 2 Triage — CARAVAN ⚠️

**Short summary:** Missing `MAPS/CARAVAN` caused autorun map load to fail (rc=-1), producing presentation anomalies and two suspicious `GNW_SHOW_RECT` events (surf_pre>0 && surf_post==0). The run was terminated by the test harness due to timeout.

---

## Top suspicious findings (up to 5)

1) **Missing datafile (MAPS\CARAVAN) — probable root cause**

```
[2026-02-10 17:18:06] [GNW_SHOW_RECT] seq=128 surfacePtr=0xa166bd950 dest=(320,240) copy=1x1 src_nonzero=1 surf_pre=1 surf_post=1 disp_pre=1 disp_post=1 tex_pre=0 tex_post=0
[2026-02-10 17:18:06] [AUTORUN_MAP] load_start map="CARAVAN"
[2026-02-10 17:18:06] [DB_OPEN_MISS] source=patches path="data/MAPS/CARAVAN" mode="rb"
[2026-02-10 17:18:06] [DB_OPEN_FAIL] source=datafile reason=missing request="MAPS\CARAVAN" path=".\MAPS\CARAVAN" mode="rb"
[2026-02-10 17:18:06] [AUTORUN_MAP] load_end map="CARAVAN" rc=-1
```
Classification: **missing datafile (MAPS)**

---

2) **Suspicious drawing condition — GNW_SHOW_RECT (event #1)**

```
[2026-02-10 17:18:06] [RENDER_PRESENT_TOP_PIXELS] seq=129 pre=230400 present=856080
[2026-02-10 17:18:06] [WIN_FILL_RECT] dest=0,380 w=640 h=100 bk_color=0 srcPtr=0xa15588010
[2026-02-10 17:18:06] [DEBUG_MEM] no-overlap buf=0xa15588010 width=640 height=100
[2026-02-10 17:18:06] [GNW_SHOW_RECT_SRC] seq=130 srcPtr=0xa15588010 surfacePtr=0xa166d3610 dest=(0,380) copy=640x100 srcOffset=(0,0) sampleSrc0=0 sampleSurf0=228
[2026-02-10 17:18:06] [GNW_SHOW_RECT] seq=131 surfacePtr=0xa166d3610 dest=(0,380) copy=640x100 src_nonzero=0 surf_pre=64000 surf_post=0 disp_pre=0 disp_post=0 tex_pre=64000 tex_post=64000
```
Classification: **suspicious drawing condition (surf_pre>0 && surf_post==0)**

---

3) **Suspicious drawing condition — GNW_SHOW_RECT (event #2)**

```
[2026-02-10 17:18:07] [WIN_FILL_RECT] dest=0,0 w=640 h=380 bk_color=0 srcPtr=0xa1554c010
[2026-02-10 17:18:07] [GNW_SHOW_RECT_SRC] seq=159 srcPtr=0xa1554c010 surfacePtr=0xa16698010 dest=(0,0) copy=640x380 srcOffset=(0,0) sampleSrc0=0 sampleSurf0=207
[2026-02-10 17:18:07] [GNW_SHOW_RECT] seq=160 surfacePtr=0xa16698010 dest=(0,0) copy=640x380 src_nonzero=0 surf_pre=243200 surf_post=0 disp_pre=0 disp_post=0 tex_pre=243200 tex_post=0
```
Classification: **suspicious drawing condition (surf_pre>0 && surf_post==0)**

---

4) **Present anomaly (render) — possible symptom of missing map**

```
[2026-02-10 17:18:05] [RENDER_PRESENT_ANOMALY] seq=126 pre=0 present=856080
[2026-02-10 17:18:06] [RENDER_PRESENT_ANOMALY] screenshot=/Volumes/Storage/GitHub/fallout1-rebirth/development/RME/ARTIFACTS/evidence/gate-2/runtime/present-anomalies/f1r-present-anom-126.bmp
[2026-02-10 17:18:06] [RENDER_PRESENT_TOP_PIXELS] seq=127 pre=0 present=856080
```
Classification: **suspicious drawing / present anomaly**

---

5) **Timeout / hang — test harness killed process**

```
./scripts/patch/rme-repeat-map.sh: line 31: 48319 Terminated: 15          ( sleep "$TIMEOUT"; if kill -0 "$pid" 2> /dev/null; then
    echo "[TIMEOUT] Killing pid $pid after $TIMEOUT seconds" >> "$RUN_LOG"; kill "$pid" 2> /dev/null || true; sleep 2; kill -9 "$pid" 2> /dev/null || true;
fi )
```
Classification: **timeout / hang**

---

## Quick recommendations (priority order)

1. **P0:** Restore / add `MAPS/CARAVAN` to the app data (or confirm the patched data includes it). Re-run M-5 for CARAVAN. ✅
2. **P1:** If missing-by-design, update test to skip or mark missing maps as expected failures (avoid timeouts). ⚠️
3. **P1:** If the GNW_SHOW_RECT anomalies persist after map restore, open a focused bug (rendering/memory) and attach the `*_patchlog.txt` + screenshots. 🔧

## Evidence
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-1-timeout180.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog_analyze.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/screenshots-individual/CARAVAN.iter01.bmp`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.patchlog.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.run.log`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01.patchlog_analyze.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-fail-01-present.bmp`

---

**Owner/next action:** Executor — restore map files / re-run M-5

### Manual run evidence (2026-02-11T03:01:47Z)
- 
- 
- 


### Manual run evidence (2026-02-11T03:01:57Z)
- development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-manual-run.log
- development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-manual-scr.bmp
- development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.manual.patchlog_analyze.txt
