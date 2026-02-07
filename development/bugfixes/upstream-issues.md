# Upstream issues scan (alexbatalov/fallout1-ce)

Last updated: 2026-02-07

Source: https://github.com/alexbatalov/fallout1-ce/issues (open issues list)

## Potential overlap with our work

- #243 "Black screen w/controls"
  - Reports a black screen with only UI controls visible on mobile.
  - Possibly overlaps with our iOS "missing datafile" black screen behavior.

- #248 "iOS How to edit f1_res.ini"
  - User cannot access f1_res.ini / fallout.cfg on iOS to adjust resolution.
  - Overlaps with our configuration access/documentation on iOS.

- #239 "cannot load iface textures nor high res main menu (macOS)"
  - High-res interface/menu issues with f1_res.ini and GOG data.
  - Related to resolution/scaling concerns (not directly to our input bugs).

- #245 "Character shows up on map when playing in high resolutions"
  - High-res presentation oddity. Not a direct match but indicates
    resolution-related edge cases.

## Not found (in open issues list)

- Cursor-at-top stutter / audio glitches
- Screen tearing during keyboard-driven cursor movement
- Sporadic touch/Pencil click offsets
- Vault 15 / ladder self-attack combat bug

Note: This scan only covered the open issues list visible without filters.
If we need a wider historical search, we should query closed issues and
perform a keyword search (stutter, tearing, ladder, vault 15, self-attack).

