# Fallout Community Edition - Rebirth

**Apple-Only Fork** — This project exclusively targets **macOS** and **iOS/iPadOS**.

Fallout Community Edition Rebirth is a fully working re-implementation of Fallout, with the same original gameplay, engine bugfixes, and quality of life improvements, optimized for Apple platforms.

> For Windows, Linux, or Android support, use the upstream project: [alexbatalov/fallout1-ce](https://github.com/alexbatalov/fallout1-ce)

There is also [Fallout 2 Community Edition](https://github.com/alexbatalov/fallout2-ce).

## Features

This fork includes cherry-picked improvements:
- **iPad mouse/trackpad + F-key support** (evaera)
- **Touch control optimization** (zverinapavel)
- **Borderless window mode** (radozd)
- **QoL features + bugfixes** (korri123)
- **TeamX Patch 1.3.5 compatibility**
- **RME 1.1e data integration**

## Installation

You must own the game to play. Purchase your copy on [GOG](https://www.gog.com/game/fallout) or [Steam](https://store.steampowered.com/app/38400). Download latest [release](https://github.com/alexbatalov/fallout1-ce/releases) or build from source.

### macOS

> **NOTE**: macOS 11.0 (Big Sur) or higher is required. Runs natively on Intel-based Macs and Apple Silicon.

- Use Windows installation as a base - it contains data assets needed to play. Copy `Fallout` folder somewhere, for example `/Applications/Fallout`.

- Alternatively you can use Fallout from MacPlay/The Omni Group as a base - you need to extract game assets from the original bundle. Mount CD/DMG, right click `Fallout` -> `Show Package Contents`, navigate to `Contents/Resources`. Copy `GameData` folder somewhere, for example `/Applications/Fallout`.

- Or if you're a Terminal user and have Homebrew installed you can extract the needed files from the GoG installer:

```console
$ brew install innoextract
$ innoextract ~/Downloads/setup_fallout_2.1.0.18.exe -I app
$ mv app /Applications/Fallout
```

- Download and copy `fallout-ce.app` to this folder.

- Run `fallout-ce.app`.

### iOS/iPadOS

> **NOTE**: iPad is the primary target platform for this fork. Fallout was designed with mouse in mind. There are many controls that require precise cursor positioning. Current control scheme:

> - **Single tap**: Move cursor and left-click
> - **One finger drag**: Move cursor around
> - **Two-finger tap**: Right-click (switch cursor mode)
> - **Two fingers**: Scroll views
> - **Three-finger tap**: Left-click at cursor position without moving

> **iPad with Magic Keyboard/Trackpad**: Full mouse and keyboard support including F-keys.

- Download `fallout-ce.ipa`. Use sideloading applications ([AltStore](https://altstore.io/) or [Sideloadly](https://sideloadly.io/)) to install it to your device. Alternatively you can always build from source with your own signing certificate.

- Run the game once. You'll see error message saying "Could not find the master datafile...". This step is needed for iOS to expose the game via File Sharing feature.

- Use Finder (macOS Catalina and later) or iTunes (Windows and macOS Mojave or earlier) to copy `master.dat`, `critter.dat`, and `data` folder to "Fallout" app ([how-to](https://support.apple.com/HT210598)). Watch for file names - keep (or make) them lowercased (see [Configuration](#configuration)).

## Configuration

The main configuration file is `fallout.cfg`. There are several important settings you might need to adjust for your installation. Depending on your Fallout distribution main game assets `master.dat`, `critter.dat`, and `data` folder might be either all lowercased, or all uppercased. You can either update `master_dat`, `critter_dat`, `master_patches` and `critter_patches` settings to match your file names, or rename files to match entries in your `fallout.cfg`.

The `sound` folder (with `music` folder inside) might be located either in `data` folder, or be in the Fallout folder. Update `music_path1` setting to match your hierarchy, usually it's `data/sound/music/` or `sound/music/`. Make sure it match your path exactly (so it might be `SOUND/MUSIC/` if you've installed Fallout from CD). Music files themselves (with `ACM` extension) should be all uppercased, regardless of `sound` and `music` folders.

The second configuration file is `f1_res.ini`. Use it to change game window size and enable/disable fullscreen mode.

```ini
[MAIN]
SCR_WIDTH=1280
SCR_HEIGHT=720
WINDOWED=1
```

Recommendations:

- **macOS**: Use any resolution you see fit.
- **iPad**: Set these values to logical resolution of your device, for example iPad Pro 11 is 1668x2388 (pixels), but its logical resolution is 834x1194 (points). Recommended: `1024x768` with `SCALE_2X=1`.

In time this stuff will receive in-game interface, right now you have to do it manually.

## Building from Source

### macOS (Xcode)

```bash
cmake -B build-macos -G Xcode -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-macos --config RelWithDebInfo -j $(sysctl -n hw.physicalcpu)
```

### macOS (Makefiles - faster iteration)

```bash
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j $(sysctl -n hw.physicalcpu)
./build/fallout-ce
```

### iOS Build

```bash
cmake -B build-ios \
  -D CMAKE_TOOLCHAIN_FILE=cmake/toolchain/ios.toolchain.cmake \
  -D ENABLE_BITCODE=0 \
  -D PLATFORM=OS64 \
  -G Xcode \
  -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''
cmake --build build-ios --config RelWithDebInfo -j $(sysctl -n hw.physicalcpu)
```

## Contributing

This is an Apple-focused fork. Contributions related to macOS and iOS/iPadOS are welcome!

Current goals:

- **Engine bug fixes**: Port fixes from ETTU/Fo1in2 analysis for Fallout 1-specific issues
- **iPad optimization**: Improve touch controls and UI scaling for tablets
- **Quality of life**: Backport relevant Fallout 2 improvements

## Credits

- **Original game**: Interplay/Black Isle Studios
- **Community Edition**: [alexbatalov](https://github.com/alexbatalov/fallout1-ce)
- **Fork contributors**: evaera, zverinapavel, radozd, korri123
- **Mods**: TeamX, Wasteland Ghost, Sduibek, and many others

## License

The source code in this repository is available under the [Sustainable Use License](LICENSE.md).
