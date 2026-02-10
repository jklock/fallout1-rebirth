# Gate 2 Triage — ZDESERT1 ⚠️

**Short summary:** Missing `MAPS/ZDESERT1` caused autorun load failure (rc=-1). Analyzer flagged two suspicious `GNW_SHOW_RECT` events (surf_pre>0 && surf_post==0). The run was terminated by the harness due to timeout.

---

## Top suspicious findings (up to 5)

1) **Missing datafile (MAPS\ZDESERT1)**

```
[2026-02-10 17:22:36] [AUTORUN_MAP] load_start map="ZDESERT1"
[2026-02-10 17:22:36] [DB_OPEN_MISS] source=patches path="data/MAPS/ZDESERT1" mode="rb"
[2026-02-10 17:22:36] [DB_OPEN_FAIL] source=datafile reason=missing request="MAPS\ZDESERT1" path=".\MAPS\ZDESERT1" mode="rb"
[2026-02-10 17:22:36] [AUTORUN_MAP] load_end map="ZDESERT1" rc=-1
```
Classification: **missing datafile (MAPS)**

---

2) **Suspicious drawing condition — GNW_SHOW_RECT (event #1)**

```
[2026-02-10 17:22:36] [WIN_FILL_RECT] dest=0,380 w=640 h=100 bk_color=0 srcPtr=0x7afd88010
[2026-02-10 17:22:36] [DEBUG_MEM] no-overlap buf=0x7afd88010 width=640 height=100
[2026-02-10 17:22:36] [GNW_SHOW_RECT_SRC] seq=130 srcPtr=0x7afd88010 surfacePtr=0x7b0ad3610 dest=(0,380) copy=640x100 srcOffset=(0,0) sampleSrc0=0 sampleSurf0=228
[2026-02-10 17:22:36] [GNW_SHOW_RECT] seq=131 surfacePtr=0x7b0ad3610 dest=(0,380) copy=640x100 src_nonzero=0 surf_pre=64000 surf_post=0 disp_pre=0 disp_post=0 tex_pre=64000 tex_post=64000
```
Classification: **suspicious drawing condition (surf_pre>0 && surf_post==0)**

---

3) **Suspicious drawing condition — GNW_SHOW_RECT (event #2)**

```
[2026-02-10 17:22:36] [GNW_SHOW_RECT_SRC] seq=159 srcPtr=0x7afd4c010 surfacePtr=0x7b0a98010 dest=(0,0) copy=640x380 srcOffset=(0,0) sampleSrc0=0 sampleSurf0=207
[2026-02-10 17:22:36] [GNW_SHOW_RECT] seq=160 surfacePtr=0x7b0a98010 dest=(0,0) copy=640x380 src_nonzero=0 surf_pre=243200 surf_post=0 disp_pre=0 disp_post=0 tex_pre=243200 tex_post=0
```
Classification: **suspicious drawing condition (surf_pre>0 && surf_post==0)**

---

4) **Present anomaly & screenshot (symptom)**

```
[2026-02-10 17:22:35] [RENDER_PRESENT_ANOMALY] seq=126 pre=0 present=856080
[2026-02-10 17:22:36] [RENDER_PRESENT_ANOMALY] screenshot=/Volumes/Storage/GitHub/fallout1-rebirth/development/RME/ARTIFACTS/evidence/gate-2/runtime/present-anomalies/f1r-present-anom-126.bmp
[2026-02-10 17:22:36] [RENDER_PRESENT_TOP_PIXELS] seq=127 pre=0 present=856080
```
Classification: **suspicious drawing / present anomaly**

---

5) **Timeout / hang — harness terminated the process**

```
./scripts/patch/rme-repeat-map.sh: line 61: 52069 Terminated: 15  ( cd "$RESOURCES_DIR" && env -i PATH="$PATH" F1R_AUTORUN_MAP="$MAP" ... "$EXE" > "$RUN_LOG" 2>&1 )
./scripts/patch/rme-repeat-map.sh: line 31: 52071 Terminated: 15 ( sleep "$TIMEOUT"; ... echo "[TIMEOUT] Killing pid $pid after $TIMEOUT seconds" >> "$RUN_LOG"; ... )
```
Classification: **timeout / hang**

---

## Quick recommendations

1. **P0:** Restore `MAPS/ZDESERT1` to data (or confirm patched data includes it); re-run M-5 for ZDESERT1. ✅
2. **P1:** If file intentionally absent, mark as expected fail or update harness to skip gracefully. ⚠️
3. **P1:** If `GNW_SHOW_RECT` anomalies still occur after map restore, file a rendering/memory bug with `patchlog` + screenshot. 🔧

## Evidence
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-fail-01.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/ZDESERT1-10.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/ZDESERT1.iter01.patchlog.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/ZDESERT1.iter01.patchlog_analyze.txt`

**Owner/next action:** Executor — restore map files / re-run M-5
