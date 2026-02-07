# dist/

Distribution files and default configurations.

Last updated: 2026-02-07

Contains platform-specific files that are bundled with the distributed application.

## Structure

| Directory | Description |
|-----------|-------------|
| [ios/](ios/) | iOS/iPadOS distribution files |
| [macos/](macos/) | macOS distribution files |

## Common Files

Both platforms include:

| File | Description |
|------|-------------|
| `README.txt` | End-user instructions |
| `fallout.cfg` | Default game configuration |
| `f1_res.ini` | Resolution and display settings |

## fallout.cfg

Default configuration file with settings for:
- Data file paths (master.dat, critter.dat)
- Audio preferences
- Game options

## f1_res.ini

High-resolution patch configuration:
- Screen resolution
- Scaling mode
- Display options

## Build Integration

These files are copied into the application bundle during packaging. On iOS, they go into the app bundle's Resources. On macOS, they are placed in Contents/Resources.

## User Configuration

At runtime, the game reads configuration relative to the working directory:
- macOS: typically the app bundle (Contents/MacOS or Contents/Resources)
- iOS: the app's Documents container

The bundled defaults are used when user configs don't exist in those locations.
