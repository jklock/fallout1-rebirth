# Gate 2 — CARAVAN rerun (single iteration with TIMEOUT=180) — Summary

**Result:** FAIL (single iteration terminated early; no patchlog produced)

**Command run (from repo root):**
```
PATH="$(brew --prefix python@3.11)/libexec/bin:$(brew --prefix python@3.11)/bin:$PATH" \
F1R_PATCHLOG=1 TIMEOUT=180 OUT_DIR=development/RME/ARTIFACTS/evidence/gate-2/runtime \
  ./scripts/patch/rme-repeat-map.sh CARAVAN 1 > development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-1-timeout180.txt 2>&1
```

**Observed behaviour:**
- The wrapper terminated the run (signal SIGTERM) and exited with code 3.
- The analyzer output indicates the expected patchlog `CARAVAN.iter01.patchlog.txt` did not exist and raised FileNotFoundError.
- No screenshot was produced.

**Artifacts created/preserved:**
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN-1-timeout180.txt` — captured wrapper output
  - SHA256: `6555c83fa701e063ff1b75d719fde0a68c999ae7936fdb453f6284e90c3b0be5`
- `development/RME/ARTIFACTS/evidence/gate-2/repeats/CARAVAN.iter01.patchlog_analyze.txt` — analyzer output (copied from runtime patchlogs)
  - SHA256: `89c6125d0ba53ef25c272aa2a9efb0828030d28e16767c238555ab6cde65d91c`

**Files expected but missing:**
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog.txt` (no patchlog produced)
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.run.log` (no run log produced)
- `development/RME/ARTIFACTS/evidence/gate-2/runtime/screenshots-individual/CARAVAN.iter01.bmp` (no screenshot)

---

**Suggested next steps:**
1. Run the game executable directly with explicit `F1R_PATCHLOG_PATH` to force writing to a known location and capture stdout/stderr:
```
cd "$(pwd)/build-macos/RelWithDebInfo/Fallout 1 Rebirth.app/Contents/Resources" && \
F1R_AUTORUN_MAP=CARAVAN F1R_AUTOSCREENSHOT=1 F1R_PATCHLOG=1 \
F1R_PATCHLOG_PATH="$(pwd)/development/RME/ARTIFACTS/evidence/gate-2/runtime/patchlogs/CARAVAN.iter01.patchlog.txt" \
  "$PWD/../../MacOS/fallout1-rebirth" > run.local.log 2>&1
```
2. If the process still exits or hangs, run under LLDB to obtain a backtrace and inspect missing assets referenced at startup.

---

File created: `development/RME/ARTIFACTS/evidence/gate-2/gate-2-caravan-rerun-summary.md`
