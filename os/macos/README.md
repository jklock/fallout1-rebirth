# os/macos/

macOS application bundle resources.

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

## Notarization

For distribution, the app must be signed and notarized. CI handles this using repository secrets for:
- Developer ID certificate
- Apple notarization credentials
