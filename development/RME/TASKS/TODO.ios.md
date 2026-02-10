# TODO: iOS Testing

> iPad is the PRIMARY use case. Zero iOS runtime testing has been done.
> All tasks below must be completed before Gate 4 sign-off.

## Status Key

- `[ ]` Not started
- `[~]` In progress
- `[x]` Complete
- `[!]` Blocked

---

## IO-1: Build iOS IPA

```bash
cd /Volumes/Storage/GitHub/fallout1-rebirth
./scripts/build/build-ios.sh
cd build-ios && cpack -C RelWithDebInfo
cd ..
```

**Verify:**

```bash
ls build-ios/fallout1-rebirth.ipa
```

- [ ] IPA file exists and is non-zero size

---

## IO-2: Patch Data for iOS

```bash
rm -rf GOG/patchedfiles-ios
./scripts/patch/rebirth-patch-ipa.sh \
  --base GOG/unpatchedfiles \
  --out GOG/patchedfiles-ios \
  --force
```

**Verify:**

```bash
ls GOG/patchedfiles-ios/fallout.cfg GOG/patchedfiles-ios/f1_res.ini
```

- [ ] `fallout.cfg` exists with iOS-correct paths
- [ ] `f1_res.ini` exists with iPad resolution settings

---

## IO-3: iOS Simulator Setup

```bash
# Shutdown all running simulators first
./scripts/test/test-ios-simulator.sh --shutdown

# List available iPad sims
./scripts/test/test-ios-simulator.sh --list

# Build for simulator and launch
./scripts/test/test-ios-simulator.sh
```

**CRITICAL:** One simulator at a time only! Multiple sims cause memory pressure.

- Default target: `iPad Pro 13-inch (M4)` (override via `SIMULATOR_NAME` env var)
- [ ] Simulator boots cleanly
- [ ] App installs to simulator
- [ ] App launches without immediate crash

---

## IO-4: Install Game Data to Simulator

```bash
# Find the simulator app data path
BUNDLE_ID=$(grep -A1 'CFBundleIdentifier' os/ios/Info.plist | grep string | sed 's/.*<string>\(.*\)<\/string>/\1/')
DATA_PATH=$(xcrun simctl get_app_container booted "$BUNDLE_ID" data)/Documents

# Copy patched data
cp GOG/patchedfiles-ios/master.dat "$DATA_PATH/"
cp GOG/patchedfiles-ios/critter.dat "$DATA_PATH/"
cp -R GOG/patchedfiles-ios/data/ "$DATA_PATH/data/"
cp GOG/patchedfiles-ios/fallout.cfg "$DATA_PATH/"
cp GOG/patchedfiles-ios/f1_res.ini "$DATA_PATH/"

# Verify
ls -la "$DATA_PATH/master.dat" "$DATA_PATH/critter.dat"
```

> **Note:** If `get_app_container` fails, the app may need to be launched first to create its container. Launch the app once, let it fail (no data), then retry the copy.

- [ ] `master.dat` copied to Documents
- [ ] `critter.dat` copied to Documents
- [ ] `data/` directory copied to Documents
- [ ] Config files copied to Documents

---

## IO-5: iOS Smoke Test

- [ ] App launches without crash on iPad Simulator
- [ ] Main menu renders correctly
- [ ] Fonts display correctly (FO2 fonts from RME)
- [ ] Start "New Game"
- [ ] Character creation screen works
- [ ] Vault 13 loads and renders

---

## IO-6: iOS Touch Controls

- [ ] Tap to move character — character walks to tapped location
- [ ] Tap on NPC — interaction menu appears
- [ ] Tap on door — door interaction works
- [ ] Double-tap or long-press behaviors work correctly
- [ ] Edge scrolling/pan works

Relevant source: `src/plib/gnw/touch.cc`, `src/plib/gnw/touch.h`

---

## IO-7: iOS Dialog Test

- [ ] Talk to Overseer in Vault 13
- [ ] Dialog text renders correctly (touch to select options)
- [ ] Complete a full dialog tree

---

## IO-8: iOS Map Transition

- [ ] Navigate to Vault 13 cave exit
- [ ] Transition to world map
- [ ] Select a destination
- [ ] Destination loads correctly

---

## IO-9: iOS Case Sensitivity Verification

iOS uses case-sensitive APFS by default. This is critical for file lookups.

```bash
# Verify ALL files in patched iOS data are lowercase
find GOG/patchedfiles-ios/data/ -name '*[A-Z]*' | wc -l
# MUST be 0
```

- [ ] Zero uppercase filenames in patched iOS data

If non-zero, the patch script's case normalization failed for iOS. Remediation: re-run with `--force` and check for normalization errors.

---

## IO-10: iOS Config Verification

```bash
# Verify iOS-specific config settings
cat GOG/patchedfiles-ios/f1_res.ini
# Should show correct iPad resolution, SCALE_2X=1, CLICK_OFFSET values

cat GOG/patchedfiles-ios/fallout.cfg
# Should show correct paths for iOS Documents directory structure
```

- [ ] `f1_res.ini` has correct iPad resolution
- [ ] `f1_res.ini` has `SCALE_2X=1`
- [ ] `f1_res.ini` has correct `CLICK_OFFSET` values
- [ ] `fallout.cfg` has correct iOS `Documents/` path structure

---

## IO-11: iOS Cleanup

```bash
./scripts/test/test-ios-simulator.sh --shutdown
```

- [ ] All simulators shut down

---

## Remediation Guide

### iOS build fails

1. Check toolchain file exists: `cmake/toolchain/ios.toolchain.cmake`
2. Verify Xcode and Command Line Tools installed: `xcode-select -p`
3. Check signing identity is empty string (ad-hoc): `CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''`
4. Try clean build: `rm -rf build-ios && ./scripts/build/build-ios.sh`

### Touch controls don't work

1. Check `src/plib/gnw/touch.cc` — touch event handling
2. Verify `f1_res.ini` has correct `CLICK_OFFSET` values for iPad resolution
3. Check SDL touch event forwarding in `src/plib/gnw/svga.cc`

### Case-sensitive filesystem causes missing files

1. Re-run patch with `--force` flag
2. Manually check: `find GOG/patchedfiles-ios/ -name '*[A-Z]*'`
3. If files remain uppercase, manually lowercase them:
   ```bash
   find GOG/patchedfiles-ios/data/ -name '*[A-Z]*' | while read f; do
     dir=$(dirname "$f")
     base=$(basename "$f" | tr '[:upper:]' '[:lower:]')
     mv "$f" "$dir/$base"
   done
   ```

### App crashes on launch

1. Check Console.app for crash logs (filter by app name)
2. Check that all required `.dat` files are in the Documents container
3. Verify `fallout.cfg` paths match the actual container structure
4. Try launching with `DYLD_PRINT_LIBRARIES=1` to check for missing dylibs

### Simulator won't boot

1. `./scripts/test/test-ios-simulator.sh --shutdown` first
2. Check available simulators: `xcrun simctl list devices available`
3. Try different iPad: `SIMULATOR_NAME="iPad Air 13-inch (M2)" ./scripts/test/test-ios-simulator.sh`
4. Delete and recreate runtime: `xcrun simctl delete all` (nuclear option)
