# Gate 2 Triage — TEMPLAT1 ⚠️

**Short summary:** Missing `MAPS/TEMPLAT1` caused autorun load to fail (rc=-1). Analyzer flagged two `GNW_SHOW_RECT` events where surf_pre>0 and surf_post==0. Run was terminated by the harness due to timeout.

---

## Top suspicious findings (up to 5)

1) **Missing datafile (MAPS\TEMPLAT1)**

```
[2026-02-10 17:24:26] [AUTORUN_MAP] load_start map="TEMPLAT1"
[2026-02-10 17:24:26] [DB_OPEN_MISS] source=patches path="data/MAPS/TEMPLAT1" mode="rb"
[2026-02-10 17:24:26] [DB_OPEN_FAIL] source=datafile reason=missing request="MAPS\TEMPLAT1" path=".\MAPS\TEMPLAT1" mode="rb"
[2026-02-10 17:24:26] [AUTORUN_MAP] load_end map="TEMPLAT1" rc=-1
```
Classification: **missing datafile (MAPS)**

---

2) **Suspicious drawing condition — GNW_SHOW_RECT (event #1)**

```
[2026-02-10 17:24:26] [WIN_FILL_RECT] dest=0,380 w=640 h=100 bk_color=0 srcPtr=0x947d88010
[2026-02-10 17:24:26] [DEBUG_MEM] no-overlap buf=0x947d88010 width=640 height=100
[2026-02-10 17:24:26] [GNW_SHOW_RECT_SRC] seq=130 srcPtr=0x947d88010 surfacePtr=0x948ad3610 dest=(0,380) copy=640x100 srcOffset=(0,0) sampleSrc0=0 sampleSurf0=228
[2026-02-10 17:24:26] [GNW_SHOW_RECT] seq=131 surfacePtr=0x948ad3610 dest=(0,380) copy=640x100 src_nonzero=0 surf_pre=64000 surf_post=0 disp_pre=0 disp_post=0 tex_pre=64000 tex_post=64000
```
Classification: **suspicious drawing condition (surf_pre>0 && surf_post==0)**

---

3) **Suspicious drawing condition — GNW_SHOW_RECT (event #2)**

```
[2026-02-10 17:24:26] [GNW_SHOW_RECT_SRC] seq=159 srcPtr=0x947d4c010 surfacePtr=0x948a98010 dest=(0,0) copy=640x380 srcOffset=(0,0) sampleSrc0=0 sampleSurf0=207
[2026-02-10 17:24:26] [GNW_SHOW_RECT] seq=160 surfacePtr=0x948a98010 dest=(0,0) copy=640x380 src_nonzero=0 surf_pre=243200 surf_post=0 disp_pre=0 disp_post=0 tex_pre=243200 tex_post=0
```
Classification: **suspicious drawing condition (surf_pre>0 && surf_post==0)**

---

4) **Present anomaly & screenshot**

```
[2026-02-10 17:24:25] [RENDER_PRESENT_ANOMALY] seq=126 pre=0 present=856080
[2026-02-10 17:24:26] [RENDER_PRESENT_ANOMALY] screenshot=/Volumes/Storage/GitHub/fallout1-rebirth/development/RME/ARTIFACTS/evidence/gate-2/runtime/present-anomalies/f1r-present-anom-126.bmp
[2026-02-10 17:24:26] [RENDER_PRESENT_TOP_PIXELS] seq=127 pre=0 present=856080
```
Classification: **suspicious drawing / present anomaly**

---

5) **Timeout / hang — harness killed process**

```
./scripts/patch/rme-repeat-map.sh: line 31: 54225 Terminated: 15          ( sleep "$TIMEOUT"; if kill -0 "$pid" 2> /dev/null; then
    echo "[TIMEOUT] Killing pid $pid after $TIMEOUT seconds" >> "$RUN_LOG"; kill "$pid" 2> /dev/null || true; sleep 2; kill -9 "$pid" 2> /dev/null || true;
fi )
```
Classification: **timeout / hang**

---

## Quick recommendations

1. **P0:** Restore `MAPS/TEMPLAT1` to data; re-run M-5 for TEMPLAT1. ✅
2. **P1:** If intentionally missing, adjust test expectations (skip/expected fail). ⚠️
3. **P1:** If GNW anomalies persist after map restore, open a render/memory bug with `patchlog` + screenshot. 🔧

## Evidence
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-10.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/TEMPLAT1.iter01.patchlog.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/TEMPLAT1.iter01.patchlog_analyze.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.patchlog.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.run.log`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.patchlog_analyze.txt`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01-present.bmp`

**Owner/next action:** Executor — restore map files / re-run M-5

### Manual run evidence (2026-02-11T03:06:41Z)
- no manual patchlog produced; using  artifacts:
  - development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.patchlog.txt
  - development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.run.log
  - development/RME/ARTIFACTS/evidence/gate-2/repeats/TEMPLAT1-fail-01.bmp
