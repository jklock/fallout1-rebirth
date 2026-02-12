# TODO: Release

> Final release packaging and sign-off for RME 1.1e integration.

## Status Key

- `[ ]` Not started
- `[~]` In progress
- `[x]` Complete
- `[!]` Blocked

---

## R-1: macOS DMG Build

```bash
cd /Volumes/Storage/GitHub/fallout1-rebirth
./scripts/build/build-macos.sh
cd build-macos && cpack -C RelWithDebInfo
cd ..
```

**Verify:**

```bash
ls build-macos/*.dmg
```

- [ ] DMG file exists and is non-zero size

---

## R-2: DMG Smoke Test

```bash
# Mount DMG
hdiutil attach build-macos/*.dmg
DMG_MOUNT=$(ls -d /Volumes/Fallout* | head -1)

# Copy app to temp
cp -R "$DMG_MOUNT/Fallout 1 Rebirth.app" /tmp/

# Install game data
RES="/tmp/Fallout 1 Rebirth.app/Contents/Resources"
cp GOG/patchedfiles/master.dat "$RES/"
cp GOG/patchedfiles/critter.dat "$RES/"
cp -R GOG/patchedfiles/data/ "$RES/data/"
cp GOG/patchedfiles/fallout.cfg "$RES/"
cp GOG/patchedfiles/f1_res.ini "$RES/"

# Launch and verify main menu loads
open "/tmp/Fallout 1 Rebirth.app"
# Manually verify: main menu → new game → Vault 13

# Cleanup
rm -rf "/tmp/Fallout 1 Rebirth.app"
hdiutil detach "$DMG_MOUNT"
```

- [ ] DMG mounts successfully
- [ ] App copies to /tmp without error
- [ ] Game data installs to Resources/
- [ ] App launches from DMG copy
- [ ] Main menu renders
- [ ] New Game → Vault 13 loads

---

## R-3: iOS IPA Build

```bash
cd build-ios && cpack -C RelWithDebInfo && cd ..
```

**Verify:**

```bash
ls build-ios/*.ipa
```

- [ ] IPA file exists and is non-zero size

---

## R-4: Pre-Release Checklist

All gates must pass before release:

- [ ] Gate 1 (static validation) PASSED
- [ ] Gate 2 (runtime map sweep) PASSED
- [ ] Gate 3 (macOS gameplay) PASSED
- [ ] Gate 4 (iOS testing) PASSED
- [ ] macOS DMG builds and launches with patched data
- [ ] iOS IPA builds successfully
- [ ] All evidence committed to `development/RME/ARTIFACTS/`
- [ ] `OUTCOME.md` sign-off complete
- [ ] No uncommitted code changes: `./scripts/dev/dev-check.sh`
- [ ] No formatting issues: `./scripts/dev/dev-format.sh`

---

## R-5: Create GitHub Release (Manual)

```bash
# Tag the release
git tag -a v1.0.0-rme -m "RME 1.1e integration validated"

# Upload artifacts to GitHub Releases:
# - build-macos/*.dmg
# - build-ios/*.ipa
# - Include release notes referencing the 22 bundled mods
```

### Release Notes Template

```
## Fallout 1 Rebirth v1.0.0-rme

RME 1.1e (Restoration Mod Extended) integration — validated and packaged.

### What's Included
- 22 community mods bundled via RME 1.1e
- TeamX Patch 1.3.5 compatibility
- FO2-style fonts
- Apple-only: macOS (Intel & Apple Silicon) + iOS/iPadOS

### Artifacts
- **macOS**: Fallout 1 Rebirth.dmg
- **iOS/iPadOS**: fallout1-rebirth.ipa

### Requirements
- Original Fallout 1 game data files (master.dat, critter.dat)
- macOS 12+ or iOS/iPadOS 16+

### Engine Fixes
- Survivalist perk fix
- VSync enabled by default
- Touch coordinate fixes for iPad
- Case-insensitive file lookups

See docs/ for setup instructions.
```

- [ ] Git tag created
- [ ] DMG uploaded to GitHub Release
- [ ] IPA uploaded to GitHub Release
- [ ] Release notes published
