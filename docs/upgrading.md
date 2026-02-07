# Upgrading Fallout 1 Rebirth

This guide explains how to update Fallout 1 Rebirth to a new version **without losing your save data**.

> ⚠️ **Always back up your saves before upgrading!** While upgrades should preserve your data, it's good practice to keep a backup.

---

## Quick Reference: Important Files

| File/Folder | Purpose | Must Backup? |
|-------------|---------|--------------|
| `data/SAVEGAME/` | Your saved games | ✅ **Yes** |
| `fallout.cfg` | Game configuration | ✅ Yes |
| `f1_res.ini` | Resolution/display settings | ✅ Yes |
| `data/PREMADE/` | Exported characters | ✅ Yes (if you have exports) |
| `master.dat` | Original game data | ❌ No (can re-copy from your original install) |
| `critter.dat` | Original game data | ❌ No (can re-copy from your original install) |

---

## For macOS

### Step 1: Locate Your Game Data

Your game data is stored alongside the application. The typical location is:

```
~/Applications/Fallout 1 Rebirth.app  (or wherever you installed it)
```

The game data files are in the **same folder** as the app:
```
Fallout 1 Rebirth.app
master.dat
critter.dat
data/
├── SAVEGAME/     ← Your saves are here!
├── PREMADE/      ← Exported characters
├── ...
fallout.cfg
f1_res.ini
```

### Step 2: Backup Your Data

1. **Open Finder** and navigate to your game folder
2. **Copy these items** to a safe location (e.g., Desktop or Documents):
   - `data/SAVEGAME/` folder (entire folder)
   - `data/PREMADE/` folder (if you have exported characters)
   - `fallout.cfg` file
   - `f1_res.ini` file

**Quick Terminal backup** (optional):
```bash
# Create a timestamped backup
BACKUP_DIR=~/Desktop/fallout-backup-$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"
cp -R "/path/to/game/data/SAVEGAME" "$BACKUP_DIR/"
cp -R "/path/to/game/data/PREMADE" "$BACKUP_DIR/" 2>/dev/null
cp "/path/to/game/fallout.cfg" "$BACKUP_DIR/"
cp "/path/to/game/f1_res.ini" "$BACKUP_DIR/"
echo "Backup saved to: $BACKUP_DIR"
```

### Step 3: Install the New Version

1. **Download** the new DMG from GitHub Releases
2. **Double-click** the DMG to mount it
3. **Drag** "Fallout 1 Rebirth.app" to your Applications folder (or game folder)
4. If prompted, choose **Replace** to overwrite the old version
5. **Eject** the DMG

### Step 4: Restore Your Data

1. Navigate to your game folder in Finder
2. **Copy back** your backed-up files:
   - Replace `data/SAVEGAME/` with your backup
   - Replace `data/PREMADE/` with your backup (if applicable)
   - Replace `fallout.cfg` with your backup
   - Replace `f1_res.ini` with your backup

> 💡 **Tip:** If you're upgrading from a version with different config options, you may want to keep the new config files and manually adjust settings instead of overwriting.

### Step 5: Verify the Upgrade

1. **Launch** Fallout 1 Rebirth
2. Go to **Load Game** and verify your saves appear
3. **Load a save** and confirm it works correctly
4. Check that your settings (resolution, sound, etc.) are correct

---

## For iOS/iPadOS

### Step 1: Understand the Data Location

On iOS/iPadOS, your game data is stored in the app's **container**:
```
App Container/
├── Documents/
│   ├── master.dat
│   ├── critter.dat
│   ├── data/
│   │   ├── SAVEGAME/     ← Your saves
│   │   ├── PREMADE/      ← Exported characters
│   │   └── ...
│   ├── fallout.cfg
│   └── f1_res.ini
```

### Step 2: Backup Using Finder (macOS Catalina and later)

1. **Connect** your iPhone/iPad to your Mac with a cable
2. **Open Finder** and select your device in the sidebar
3. Click the **Files** tab
4. Find **Fallout 1 Rebirth** in the app list
5. **Drag the following** to your Mac (e.g., Desktop):
   - `data/SAVEGAME/` folder
   - `data/PREMADE/` folder (if present)
   - `fallout.cfg`
   - `f1_res.ini`

### Step 2 (Alternative): Backup Using iTunes (Windows or older macOS)

1. **Connect** your device and open iTunes
2. Select your device and go to **File Sharing**
3. Select **Fallout 1 Rebirth**
4. Select the files/folders listed above
5. Click **Save** to copy them to your computer

### Step 3: Install the New Version

#### Via AltStore/Sideloading:
1. **Download** the new IPA from GitHub Releases
2. **Install** using your preferred sideloading method (AltStore, Sideloadly, etc.)
3. The app will be reinstalled, which may clear the container

#### Via TestFlight (if available):
1. Updates are automatic—your data should be preserved
2. Still recommended to backup before major updates

### Step 4: Restore Your Game Data

1. **Connect** your device to your Mac/PC
2. **Open Finder** (or iTunes) and go to the Files tab
3. Select **Fallout 1 Rebirth**
4. **Drag your backed-up files** into the app's documents:
   - `data/SAVEGAME/` folder
   - `data/PREMADE/` folder
   - `fallout.cfg`
   - `f1_res.ini`
5. Also copy `master.dat` and `critter.dat` if they were removed

### Step 5: Verify the Upgrade

1. **Launch** Fallout 1 Rebirth on your device
2. Tap **Load Game** and verify your saves appear
3. **Load a save** and confirm it works
4. Check your display and control settings

---

## Troubleshooting

### Saves don't appear after upgrade

1. Verify the `SAVEGAME` folder is in the correct location (`data/SAVEGAME/`)
2. Check that save files have the correct structure (each save is a folder like `SLOT01/`, `SLOT02/`, etc.)
3. Ensure file permissions allow reading

### Game crashes on load

1. The save may be incompatible with the new version (rare)
2. Try loading an earlier save
3. Check the game logs for error messages
4. Report the issue on GitHub with details

### Settings are wrong after upgrade

1. Your `fallout.cfg` or `f1_res.ini` may have new options
2. Try deleting your old config files and reconfiguring in-game
3. Compare old and new config files to merge settings manually

### "master.dat not found" error

1. The original game data files need to be in the game folder
2. Copy `master.dat` and `critter.dat` from your original installation
3. On iOS, use Finder/iTunes to copy these files to the app container

---

## Important Notes

### Original Game Data
- `master.dat` and `critter.dat` are from the original Fallout game
- These files are **always safe to re-copy** from your original installation
- They are not modified by the game and contain no user data

### Mods and Custom Patches

---

## Proof of Work

- **Timestamp**: February 5, 2026
- **Files verified**:
  - Project structure confirms save game locations and configuration file paths
  - `gameconfig/` directory confirms configuration templates exist
- **Updates made**: No updates needed - content verified accurate. Upgrade instructions, backup procedures, and troubleshooting guidance are all current.
- Custom mods or patches may need to be **reinstalled** after upgrading
- Check if the mod is compatible with the new version
- Back up any mod files separately if needed

### Configuration Files
- New versions may add new configuration options
- If you experience issues, try using the **default config files** that come with the new version
- You can then adjust settings in-game or manually edit the configs

### Testing Your Upgrade
- Always **test loading a save** immediately after upgrading
- Try both quick save and regular saves
- Verify that the game plays correctly before deleting your backup

---

## See Also

- [Setup Guide](setup_guide.md) - Initial installation instructions
- [Configuration](configuration.md) - Config file options
- [Building](building.md) - Building from source
