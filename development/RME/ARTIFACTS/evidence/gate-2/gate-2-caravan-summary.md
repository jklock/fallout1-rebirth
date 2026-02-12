# Gate 2 — CARAVAN repeat (run 1) — Summary

**Summary (short):** The CARAVAN repeat run terminated early (signal SIGTERM) and did not produce the expected run log or patchlog. The analyzer failed with a FileNotFoundError because the patchlog file was missing. Most likely the process hit the runner's timeout (default TIMEOUT=60), was killed by the wrapper, and therefore produced no patchlog/screenshot for analysis.

---

## Suspicious lines extracted

From the repeat run wrapper (repeats/CARAVAN-10.txt):

```
./scripts/patch/rme-repeat-map.sh: line 44: development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.run.log: No such file or directory
./scripts/patch/rme-repeat-map.sh: line 31:  8041 Terminated: 15          ( sleep "$TIMEOUT"; if kill -0 "$pid" 2> /dev/null; then
    echo "[TIMEOUT] Killing pid $pid after $TIMEOUT seconds" >> "$RUN_LOG"; kill "$pid" 2> /dev/null || true; sleep 2; kill -9 "$pid" 2> /dev/null || true;
fi )
SUSPICIOUS event found in CARAVAN run 1; analyze output: development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog_analyze.txt
Artifacts are available in:
  patchlog: development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog.txt
  run log: development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.run.log
  screenshot (if any): development/RME/ARTIFACTS/evidence/gate-2/runtime/screenshots-individual/CARAVAN.iter01.bmp
EXIT:3
```

From the analyzer output (patchlogs/CARAVAN.iter01.patchlog_analyze.txt):

```
Analyzing development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog.txt
Traceback (most recent call last):
  File "/Volumes/Storage/GitHub/fallout1-rebirth/scripts/dev/patchlog_analyze.py", line 120, in <module>
    res = analyze(path)
  File "/Volumes/Storage/GitHub/fallout1-rebirth/scripts/dev/patchlog_analyze.py", line 46, in analyze
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
FileNotFoundError: [Errno 2] No such file or directory: 'development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog.txt'
```

---

## Interpretation (3–4 sentences)
The run process did not produce the expected outputs (run log, patchlog, or screenshot). The runner's timeout wrapper indicates the child was terminated (signal 15) — likely because it exceeded the default TIMEOUT (60s). Because no patchlog was written, the analyzer raised a FileNotFoundError and could not determine in-map causes (e.g., missing asset or script error). This pattern strongly suggests either a hang during early startup or a crash before patchlog/screenshot generation.

---

## Recommended remedial action (specific)
1. Increase the TIMEOUT and re-run a single iteration to capture the run log and patchlog for analysis. Example command (from repo root):

```
TIMEOUT=180 ./scripts/patch/rme-repeat-map.sh CARAVAN 1
```

2. If the run still fails or produces no logs, run the executable manually with the same environment variables to capture stdout/stderr and test under the debugger:

```
cd "$(pwd)/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources" && \
  env -i PATH="$PATH" F1R_AUTORUN_MAP=CARAVAN F1R_AUTOSCREENSHOT=1 F1R_PATCHLOG=1 \
  F1R_PATCHLOG_PATH="$(pwd)/development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog.txt" \
  F1R_PATCHLOG_VERBOSE=1 "$PWD/../../MacOS/fallout1-rebirth" > run.local.log 2>&1
```

3. If a hang or crash persists, run under LLDB / lldb -- to capture a backtrace or inspect missing resources referenced at startup.

---

**Next recommended command:**

```
TIMEOUT=180 ./scripts/patch/rme-repeat-map.sh CARAVAN 1
```

---

File created: `development/RME/ARTIFACTS/evidence/gate-2/gate-2-caravan-summary.md`
