# dist/ios/

iOS and iPadOS distribution files bundled with the application.

## Contents

| File | Description |
|------|-------------|
| `README.txt` | End-user installation and usage instructions |
| `fallout.cfg` | Default game configuration |
| `f1_res.ini` | High-resolution patch settings |

## README.txt

Plain-text instructions for end users covering:
- Sideloading methods (AltStore, Sideloadly, Xcode)
- Game data file installation via Finder
- Touch control gestures
- Keyboard and trackpad support on iPad
- Troubleshooting steps

## fallout.cfg

Game configuration file specifying:
- Data file paths
- Audio settings
- Gameplay preferences

## f1_res.ini

Display configuration including:
- Screen resolution settings
- Scaling options

## Build Integration

These files are copied into the iOS .app bundle at the root level during CPack packaging. At runtime, the app reads configuration from the user's Documents container, falling back to bundled defaults.

## iOS Data Installation

Users must transfer game data files to the app's data container:
1. Connect device to Mac
2. Open Finder and select the device
3. Navigate to the Files tab
4. Find the Fallout app
5. Drag master.dat, critter.dat, and data/ folder into the app

## See Also

- [dist/README.md](../README.md) - Distribution overview
- [dist/macos/](../macos/) - macOS distribution files
- [os/ios/](../../os/ios/) - iOS app bundle resources
