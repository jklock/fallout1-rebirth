<p align="center">
  <img src="img/RebirthLogo.png" alt="Fallout 1 Rebirth" width="512">
</p>

# Fallout 1 Rebirth

**Apple-Only Fork** — This project exclusively targets **macOS** and **iOS/iPadOS**.

Fallout 1 Rebirth is a fully working re-implementation of Fallout, with the same original gameplay, engine bugfixes, and quality of life improvements, optimized for Apple platforms.

> For Windows, Linux, or Android support, use the upstream project: [alexbatalov/fallout1-ce](https://github.com/alexbatalov/fallout1-ce)

I did this because I love Fallout. Fallout 1 was the first computer game I ever bought. I got it at Target for $10 when I was a kid. It was the first game I ever installed on MY computer and the first computer game I really fell in love with.

## Features

### Core Features
- **Native Apple Silicon support** — Runs natively on M1/M2/M3/M4 Macs and all modern iPads
- **Engine bug fixes** — Survivalist perk fix, combat improvements, and script corrections
- **High-DPI Retina support** — Sharp rendering with 2X integer scaling option

### Cherry-Picked Community Improvements
- **iPad mouse/trackpad + F-key support** (evaera)
- **Touch control optimization** (zverinapavel)
- **Borderless window mode** (radozd)
- **QoL features + bugfixes** (korri123)
- **TeamX Patch 1.3.5 compatibility**
- **RME 1.1e data integration**

### Input Support
| Input Method | macOS | iPad |
|--------------|-------|------|
| Mouse | ✅ Full | ✅ Magic Keyboard/Trackpad |
| Keyboard | ✅ Full | ✅ External keyboards |
| Touch | — | ✅ Gesture-based (see below) |
| Apple Pencil | — | ✅ Full support (see below) |

## Installation

You must own the game to play. Purchase your copy on [GOG](https://www.gog.com/game/fallout) or [Steam](https://store.steampowered.com/app/38400). Download the latest release or build from source.

### macOS

> **Requirements**: macOS 11.0 (Big Sur) or higher. Runs natively on Intel-based Macs and Apple Silicon.

1. **Get game data** — Search archive.org for "Fallout 1 GOG Linux" and download the Linux installer. Extract and lowercase the files:
   ```bash
   # Extract the Linux installer (no special tools needed)
   unzip fallout_classic_linux_*.zip -d ~/Games/Fallout
   cd ~/Games/Fallout
   
   # Lowercase all filenames (required for macOS/iOS)
   find . -depth -exec rename 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
   # Or if you don't have 'rename', use this:
   find . -depth -name '*[A-Z]*' -execdir bash -c 'mv "$1" "${1,,}"' _ {} \;
   ```

2. **Download** `Fallout 1 Rebirth.dmg` from Releases and copy the app to your Fallout folder.

3. **Run** `Fallout 1 Rebirth.app`.

### iOS/iPadOS

> **Primary target**: iPad is the main platform for this fork. **Landscape orientation only** — the game locks to landscape mode for optimal gameplay.

**Touch Controls:**
| Gesture | Action |
|---------|--------|
| Single tap | Move cursor + left-click |
| One finger drag | Move cursor |
| Two-finger tap | Right-click (switch cursor mode) |
| Two fingers drag | Scroll views |
| Three-finger tap | Left-click without moving cursor |

**Apple Pencil Controls:**
| Gesture | Action |
|---------|--------|
| Tap near cursor | Left-click |
| Tap away from cursor | Move cursor only (no click) |
| Long-press | Right-click (examine/context menu) |
| Pencil body double-tap | Right-click (2nd gen+ pencils) |
| Squeeze | Right-click (Apple Pencil Pro only) |
| Drag from cursor | Click + drag |
| Drag from away | Move cursor (no button) |

Apple Pencil uses absolute positioning — the cursor follows exactly where you touch. The "click radius" concept separates positioning from clicking, just like a mouse.

**With Magic Keyboard/Trackpad:** Full mouse and keyboard support including F-keys.

**Installation:**
1. Download `fallout1-rebirth.ipa` from Releases
2. Sideload using [AltStore](https://altstore.io/) or [Sideloadly](https://sideloadly.io/)
3. Run the game once (you'll see a "Could not find the master datafile..." error — this is expected)
4. Use Finder or iTunes to copy `master.dat`, `critter.dat`, and `data` folder to the app ([how-to](https://support.apple.com/HT210598))

## Configuration

The game uses two configuration files:

### fallout.cfg — Game Settings

Controls game logic, data paths, sound, and preferences.

```ini
[system]
master_dat=master.dat        # Main game data archive
master_patches=data          # Override folder for master.dat
critter_dat=critter.dat      # Critter/NPC data archive
critter_patches=data         # Override folder for critter.dat

[sound]
music_path1=data/sound/music/  # Path to music files (case-sensitive!)

[preferences]
combat_speed=0               # 0-5 (0=normal, 5=fastest)
game_difficulty=1            # 0=easy, 1=normal, 2=hard
```

> **Important**: File paths are case-sensitive! If your game data uses `MASTER.DAT` instead of `master.dat`, update the config accordingly.

### f1_res.ini — Display Settings

Controls resolution, scaling, and window mode.

```ini
[MAIN]
SCR_WIDTH=1024     # Screen width in pixels
SCR_HEIGHT=768     # Screen height in pixels
WINDOWED=0         # 0=fullscreen, 1=windowed
SCALE_2X=1         # 0=native, 1=2x integer scaling
```

### Platform-Specific Recommendations

| Platform | Resolution | WINDOWED | SCALE_2X | Notes |
|----------|------------|----------|----------|-------|
| **macOS** | 1920x1080 | 1 | 0 | Any resolution works; windowed recommended |
| **iPad Pro 13"** | 1024x768 | 0 | 1 | Use logical resolution, not pixel resolution |
| **iPad Pro 11"** | 1024x768 | 0 | 1 | Logical res is 834x1194 (portrait) |
| **iPad Air** | 1024x768 | 0 | 1 | Standard 4:3 ratio works well |

> **iPad resolution note**: iPads report logical points, not pixels. iPad Pro 11" is 1668x2388 pixels but 834x1194 logical points. Use `1024x768` with `SCALE_2X=1` for optimal display.

## Building from Source

### Requirements
- Xcode 15+ with Command Line Tools
- CMake 3.21+

### Game Data for Development

When developing or testing locally, place your game files in `GOG/Fallout1/` in the repository root:

```
fallout1-rebirth/
├── GOG/
│   └── Fallout1/           # Create this folder
│       ├── master.dat      # ~300 MB - Required
│       ├── critter.dat     # ~25 MB  - Required
│       └── data/           # Override folder
│           └── sound/
│               └── music/  # Music files
└── src/
    └── ...
```

The `GOG/` folder is gitignored — game files are never committed to the repository.

**Getting game files:**
```bash
# Search archive.org for "Fallout 1 GOG Linux" and download the Linux installer
# Extract and lowercase:
unzip fallout_classic_linux_*.zip -d GOG/Fallout1
cd GOG/Fallout1

# Lowercase all filenames (required for macOS/iOS)
find . -depth -exec rename 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
# Or if you don't have 'rename':
find . -depth -name '*[A-Z]*' -execdir bash -c 'mv "$1" "${1,,}"' _ {} \;
```

The test scripts automatically copy these files to the appropriate locations:
- **iOS Simulator**: Copies to app's Documents container
- **macOS**: The app reads from its bundle Resources folder

### macOS (Xcode)

```bash
cmake -B build-macos -G Xcode -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-macos --config RelWithDebInfo -j $(sysctl -n hw.physicalcpu)
```

### macOS (Makefiles — faster iteration)

```bash
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j $(sysctl -n hw.physicalcpu)
./build/fallout1-rebirth
```

### iOS/iPadOS (Device)

```bash
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=OS64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-ios --config RelWithDebInfo -j $(sysctl -n hw.physicalcpu)
```

### iOS Simulator Testing

```bash
./scripts/test-ios-simulator.sh              # Full flow: build + install + launch
./scripts/test-ios-simulator.sh --build-only # Just build
./scripts/test-ios-simulator.sh --shutdown   # Shutdown all simulators
```

### Packaging

```bash
cd build-macos && cpack -C RelWithDebInfo  # Creates .dmg
cd build-ios && cpack -C RelWithDebInfo    # Creates .ipa
```

## Documentation

Comprehensive documentation is available in the [docs/](docs/) directory:

- [Setup Guide](docs/setup_guide.md) — Complete installation instructions
- [Building](docs/building.md) — Build from source instructions
- [Architecture](docs/architecture.md) — Codebase structure and how it works
- [Testing](docs/testing.md) — Running tests and validation
- [Scripts](docs/scripts.md) — Available automation scripts
- [Contributing](docs/contributing.md) — How to contribute

## Contributing

This is an Apple-focused fork. Contributions related to macOS and iOS/iPadOS are welcome!

See [docs/contributing.md](docs/contributing.md) for detailed contribution guidelines.

Current goals:
- **Engine bug fixes** — Port fixes from ETTU/Fo1in2 analysis
- **iPad optimization** — Improve touch controls and UI scaling
- **Quality of life** — Backport relevant Fallout 2 improvements

## Credits

- **Original game**: Interplay/Black Isle Studios
- **Community Edition**: [alexbatalov](https://github.com/alexbatalov/fallout1-ce)
- **Fork contributors**: evaera, zverinapavel, radozd, korri123
- **Mods**: TeamX, Wasteland Ghost, Sduibek, and many others

## License

The source code in this repository is available under the [Sustainable Use License](LICENSE.md).
