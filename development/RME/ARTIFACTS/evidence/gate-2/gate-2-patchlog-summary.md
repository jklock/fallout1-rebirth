# Gate 2 — Patchlog Summary

**Date:** 2026-02-10 22:19:49Z

**Maps scanned:** 72
**Total missing-resource reports (reason=missing / DB_OPEN_FAIL):** 1327

## Top missing items (normalized)
[DB_OPEN_FAIL] source=datafile reason=missing request="font9.fon" path=".\FONT9.FON" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font9.aaf" path=".\FONT9.AAF" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font8.fon" path=".\FONT8.FON" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font8.aaf" path=".\FONT8.AAF" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font7.fon" path=".\FONT7.FON" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font7.aaf" path=".\FONT7.AAF" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font6.fon" path=".\FONT6.FON" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font6.aaf" path=".\FONT6.AAF" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font5.aaf" path=".\FONT5.AAF" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font4.fon" path=".\FONT4.FON" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font15.aaf" path=".\FONT15.AAF" mode="rb"
[DB_OPEN_FAIL] source=datafile reason=missing request="font14.aaf" path=".\FONT14.AAF" mode="rb"

## Recommended Triage

- Fonts: add missing .fon/.aaf to data/ packaging (create TODO.fonts.md)
- Splash art: restore ART\SPLASH\SPLASH*.RIX (TODO.art.md)
- Maps: re-add missing .GAM/.SAV if accidental (TODO.maps.md)
