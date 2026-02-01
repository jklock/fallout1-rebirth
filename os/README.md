# os/

Operating system integration files for app packaging.

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
