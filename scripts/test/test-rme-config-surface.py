#!/usr/bin/env python3
"""
Validate that gameconfig templates expose only runtime-consumed keys and keep
platform defaults aligned with current policy.
"""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path
import sys
from typing import Dict, Set

F1_RES_EXPECTED: Dict[str, Set[str]] = {
    "MAIN": {"SCR_WIDTH", "SCR_HEIGHT", "WINDOWED", "EXCLUSIVE", "SCALE_2X"},
    "INPUT": {"CLICK_OFFSET_X", "CLICK_OFFSET_Y", "CLICK_OFFSET_MOUSE_X", "CLICK_OFFSET_MOUSE_Y"},
}

FALLOUT_EXPECTED: Dict[str, Set[str]] = {
    "debug": {
        "mode",
        "rme_log",
        "output_map_data_info",
        "show_load_info",
        "show_script_messages",
        "show_tile_num",
    },
    "input": {
        "map_scroll_delay",
        "pencil_right_click",
    },
    "preferences": {
        "brightness",
        "combat_difficulty",
        "combat_messages",
        "combat_speed",
        "combat_taunts",
        "game_difficulty",
        "item_highlight",
        "language_filter",
        "mouse_sensitivity",
        "player_speedup",
        "running",
        "running_burning_guy",
        "subtitles",
        "target_highlight",
        "text_base_delay",
        "text_line_delay",
        "violence_level",
    },
    "sound": {
        "cache_size",
        "debug",
        "initialize",
        "master_volume",
        "music",
        "music_path1",
        "music_path2",
        "music_volume",
        "sndfx_volume",
        "sounds",
        "speech",
        "speech_volume",
    },
    "system": {
        "art_cache_size",
        "color_cycling",
        "critter_dat",
        "critter_patches",
        "cycle_speed_factor",
        "executable",
        "hashing",
        "interrupt_walk",
        "language",
        "master_dat",
        "master_patches",
        "splash",
    },
}


def read_ini(path: Path) -> configparser.ConfigParser:
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    with path.open("r", encoding="utf-8") as handle:
        parser.read_file(handle)
    return parser


def validate_surface(
    path: Path,
    expected: Dict[str, Set[str]],
) -> list[str]:
    errors: list[str] = []

    parser = read_ini(path)
    actual_sections = set(parser.sections())
    expected_sections = set(expected.keys())

    missing_sections = sorted(expected_sections - actual_sections)
    if missing_sections:
        errors.append(f"{path}: missing sections: {', '.join(missing_sections)}")

    unknown_sections = sorted(actual_sections - expected_sections)
    if unknown_sections:
        errors.append(f"{path}: unknown sections: {', '.join(unknown_sections)}")

    for section in sorted(actual_sections & expected_sections):
        actual_keys = set(parser.options(section))
        expected_keys = expected[section]

        missing_keys = sorted(expected_keys - actual_keys)
        if missing_keys:
            errors.append(f"{path} [{section}]: missing keys: {', '.join(missing_keys)}")

        unknown_keys = sorted(actual_keys - expected_keys)
        if unknown_keys:
            errors.append(f"{path} [{section}]: unknown keys: {', '.join(unknown_keys)}")

    return errors


def get(parser: configparser.ConfigParser, section: str, key: str) -> str:
    return parser.get(section, key, fallback="").strip()


def validate_defaults(root: Path) -> list[str]:
    errors: list[str] = []

    mac_res = read_ini(root / "gameconfig/macos/f1_res.ini")
    ios_res = read_ini(root / "gameconfig/ios/f1_res.ini")
    mac_cfg = read_ini(root / "gameconfig/macos/fallout.cfg")
    ios_cfg = read_ini(root / "gameconfig/ios/fallout.cfg")

    expected_res = {
        "SCR_WIDTH": "1280",
        "SCR_HEIGHT": "960",
        "SCALE_2X": "1",
        "EXCLUSIVE": "1",
    }

    for key, val in expected_res.items():
        if get(mac_res, "MAIN", key) != val:
            errors.append(
                f"gameconfig/macos/f1_res.ini [MAIN] {key}: expected {val}, got {get(mac_res, 'MAIN', key)}"
            )
        if get(ios_res, "MAIN", key) != val:
            errors.append(
                f"gameconfig/ios/f1_res.ini [MAIN] {key}: expected {val}, got {get(ios_res, 'MAIN', key)}"
            )

    if get(mac_res, "MAIN", "WINDOWED") != "1":
        errors.append("gameconfig/macos/f1_res.ini [MAIN] WINDOWED must be 1 (macOS default windowed)")
    if get(ios_res, "MAIN", "WINDOWED") != "0":
        errors.append("gameconfig/ios/f1_res.ini [MAIN] WINDOWED must be 0 (iOS default fullscreen)")

    if get(mac_cfg, "input", "map_scroll_delay") != "33":
        errors.append("gameconfig/macos/fallout.cfg [input] map_scroll_delay must be 33")
    if get(ios_cfg, "input", "map_scroll_delay") != "66":
        errors.append("gameconfig/ios/fallout.cfg [input] map_scroll_delay must be 66")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit runtime config template surface")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Repository root (default: auto)",
    )
    args = parser.parse_args()

    root = args.root.resolve()

    checks = [
        (root / "gameconfig/macos/f1_res.ini", F1_RES_EXPECTED),
        (root / "gameconfig/ios/f1_res.ini", F1_RES_EXPECTED),
        (root / "gameconfig/macos/fallout.cfg", FALLOUT_EXPECTED),
        (root / "gameconfig/ios/fallout.cfg", FALLOUT_EXPECTED),
    ]

    errors: list[str] = []
    for path, expected in checks:
        if not path.is_file():
            errors.append(f"Missing config template: {path}")
            continue
        errors.extend(validate_surface(path, expected))

    if not errors:
        errors.extend(validate_defaults(root))

    if errors:
        for err in errors:
            print(f"FAIL: {err}", file=sys.stderr)
        return 1

    print("PASS: runtime config surface and platform defaults are valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
