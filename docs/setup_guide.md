# Fallout 1 Rebirth Setup Guide

How to set up Fallout 1 Rebirth on macOS and iOS/iPadOS devices.

**Table of Contents**

- [Part 1: Prerequisites](#part-1-prerequisites)
- [Part 2: Getting Game Data Files](#part-2-getting-game-data-files)
- [Part 3: macOS Setup](#part-3-macos-setup)
- [Part 4: iOS/iPadOS Setup](#part-4-iosipados-setup)
- [Part 5: Troubleshooting](#part-5-troubleshooting)

---

## Part 1: Prerequisites

Before you begin, you'll need:

### System Requirements

#### macOS
- **Operating System**: macOS 11 (Big Sur) or later
- **Processor**: Apple Silicon (M1/M2/M3/M4) or Intel-based Mac
- **Storage**: At least 1 GB free space
- **Display**: Any resolution (the game scales to fit)

#### iOS/iPadOS
- **Operating System**: iOS 14.0+ / iPadOS 14.0+ or later
- **Device**: iPhone or iPad (iPad recommended for best experience)
- **Storage**: At least 1 GB free space

### Required Software

#### For macOS
- No additional software required for running the game
- Optional: A text editor for configuration files

#### For iOS/iPadOS
- A sideloading tool (one of the following):
  - [AltStore](https://altstore.io/) - Free, requires periodic refresh
  - [Sideloadly](https://sideloadly.io/) - Free, works on Windows and macOS
- A computer (Mac or Windows) for the initial sideloading process
- Apple ID (free account works)

### Game Data Files (Required)

You need a legitimate copy of Fallout 1 to get the required game data files. Fallout 1 Rebirth is an engine reimplementation and doesn't include any copyrighted game assets.

**Where to purchase Fallout 1:**
- [GOG.com](https://www.gog.com/game/fallout) - DRM-free, recommended
- [Steam](https://store.steampowered.com/app/38400/Fallout_A_Post_Nuclear_Role_Playing_Game/)

---

## Part 2: Getting Game Data Files

### Option A: From GOG (Recommended)

GOG provides DRM-free installers that are easy to extract.

#### On macOS:

1. Buy and download Fallout 1 from GOG.com
2. Download the macOS installer (`.pkg` file)
3. Double-click the installer to mount it
4. Navigate to the installed game location (typically in Applications or where you chose to install)
5. Locate the game data files inside the application bundle:
   - Right-click the Fallout app and select "Show Package Contents"
   - Navigate to `Contents/Resources/game/`

#### On Windows (for iOS users):

1. Purchase and download Fallout 1 from GOG.com
2. Run the installer and install the game
3. Navigate to the installation folder (typically `C:\GOG Games\Fallout\`)
4. The game data files are in this folder

### Option B: From Steam

#### On macOS:

1. Install Steam and purchase Fallout 1
2. Download and install the game through Steam
3. Right-click Fallout in your library and select "Manage" then "Browse Local Files"
4. The game data files are in this folder

#### On Windows (for iOS users):

1. Install Steam and purchase Fallout 1
2. Download and install the game through Steam
3. Right-click Fallout in your library and select "Manage" then "Browse Local Files"
4. Navigate to the Fallout folder (typically `C:\Program Files (x86)\Steam\steamapps\common\Fallout\`)

### Required Files List

You need to copy the following files and folders:

| File/Folder | Description | Required |
|-------------|-------------|----------|
| `master.dat` | Main game data archive | Yes |
| `critter.dat` | Character/creature graphics | Yes |
| `data/` | Game data folder | Yes |
| `sound/` | Sound effects and music | Yes |
| `fallout.cfg` | Game configuration | Optional (will be created) |

**Notes:**
- File names are case-sensitive on some systems
- The `data/` folder contains maps, scripts, and other game content
- Don't modify the `.dat` files

### File Structure Overview

After extracting, your game data should have this structure:

```
game-data/
├── master.dat          (approximately 300 MB)
├── critter.dat         (approximately 30 MB)
├── data/
│   ├── maps/
│   ├── proto/
│   ├── scripts/
│   └── ...
└── sound/
    ├── music/
    └── sfx/
```

---

## Part 3: macOS Setup

Follow these steps to install and run Fallout 1 Rebirth on your Mac.

### Step 1: Download the DMG

1. Go to the [Fallout 1 Rebirth Releases page](https://github.com/YOUR_USERNAME/fallout1-rebirth/releases)
   > **Note:** Update the URL above with the correct repository location.
2. Download the latest `.dmg` file for macOS
3. Wait for the download to complete

### Step 2: Open the DMG

1. Locate the downloaded DMG file (usually in your Downloads folder)
2. Double-click the DMG file to mount it
3. A new Finder window will open showing the contents

<!-- SCREENSHOT: dmg-contents.png -->
<!-- Description: The mounted DMG window showing the Fallout 1 Rebirth app icon and an arrow pointing to the Applications folder alias -->
<!-- Alt text: Finder window displaying the Fallout 1 Rebirth application and Applications folder shortcut -->

### Step 3: Copy to Applications

1. Drag the "Fallout 1 Rebirth" application to the Applications folder
2. Wait for the copy to complete
3. Eject the DMG by right-clicking it in Finder and selecting "Eject"

<!-- SCREENSHOT: copy-to-applications.png -->
<!-- Description: Dragging the Fallout 1 Rebirth app icon onto the Applications folder alias -->
<!-- Alt text: User dragging the application icon to the Applications folder -->

### Step 4: Copy Game Data Files

You have two options for placing game data files:

#### Option A: Next to the Application (Recommended)

1. Open Finder and navigate to Applications
2. Create a new folder called `Fallout1` next to the app (or use any name)
3. Copy your game data files into this folder:
   - `master.dat`
   - `critter.dat`
   - `data/` folder
   - `sound/` folder

Your Applications folder should look like:
```
Applications/
├── Fallout 1 Rebirth.app
└── Fallout1/
    ├── master.dat
    ├── critter.dat
    ├── data/
    └── sound/
```

#### Option B: Inside the Application Bundle

1. Right-click "Fallout 1 Rebirth.app" in Applications
2. Select "Show Package Contents"
3. Navigate to `Contents/Resources/`
4. Copy your game data files here

**Note:** Updates will overwrite the app bundle, so Option A is recommended for easier updates.

### Step 5: First Launch and Gatekeeper Warning

When you first launch the application, macOS Gatekeeper may block it because it was downloaded from the internet and is not notarized by Apple.

1. Double-click "Fallout 1 Rebirth" in Applications
2. You will see a security warning dialog

<!-- SCREENSHOT: gatekeeper-warning.png -->
<!-- Description: macOS security dialog stating the app cannot be opened because it is from an unidentified developer -->
<!-- Alt text: macOS Gatekeeper security warning dialog box -->

3. Click "Cancel" (do not click "Move to Trash")

### Step 6: Allow in System Settings

To allow the application to run:

1. Open **System Settings** (or System Preferences on older macOS)
2. Click on **Privacy & Security**
3. Scroll down to the **Security** section
4. You will see a message about "Fallout 1 Rebirth" being blocked
5. Click **Open Anyway**

<!-- SCREENSHOT: security-settings.png -->
<!-- Description: System Settings Privacy & Security pane showing the Open Anyway button for Fallout 1 Rebirth -->
<!-- Alt text: macOS System Settings showing the option to allow the blocked application -->

6. You may need to enter your password or use Touch ID
7. A final confirmation dialog will appear - click **Open**

**Alternative Method (Terminal):**
```bash
xattr -cr /Applications/Fallout\ 1\ Rebirth.app
```

### Step 7: Configure Resolution (Optional)

The game uses `f1_res.ini` for resolution settings.

1. Find `f1_res.ini` in the game data folder (or create one)
2. Open it with a text editor (TextEdit, VS Code, etc.)
3. Modify these settings as needed:

```ini
[MAIN]
; Set to 1 for fullscreen, 0 for windowed
WINDOWED=0

; Screen resolution (set to 0 for automatic)
SCR_WIDTH=0
SCR_HEIGHT=0

; Graphics scaling mode
SCALE_2X=0
```

**Common Resolutions:**
- `0x0` - Automatic (uses your display resolution)
- `1920x1080` - Full HD
- `2560x1440` - 2K
- `3840x2160` - 4K

> **📖 Advanced Resolution:** For detailed information about iPad resolution and scaling settings, see [development/IPAD_RESOLUTION.md](../development/IPAD_RESOLUTION.md).

### Step 8: Configure Game Settings (Optional)

The game uses `fallout.cfg` for gameplay settings.

1. Locate `fallout.cfg` in the game data folder
2. Open it with a text editor
3. Key settings you may want to adjust:

```ini
[system]
; Enable music
music=1
; Music volume (0-100)
music_volume=50

[sound]
; Enable sound effects
sounds=1
; Sound volume (0-100)
sndfx_volume=50

[preferences]
; Combat speed (1-10, higher is faster)
combat_speed=5
; Enable violence (0-3, 3 is maximum)
violence_level=3
```

### Step 9: Launch the Game

1. Double-click "Fallout 1 Rebirth" in Applications
2. The game should now start
3. If prompted about game data location, navigate to your game files folder
4. Enjoy playing Fallout 1!

---

## Part 4: iOS/iPadOS Setup

Installing apps outside the App Store requires "sideloading." Here's how to install Fallout 1 Rebirth on your iPhone or iPad.

### Understanding Sideloading

Sideloading installs apps that aren't on the App Store. On iOS/iPadOS, you need:

1. A free or paid Apple Developer account (or just an Apple ID)
2. A sideloading tool on your computer
3. The IPA file of the app you want to install

**Note:** Free Apple IDs require re-signing the app every 7 days. Paid developer accounts ($99/year) let you sign for 1 year.

### Step 1: Choose a Sideloading Tool

#### Option A: AltStore (Recommended for Beginners)

AltStore is a free app store alternative that runs on your device and handles re-signing automatically.

**Setup on macOS:**
1. Download AltServer from [altstore.io](https://altstore.io/)
2. Move AltServer to Applications
3. Launch AltServer (it appears in your menu bar)
4. Connect your iOS device via USB
5. Click the AltServer icon and select "Install AltStore" then your device
6. Enter your Apple ID when prompted
7. AltStore will be installed on your device

**Setup on Windows:**
1. Download AltServer from [altstore.io](https://altstore.io/)
2. Install iTunes and iCloud from Apple (not Microsoft Store versions)
3. Run AltInstaller and complete the setup
4. Connect your iOS device via USB
5. Click the AltServer icon in the system tray and install AltStore

#### Option B: Sideloadly (More Control)

Sideloadly gives you more control over the signing process.

1. Download Sideloadly from [sideloadly.io](https://sideloadly.io/)
2. Install it on your Mac or Windows PC
3. Launch Sideloadly

### Step 2: Get the IPA File

1. Go to the [Fallout 1 Rebirth Releases page](https://github.com/YOUR_USERNAME/fallout1-rebirth/releases)
   > **Note:** Update the URL above with the correct repository location.
2. Download the latest `.ipa` file for iOS
3. Save it somewhere easy to find (like your Downloads folder)

### Step 3: Install to Device

#### Using AltStore:

1. Make sure AltServer is running on your computer
2. Connect your iOS device via USB (or Wi-Fi if configured)
3. On your device, open Safari and navigate to the IPA file
4. Tap the download link and select "Open in AltStore"
5. AltStore will install the app

#### Using Sideloadly:

1. Connect your iOS device to your computer via USB
2. Launch Sideloadly
3. Drag the IPA file into Sideloadly (or click to browse)
4. Enter your Apple ID email
5. Click "Start" to begin installation

<!-- SCREENSHOT: sideloadly-install.png -->
<!-- Description: Sideloadly application window showing an IPA being installed, with progress bar and device information -->
<!-- Alt text: Sideloadly interface during app installation process -->

6. Enter your Apple ID password when prompted
7. Wait for the installation to complete
8. A "Done" message will appear when finished

### Step 4: Trust the Developer Certificate

After installation, you must trust the developer certificate before the app will launch.

1. On your iOS device, open **Settings**
2. Navigate to **General**
3. Scroll down and tap **VPN & Device Management** (or "Device Management" on older iOS)
4. You will see a profile with your Apple ID email
5. Tap on the profile
6. Tap **Trust "[Your Apple ID]"**
7. Confirm by tapping **Trust** in the popup

<!-- SCREENSHOT: trust-developer.png -->
<!-- Description: iOS Settings showing the VPN & Device Management screen with the Trust button for the developer certificate -->
<!-- Alt text: iOS Settings screen for trusting a developer certificate -->

### Step 5: Copy Game Files to Device

The game needs access to the game data files. You can copy them using the Files app or iTunes/Finder.

#### Method A: Using Files App (Easiest)

1. Connect your iOS device to your computer
2. Open **Finder** (macOS Catalina+) or **iTunes** (Windows/older macOS)
3. Select your device
4. Click on **Files** tab
5. Find "Fallout 1 Rebirth" in the app list
6. Drag your game files into the app's document folder:
   - `master.dat`
   - `critter.dat`
   - `data/` folder
   - `sound/` folder

<!-- SCREENSHOT: files-app-copy.png -->
<!-- Description: Finder window showing the Files tab with Fallout 1 Rebirth app and game files being copied -->
<!-- Alt text: Copying game data files to the iOS app using Finder -->

#### Method B: Using a Cloud Service

1. Upload your game files to iCloud Drive, Dropbox, or Google Drive
2. On your iOS device, open the Files app
3. Navigate to your cloud storage
4. Select all game files
5. Tap Share and select "Save to Files"
6. Navigate to: On My iPhone/iPad > Fallout 1 Rebirth
7. Tap Save

**Note:** Game files are large, so this method takes longer.

### Step 6: First Launch

1. Find the "Fallout 1 Rebirth" icon on your home screen
2. Tap to launch
3. The game will search for game data files
4. If prompted, grant access to the files location
5. The game should now load

### Step 7: Touch Controls

Fallout 1 Rebirth includes optimized touch controls for iOS/iPadOS.

<!-- SCREENSHOT: touch-controls.png -->
<!-- Description: Game screen with overlay showing touch control zones - tap to click, drag to scroll, pinch to zoom -->
<!-- Alt text: Touch control diagram showing gesture areas on the game screen -->

**Basic Controls:**

| Action | Gesture |
|--------|---------|
| Click/Select | Tap |
| Right-click/Cancel | Two-finger tap |
| Scroll/Pan | Drag with one finger |
| Zoom | Pinch in/out |
| Inventory | Tap inventory button |
| Character screen | Tap character button |

**Combat Controls:**

| Action | Gesture |
|--------|---------|
| Attack target | Tap on enemy |
| Change attack mode | Tap weapon in interface |
| End turn | Tap End Turn button |
| Use item | Drag item to target |

### Step 8: Using iPad with Keyboard and Trackpad

If you have a Magic Keyboard or external keyboard/trackpad, Fallout 1 Rebirth fully supports them.

**Keyboard Shortcuts:**

| Key | Action |
|-----|--------|
| F1 | Help |
| F2 | Save Game |
| F3 | Load Game |
| F4 | Options |
| F6 | Quick Save |
| F7 | Quick Load |
| Space | End Combat Turn |
| I | Inventory |
| C | Character |
| P | Pip-Boy |
| M | Map |
| Esc | Cancel/Menu |

**Trackpad Support:**
- Click works like tap
- Right-click works like two-finger tap
- Scroll with two fingers
- Full pointer support in iPadOS

---

## Part 5: Troubleshooting

### Common Issues and Solutions

#### "App is damaged and can't be opened"

**Symptoms:** macOS displays an error that the app is damaged.

**Solutions:**
1. Clear the quarantine flag using Terminal:
   ```bash
   xattr -cr /Applications/Fallout\ 1\ Rebirth.app
   ```
2. If that doesn't work, try re-downloading the DMG
3. Make sure you copied the app to Applications, not just running it from the DMG

#### "Game data not found"

**Symptoms:** The game launches but displays an error about missing data files.

**Solutions:**
1. Verify you have copied all required files:
   - `master.dat`
   - `critter.dat`
   - `data/` folder
2. Check file permissions - the app needs read access
3. On macOS, try placing files in:
   - Next to the .app file
   - Inside the app bundle at `Contents/Resources/`
   - In `~/Library/Application Support/Fallout1/`
4. On iOS, ensure files are in the app's Documents folder

#### Black Screen on Launch

**Symptoms:** The game starts but shows only a black screen.

**Solutions:**
1. Wait 10-15 seconds - initial loading can be slow
2. Check if music is playing (indicates the game is running)
3. Try windowed mode by editing `f1_res.ini`:
   ```ini
   WINDOWED=1
   ```
4. On macOS, try a different resolution:
   ```ini
   SCR_WIDTH=1280
   SCR_HEIGHT=720
   ```
5. Update your graphics drivers (Intel Macs only)
6. Try disabling scaling in `f1_res.ini`:
   ```ini
   SCALE_2X=0
   ```

#### Performance Issues

**Symptoms:** Game runs slowly, stutters, or has low framerate.

**Solutions:**
1. Close other applications to free up memory
2. On older devices, try lower resolution settings
3. Disable scaling effects in `f1_res.ini`
4. On macOS, check Activity Monitor for high CPU usage
5. On iOS, make sure you're not in Low Power Mode
6. Make sure your device is not overheating

#### Sound Problems

**Symptoms:** No sound, crackling audio, or music not playing.

**Solutions:**

**No Sound:**
1. Check that sound files exist in the `sound/` folder
2. Verify `fallout.cfg` has sound enabled:
   ```ini
   [sound]
   sounds=1
   [system]
   music=1
   ```
3. Check your system volume
4. On iOS, check the mute switch

**Crackling/Distorted Audio:**
1. Try adjusting the audio buffer size (if setting exists)
2. Close other audio applications
3. Restart the game

**Music Not Playing:**
1. Ensure the `sound/music/` folder exists and contains music files
2. Check `fallout.cfg` for music settings

#### iOS App Crashes on Launch

**Symptoms:** The app icon appears but the app immediately closes when tapped.

**Solutions:**
1. Make sure you trusted the developer certificate (see Step 4 in iOS Setup)
2. Re-sign the app with Sideloadly or AltStore
3. Check if your signing certificate has expired (7 days for free accounts)
4. Try reinstalling the app completely
5. Restart your device

#### App Expires After 7 Days (iOS)

**Symptoms:** The app stops launching after a week with a free Apple ID.

**Solutions:**
1. Keep AltServer running and connect your device to refresh automatically
2. With Sideloadly, repeat the installation weekly
3. Get a paid Apple Developer account ($99/year) for 1-year certificates
4. Use AltStore's background refresh with AltServer on your network

#### Game Saves Not Found

**Symptoms:** Saved games disappear or aren't accessible.

**Solutions:**
1. Saves are stored in the `data/savegame/` folder
2. Make sure the folder has write permissions
3. Don't delete the `data/` folder when updating
4. Back up your saves regularly by copying the `data/savegame/` folder

---

## Additional Resources

### Configuration File Reference

> **📁 Config Templates:** Platform-specific configuration templates are available in the [gameconfig/](../gameconfig/) folder. Copy the appropriate files from `gameconfig/macos/` or `gameconfig/ios/` to get started.

#### f1_res.ini (Resolution Settings)

| Setting | Section | Description | Values |
|---------|---------|-------------|--------|
| WINDOWED | [MAIN] | Window mode | 0=Fullscreen, 1=Windowed |
| SCR_WIDTH | [MAIN] | Screen width | 0=Auto, or pixels |
| SCR_HEIGHT | [MAIN] | Screen height | 0=Auto, or pixels |
| SCALE_2X | [MAIN] | Graphics scaling | 0=Off, 1=On |
| VSYNC | [DISPLAY] | Vertical sync | 0=Off, 1=On (default) |
| FPS_LIMIT | [DISPLAY] | Frame rate limit | -1=Match display, 0=Unlimited, or FPS value |

**VSync Settings (Recommended Defaults):**
```ini
[DISPLAY]
; VSync enabled by default for smooth scrolling and reduced tearing
VSYNC=1
; FPS_LIMIT=-1 matches the display refresh rate (60Hz, 120Hz ProMotion, etc.)
FPS_LIMIT=-1
```

> **Note:** VSync is enabled by default in Fallout 1 Rebirth for smooth gameplay. On ProMotion displays (iPad Pro, newer MacBooks), the game automatically adapts to the display's variable refresh rate.

#### fallout.cfg (Game Settings)

| Section | Setting | Description |
|---------|---------|-------------|
| [system] | music | Enable music (0/1) |
| [system] | music_volume | Music volume (0-100) |
| [sound] | sounds | Enable sound effects (0/1) |
| [sound] | sndfx_volume | Sound volume (0-100) |
| [preferences] | combat_speed | Combat animation speed (1-10) |
| [preferences] | violence_level | Gore level (0-3) |
| [input] | pencil_right_click | Apple Pencil right-click (0=Off, 1=On) |

**Apple Pencil Settings (iOS/iPadOS):**

> **🖊️ Note:** Apple Pencil support is actively being developed. Configure via the `[input]` section in `fallout.cfg`.

```ini
[input]
; Apple Pencil right-click behavior
; 0 = disabled (DEFAULT) - Pencil is a precise left-click-only device
; 1 = enabled - Pencil long-press and gestures trigger right-click
pencil_right_click=0
```

When `pencil_right_click=0` (recommended):
- Apple Pencil acts as a precise pointing device (left-click only)
- Finger touch handles general navigation with long-press for right-click
- This provides the most natural workflow: pencil for precision, fingers for navigation

### Getting Help

If you continue to experience issues:

1. Check the [GitHub Issues](https://github.com/YOUR_USERNAME/fallout1-rebirth/issues) page for known problems
   > **Note:** Update the URL above with the correct repository location.
2. Search existing issues before creating a new one
3. When reporting issues, include:
   - Your device and OS version
   - Steps to reproduce the problem
   - Any error messages
   - Relevant configuration files

---

## Credits

Fallout 1 Rebirth is based on the Fallout 1 Community Edition engine reimplementation.

- Original game by Interplay Entertainment
- Engine reimplementation by the Community Edition team
- Apple platform support by the Rebirth project

See [LICENSE.md](../LICENSE.md) for licensing information.
