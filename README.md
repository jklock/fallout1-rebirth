<p align="center">
  <img src="img/RebirthLogo.png" alt="Fallout 1 Rebirth" width="512">
</p>

# Fallout 1 Rebirth

Last updated: 2026-02-07

**Play Fallout 1 on your Mac or iPad** — the classic 1997 RPG, rebuilt for Apple platforms.

Fallout 1 Rebirth is a modern engine reimplementation that lets you play Fallout on macOS and iOS/iPadOS with native performance, bug fixes, and quality-of-life improvements.

> **You must own the game** — This is an engine only. Game data files from your own Fallout 1 copy are required.

---

## Features

- **Native Apple Silicon** — Runs natively on M1/M2/M3/M4 Macs and modern iPads
- **SDL3 Engine** — First Fallout CE fork to upgrade to SDL3 with pixel-perfect scaling
- **Full touch support** — Intuitive gestures + Apple Pencil integration on iPad
- **Magic Keyboard/Trackpad** — Full mouse and keyboard support on iPad
- **VSync & ProMotion** — Smooth 120Hz gameplay on compatible displays
- **Retina display support** — Sharp 2X scaling for high-DPI screens
- **Engine bug fixes** — Survivalist perk fix, combat improvements, and more
- **Community improvements** — Object tooltips, combat enhancements, TeamX patch compatibility

---

## Download

**[Download the latest release →](https://github.com/jklock/fallout1-rebirth/releases)**

| Platform | Download | Requirements |
|----------|----------|--------------|
| **macOS** | `Fallout 1 Rebirth.dmg` | macOS 11+ (Big Sur or later) |
| **iOS/iPadOS** | `fallout1-rebirth.ipa` | iOS 15+ (sideloading required) |

---

## Quick Start

### What You Need

1. **The app** — Download from [Releases](https://github.com/jklock/fallout1-rebirth/releases)
2. **Game data** — From your Fallout 1 copy:
   - `master.dat` (~300 MB)
   - `critter.dat` (~25 MB)
   - `data/` folder
3. **Config files** — Included in releases or from [gameconfig/](gameconfig/)

### macOS Installation

1. Download and install `Fallout 1 Rebirth.dmg`
2. Right-click the app → **Show Package Contents** → open `Contents/MacOS/`
3. Copy your game files (`master.dat`, `critter.dat`, `data/`) into this folder
4. Copy config files (`fallout.cfg`, `f1_res.ini`) from [gameconfig/macos/](gameconfig/macos/)
5. Run the app!

> 📖 **Need help?** See the [complete setup guide](docs/setup_guide.md) for detailed instructions.

### iPad Installation

1. Download `fallout1-rebirth.ipa`
2. Sideload using [AltStore](https://altstore.io/) or [Sideloadly](https://sideloadly.io/)
3. Run the app once (on iOS you may just see a black screen if data files are missing — that's normal)
4. Use Finder to copy game files + config files into the app's Documents folder
5. Relaunch and play!

> 📖 **iPad setup** is more involved. See [docs/setup_guide.md](docs/setup_guide.md) for step-by-step instructions.

---

## Controls

### iPad Touch Controls

| Gesture | Action |
|---------|--------|
| Tap | Move cursor to tap position + left-click |
| One-finger pan | Move cursor; if started near cursor, drags |
| Long-press | Left-click drag |
| Two-finger tap | Right-click (change cursor mode) |
| Three-finger tap | Left-click |
| Two-finger pan | Scroll |

### Apple Pencil

| Gesture | Action |
|---------|--------|
| Tap | Same as touch (move + left-click) |
| Pan | Always drags (left button held) |
| Double-tap or squeeze (body) | Right-click (if enabled) |

> Pencil body gestures are controlled by `pencil_right_click` in `fallout.cfg`.

### Magic Keyboard / Trackpad

Full mouse and keyboard support — works just like on Mac.

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Setup Guide](docs/setup_guide.md) | Complete installation walkthrough |
| [Configuration](docs/configuration.md) | All settings explained |
| [Features](docs/features.md) | Full list of improvements and fixes |

---

## Troubleshooting

**"Could not find the master datafile"**  
→ Game data files aren't in the right location. See [setup guide](docs/setup_guide.md).

**Game runs at wrong resolution**  
→ Make sure `f1_res.ini` is in the same folder as your game data.

**Touch/click doesn't hit the target (iOS)**  
→ Adjust `CLICK_OFFSET_Y` in `f1_res.ini` `[INPUT]` section (default is `0`). See [configuration docs](docs/configuration.md).

**Files have wrong case (MASTER.DAT vs master.dat)**  
→ Filenames must be lowercase. See [setup guide](docs/setup_guide.md#part-2-getting-game-data-files).

---

## For Developers

Want to build from source or contribute? See:

- [Building from source](docs/building.md)
- [Contributing guidelines](docs/contributing.md)
- [Architecture overview](docs/architecture.md)

---

## Credits

- **Original game**: Interplay / Black Isle Studios
- **Engine reimplementation**: [alexbatalov/fallout1-ce](https://github.com/alexbatalov/fallout1-ce)
- **Community contributors**: evaera, zverinapavel, radozd, korri123, and many others

> For Windows, Linux, or Android, use the upstream project: [fallout1-ce](https://github.com/alexbatalov/fallout1-ce)

---

## License

Source code is available under the [Sustainable Use License](LICENSE.md).

---
