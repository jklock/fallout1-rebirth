# os/macos/

macOS application bundle resources.

Last updated: 2026-02-14

## Contents

| File | Description |
|------|-------------|
| `Info.plist` | macOS app configuration (bundle ID, version, entitlements) |
| `fallout1-rebirth.icns` | Application icon in Apple ICNS format |

## Info.plist

Key configuration entries:

- Bundle identifier and display name
- Version strings (CFBundleVersion, CFBundleShortVersionString)
- Minimum macOS deployment target
- High-resolution display support
- Copyright information

## fallout1-rebirth.icns

Multi-resolution icon file containing sizes from 16x16 to 1024x1024 pixels. Used for:

- Dock icon
- Finder display
- Application Switcher

## Build Integration

These resources are bundled into the macOS .app via CMake. The Info.plist is processed and the icon is set via `MACOSX_BUNDLE_ICON_FILE`.

## Code Signing and Notarization

For public distribution, the app must be signed with a Developer ID certificate and notarized by Apple. This is a manual process:

1. Sign the app with Developer ID certificate:
   ```bash
   codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" "Fallout 1 Rebirth.app"
   ```

2. Create DMG and submit for notarization:
   ```bash
   xcrun notarytool submit fallout1-rebirth.dmg --keychain-profile "notarytool-profile" --wait
   ```

3. Staple notarization ticket:
   ```bash
   xcrun stapler staple "Fallout 1 Rebirth.app"
   ```

Alternatively, distribute unsigned builds with instructions for users to remove the quarantine flag using `xattr -cr`.

---

## Proof of Work

**Last Verified**: 2026-02-07

**Files read to verify content**:
- os/macos/Info.plist (confirmed exists)
- os/macos/fallout1-rebirth.icns (confirmed exists)

**Updates made**: Refreshed verification date.
