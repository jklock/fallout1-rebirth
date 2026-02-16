# iOS/iPadOS Physical Device Deploy + Log Collection (Xcode + CLI)

Date: 2026-02-16
Scope: Deploy Fallout 1 Rebirth to a real iPad from this repo, stage game files, run it, and pull logs for debugging.

## Why deployment was getting stuck
The repo’s canonical iOS build script configures device builds with signing disabled:
- `scripts/build/build-ios.sh:241` sets `CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO`.

That is fine for artifact generation, but it blocks normal install/run on a physical iPad unless signing is re-enabled in Xcode or overridden in `xcodebuild`.

## Preconditions (must be true)
1. Xcode installed and opened at least once.
2. Apple Developer account added in Xcode (`Xcode > Settings > Accounts`).
3. iPad connected, trusted, and visible in Xcode.
4. Developer Mode enabled on iPad (required for development workflows).
5. Project game data available locally at a patched data root containing:
   - `master.dat`
   - `critter.dat`
   - `data/`

## Workflow A (recommended when UI is acceptable): Xcode UI deploy

### A1) Generate the iOS project (repo-standard)
```bash
cd /Volumes/Storage/GitHub/fallout1-rebirth
./scripts/build/build-ios.sh -prod --device
```

### A2) Open Xcode project
Open:
- `build-ios/fallout1-rebirth.xcodeproj`

Select target:
- `fallout1-rebirth`

### A3) Fix signing settings for physical device
In target build/signing settings:
1. Set Team to your Apple Developer team.
2. Use Automatic signing.
3. Ensure signing is enabled (`Code Signing Allowed = YES`, `Code Signing Required = YES`).
4. If needed, use a unique bundle identifier (for personal/free team workflows).

### A4) Run on iPad
1. Choose your iPad as Run destination.
2. Build + Run.
3. If prompted on device, trust/allow the developer app and continue.

## Workflow B (automation-friendly): signed CLI deploy + container file ops

This path avoids Xcode UI friction and is easier for scripted repetition. Use the included automation script `scripts/test/test-ios-device.sh` as a one-step implementation of this flow.

### B1) Prepare variables
```bash
cd /Volumes/Storage/GitHub/fallout1-rebirth

DEVICE_NAME="Dadpad"                 # or use device UUID/UDID
TEAM_ID="YOUR_TEAM_ID"
BUNDLE_ID="com.fallout1rebirth.game" # adjust if you changed it
GAME_DATA="/ABS/PATH/TO/patchedfiles"
APP_PATH="build-ios/RelWithDebInfo-iphoneos/fallout1-rebirth.app"
```

List connected devices:
```bash
xcrun devicectl list devices
```

### B2) Ensure base iOS project exists
```bash
./scripts/build/build-ios.sh -prod --device
```

### B3) Build signed app for the connected iPad
```bash
xcodebuild \
  -project build-ios/fallout1-rebirth.xcodeproj \
  -scheme fallout1-rebirth \
  -configuration RelWithDebInfo \
  -destination "name=${DEVICE_NAME}" \
  DEVELOPMENT_TEAM="${TEAM_ID}" \
  PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}" \
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  build
```

### B4) Install app to the iPad
```bash
xcrun devicectl device install app --device "${DEVICE_NAME}" "${APP_PATH}"
```

Verify install:
```bash
xcrun devicectl device info apps --device "${DEVICE_NAME}" --bundle-id "${BUNDLE_ID}"
```

### B5) Copy game files into app container (Documents)
The project expects iOS data in app container `Documents` (see `docs/upgrading.md`).

Copy DAT files:
```bash
xcrun devicectl device copy to \
  --device "${DEVICE_NAME}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --destination Documents \
  --source "${GAME_DATA}/master.dat" \
  --source "${GAME_DATA}/critter.dat"
```

Copy `data/` tree:
```bash
xcrun devicectl device copy to \
  --device "${DEVICE_NAME}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --destination Documents \
  --source "${GAME_DATA}/data"
```

Optional config copy:
```bash
[ -f "${GAME_DATA}/fallout.cfg" ] && xcrun devicectl device copy to \
  --device "${DEVICE_NAME}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --destination Documents \
  --source "${GAME_DATA}/fallout.cfg"

[ -f "${GAME_DATA}/f1_res.ini" ] && xcrun devicectl device copy to \
  --device "${DEVICE_NAME}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --destination Documents \
  --source "${GAME_DATA}/f1_res.ini"
```

Verify files present:
```bash
xcrun devicectl device info files \
  --device "${DEVICE_NAME}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --subdirectory Documents
```

### B6) Launch app with runtime logging env
This app supports patchlog env variables. `devicectl` supports passing child env vars via `DEVICECTL_CHILD_` prefix.

```bash
mkdir -p dev/state/logs

DEVICECTL_CHILD_F1R_PATCHLOG=1 \
DEVICECTL_CHILD_F1R_PATCHLOG_PATH=Documents/input-device.patchlog.txt \
xcrun devicectl device process launch \
  --device "${DEVICE_NAME}" \
  --terminate-existing \
  "${BUNDLE_ID}"
```

If you want foreground console attach (blocking command):
```bash
DEVICECTL_CHILD_F1R_PATCHLOG=1 \
DEVICECTL_CHILD_F1R_PATCHLOG_PATH=Documents/input-device.patchlog.txt \
xcrun devicectl device process launch \
  --device "${DEVICE_NAME}" \
  --terminate-existing \
  --console \
  "${BUNDLE_ID}"
```

### B7) Pull logs/artifacts back to repo
After reproducing on iPad:

```bash
xcrun devicectl device copy from \
  --device "${DEVICE_NAME}" \
  --domain-type appDataContainer \
  --domain-identifier "${BUNDLE_ID}" \
  --source Documents/input-device.patchlog.txt \
  --destination "$(pwd)/dev/state/logs"
```

Check crash logs present on device:
```bash
xcrun devicectl device info files \
  --device "${DEVICE_NAME}" \
  --domain-type systemCrashLogs
```

Copy specific crash log(s) you find from listing:
```bash
xcrun devicectl device copy from \
  --device "${DEVICE_NAME}" \
  --domain-type systemCrashLogs \
  --source "<CRASH_LOG_PATH_FROM_LISTING>" \
  --destination "$(pwd)/dev/state/logs"
```

## Fast troubleshooting checklist

### App does not install
- Confirm iPad is visible as connected in `xcrun devicectl list devices`.
- Confirm signed build was produced with `CODE_SIGNING_ALLOWED=YES` and valid team.
- Re-run build with `-allowProvisioningUpdates -allowProvisioningDeviceRegistration`.

### Build succeeds, launch fails immediately
- Verify Developer Mode is enabled on iPad.
- Verify app is trusted on device (developer app trust flow).
- Pull crash logs from `systemCrashLogs` domain.

### App launches but says missing `master.dat`/`critter.dat`
- Verify files are in app container `Documents`.
- Re-check with `devicectl device info files --domain-type appDataContainer ... --subdirectory Documents`.
- Confirm `data/` copied as directory, not flattened.

### Need manual fallback for file transfer
Use Finder device File Sharing for the app container as documented in:
- `docs/upgrading.md:94`

## Sources (online research)
- Apple Xcode Help: Run your app in the Simulator or on a device
  - https://help.apple.com/xcode/mac/current/#/deva8aa1fdf5
- Apple Xcode Help: Prepare your app to run in the Simulator or on a device
  - https://help.apple.com/xcode/mac/current/#/dev5a825a1ca
- Apple Xcode Help: Connect a device to your Mac
  - https://help.apple.com/xcode/mac/current/#/devda3d905f4
- Apple Xcode Help: Pair a wireless device with Xcode
  - https://help.apple.com/xcode/mac/current/#/devac3261a70
- Apple Xcode Help: Add your Apple Account in Xcode
  - https://help.apple.com/xcode/mac/current/#/dev0cbc9d4cb
- Apple Developer Documentation: Diagnose crashes and low-memory terminations
  - https://developer.apple.com/documentation/xcode/diagnosing-issues-in-your-app-related-to-crashes-and-low-memory-terminations
- Apple Technical Note TN2339 (xcodebuild usage)
  - https://developer.apple.com/library/archive/technotes/tn2339/_index.html

## Local authoritative command references used
- `xcrun devicectl -h`
- `xcrun devicectl help device install app`
- `xcrun devicectl help device copy to`
- `xcrun devicectl help device copy from`
- `xcrun devicectl help device process launch`
- `xcodebuild -help`
