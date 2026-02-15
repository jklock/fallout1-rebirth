#!/usr/bin/env python3
"""Validate config templates against baseline key coverage and platform policy."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path
import sys
from typing import Dict, Set


def read_ini(path: Path) -> configparser.ConfigParser:
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    with path.open("r", encoding="utf-8") as handle:
        parser.read_file(handle)
    return parser


def read_manifest(path: Path) -> Dict[str, Set[str]]:
    required: Dict[str, Set[str]] = {}
    with path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if "::" not in line:
                raise ValueError(f"{path}: invalid key manifest line: {line}")
            section, key = line.split("::", 1)
            required.setdefault(section, set()).add(key)
    return required


def validate_required_keys(
    path: Path,
    required: Dict[str, Set[str]],
) -> list[str]:
    errors: list[str] = []

    parser = read_ini(path)
    actual_sections = set(parser.sections())
    required_sections = set(required.keys())

    missing_sections = sorted(required_sections - actual_sections)
    if missing_sections:
        errors.append(f"{path}: missing sections: {', '.join(missing_sections)}")
    for section, keys in required.items():
        if not parser.has_section(section):
            continue
        actual_keys = set(parser.options(section))
        missing_keys = sorted(keys - actual_keys)
        if missing_keys:
            errors.append(f"{path} [{section}]: missing keys: {', '.join(missing_keys)}")

    return errors


def get(parser: configparser.ConfigParser, section: str, key: str) -> str:
    return parser.get(section, key, fallback="").strip()


def parse_int(path: str, section: str, key: str, value: str, errors: list[str]) -> int | None:
    if value == "":
        errors.append(f"{path} [{section}] {key}: missing integer value")
        return None
    try:
        return int(value)
    except ValueError:
        errors.append(f"{path} [{section}] {key}: expected integer, got {value}")
        return None


def validate_defaults(root: Path) -> list[str]:
    errors: list[str] = []

    mac_res = read_ini(root / "gameconfig/macos/f1_res.ini")
    ios_res = read_ini(root / "gameconfig/ios/f1_res.ini")
    mac_cfg = read_ini(root / "gameconfig/macos/fallout.cfg")
    ios_cfg = read_ini(root / "gameconfig/ios/fallout.cfg")

    if get(mac_res, "MAIN", "WINDOWED") != "1":
        errors.append("gameconfig/macos/f1_res.ini [MAIN] WINDOWED must be 1 (macOS default windowed)")
    if get(ios_res, "MAIN", "WINDOWED") != "0":
        errors.append("gameconfig/ios/f1_res.ini [MAIN] WINDOWED must be 0 (iOS default fullscreen)")

    for cfg_path, parser in (
        ("gameconfig/macos/f1_res.ini", mac_res),
        ("gameconfig/ios/f1_res.ini", ios_res),
    ):
        width = parse_int(cfg_path, "MAIN", "SCR_WIDTH", get(parser, "MAIN", "SCR_WIDTH"), errors)
        height = parse_int(cfg_path, "MAIN", "SCR_HEIGHT", get(parser, "MAIN", "SCR_HEIGHT"), errors)
        scale_2x = parse_int(cfg_path, "MAIN", "SCALE_2X", get(parser, "MAIN", "SCALE_2X"), errors)
        exclusive = parse_int(cfg_path, "MAIN", "EXCLUSIVE", get(parser, "MAIN", "EXCLUSIVE"), errors)
        vsync = parse_int(cfg_path, "DISPLAY", "VSYNC", get(parser, "DISPLAY", "VSYNC"), errors)
        fps_limit = parse_int(cfg_path, "DISPLAY", "FPS_LIMIT", get(parser, "DISPLAY", "FPS_LIMIT"), errors)

        if width is not None and width < 640:
            errors.append(f"{cfg_path} [MAIN] SCR_WIDTH must be >= 640")
        if height is not None and height < 480:
            errors.append(f"{cfg_path} [MAIN] SCR_HEIGHT must be >= 480")
        if scale_2x is not None and scale_2x not in (0, 1):
            errors.append(f"{cfg_path} [MAIN] SCALE_2X must be 0 or 1")
        if exclusive is not None and exclusive not in (0, 1):
            errors.append(f"{cfg_path} [MAIN] EXCLUSIVE must be 0 or 1")
        if vsync is not None and vsync not in (0, 1):
            errors.append(f"{cfg_path} [DISPLAY] VSYNC must be 0 or 1")
        if fps_limit is not None and fps_limit < -1:
            errors.append(f"{cfg_path} [DISPLAY] FPS_LIMIT must be >= -1")

    if get(mac_cfg, "input", "map_scroll_delay") != "33":
        errors.append("gameconfig/macos/fallout.cfg [input] map_scroll_delay must be 33")
    if get(ios_cfg, "input", "map_scroll_delay") != "66":
        errors.append("gameconfig/ios/fallout.cfg [input] map_scroll_delay must be 66")
    for cfg_path, parser in (
        ("gameconfig/macos/fallout.cfg", mac_cfg),
        ("gameconfig/ios/fallout.cfg", ios_cfg),
    ):
        pencil_right_click = parse_int(
            cfg_path,
            "input",
            "pencil_right_click",
            get(parser, "input", "pencil_right_click"),
            errors,
        )
        if pencil_right_click is not None and pencil_right_click not in (0, 1):
            errors.append(f"{cfg_path} [input] pencil_right_click must be 0 or 1")

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

    f1_manifest = root / "docs/audit/key-manifests/unpatched-f1_res.keys"
    fallout_manifest = root / "docs/audit/key-manifests/unpatched-fallout.cfg.keys"

    errors: list[str] = []
    if not f1_manifest.is_file():
        errors.append(f"Missing baseline manifest: {f1_manifest}")
    if not fallout_manifest.is_file():
        errors.append(f"Missing baseline manifest: {fallout_manifest}")
    if errors:
        for err in errors:
            print(f"FAIL: {err}", file=sys.stderr)
        return 1

    try:
        f1_required = read_manifest(f1_manifest)
        fallout_required = read_manifest(fallout_manifest)
    except ValueError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    checks = [
        (root / "gameconfig/macos/f1_res.ini", f1_required),
        (root / "gameconfig/ios/f1_res.ini", f1_required),
        (root / "gameconfig/macos/fallout.cfg", fallout_required),
        (root / "gameconfig/ios/fallout.cfg", fallout_required),
    ]

    errors = []
    for path, expected in checks:
        if not path.is_file():
            errors.append(f"Missing config template: {path}")
            continue
        errors.extend(validate_required_keys(path, expected))

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
