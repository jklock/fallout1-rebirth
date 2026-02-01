# dist/macos/

macOS distribution files bundled with the application.

## Contents

| File | Description |
|------|-------------|
| `README.txt` | End-user installation and usage instructions |
| `fallout.cfg` | Default game configuration |
| `f1_res.ini` | High-resolution patch settings |

## README.txt

Plain-text instructions for end users covering:
- Required game data files (master.dat, critter.dat, data/)
- Installation steps
- Gatekeeper workarounds for unsigned builds
- Basic controls
- Configuration options

## fallout.cfg

Game configuration file specifying:
- Data file paths
- Audio settings
- Gameplay preferences

## f1_res.ini

Display configuration including:
- Screen resolution (SCR_WIDTH, SCR_HEIGHT)
- Windowed/fullscreen mode
- Scaling options

## Build Integration

These files are copied into the macOS .app bundle at `Contents/Resources/` during the CPack packaging step. The main `CMakeLists.txt` configures this via the `RESOURCE` target property.

## See Also

- [dist/README.md](../README.md) - Distribution overview
- [dist/ios/](../ios/) - iOS distribution files
- [os/macos/](../../os/macos/) - macOS app bundle resources
