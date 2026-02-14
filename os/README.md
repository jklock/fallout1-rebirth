# os/

Operating system integration files for app packaging.

Last updated: 2026-02-14

Contains platform-specific resources required for building distributable applications.

## Structure

| Directory | Description |
|-----------|-------------|
| [ios/](ios/) | iOS/iPadOS app bundle resources |
| [macos/](macos/) | macOS app bundle resources |

## Usage

These files are referenced by CMakeLists.txt during the build process and are copied into the final application bundles.

## Distinction from src/platform/

- `os/` contains packaging resources (icons, plists, storyboards)
- `src/platform/` contains compiled source code for platform-specific functionality

---

## Proof of Work

**Last Verified**: 2026-02-07

**Files read to verify content**:
- os/ios/ (Info.plist, LaunchScreen.storyboard, AppIcon.xcassets/ confirmed)
- os/macos/ (Info.plist, fallout1-rebirth.icns confirmed)
- src/platform/ (directory confirmed to exist)

**Updates made**: Refreshed verification date.
