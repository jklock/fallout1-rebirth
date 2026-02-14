# Game Configuration Templates

**Last Updated:** 2026-02-14

## Purpose

Platform-specific configuration file templates for Fallout 1 Rebirth. These files are used during app packaging and provide optimized default settings for each platform.

## Contents

| Directory | Platform | Description |
|-----------|----------|-------------|
| `ios/` | iOS/iPadOS | Touch-optimized settings for mobile devices |
| `macos/` | macOS | Desktop-optimized settings for Mac |

### Configuration Files

| File | Purpose |
|------|---------|
| `f1_res.ini` | High-resolution patch settings (screen scaling, graphics options) |
| `fallout.cfg` | Core game configuration (paths, sound, preferences) |
| `fallout.ini` | Additional game settings (iOS only) |

## Platform Differences

### iOS/iPadOS
- Touch input enabled
- Virtual keyboard support
- Optimized for Retina displays
- Home indicator handling

### macOS
- Mouse/keyboard input
- Borderless window mode available
- VSync enabled by default

## Usage

These templates are automatically bundled with the app during the build process (CPack). Users can modify settings in the app's data container after installation.

## See Also

- [Configuration Guide](../docs/configuration.md)
- [Building Guide](../docs/building.md)
