#!/usr/bin/env python3
"""Validate config template and release artifact alignment."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[2]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").replace("\r\n", "\n")


def compare_files(label: str, expected: Path, actual: Path, errors: list[str]) -> None:
    if not expected.is_file():
        errors.append(f"{label}: missing expected file: {expected}")
        return
    if not actual.is_file():
        errors.append(f"{label}: missing actual file: {actual}")
        return

    if read_text(expected) != read_text(actual):
        errors.append(f"{label}: mismatch: {actual} != {expected}")


def find_payload_app_member(zf: zipfile.ZipFile, suffix: str) -> str | None:
    members = [name for name in zf.namelist() if name.startswith("Payload/") and name.endswith(suffix)]
    if not members:
        return None
    # deterministic choice in case of multiple payload apps
    return sorted(members)[0]


def read_zip_text(zf: zipfile.ZipFile, member: str) -> str:
    with zf.open(member, "r") as handle:
        return handle.read().decode("utf-8").replace("\r\n", "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate config packaging alignment")
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument(
        "--mac-app",
        type=Path,
        default=ROOT / "releases/prod/macOS/Fallout 1 Rebirth.app",
        help="Path to release macOS app bundle",
    )
    parser.add_argument(
        "--ios-ipa",
        type=Path,
        default=ROOT / "releases/prod/iOS/fallout1-rebirth.ipa",
        help="Path to release iOS IPA",
    )
    parser.add_argument(
        "--require-artifacts",
        action="store_true",
        help="Fail if macOS app or iOS IPA is missing",
    )
    args = parser.parse_args()

    root = args.root.resolve()
    mac_app = args.mac_app.resolve()
    ios_ipa = args.ios_ipa.resolve()

    errors: list[str] = []

    # Templates must stay in sync.
    compare_files(
        "template-macos-fallout",
        root / "gameconfig/macos/fallout.cfg",
        root / "dist/macos/fallout.cfg",
        errors,
    )
    compare_files(
        "template-macos-f1",
        root / "gameconfig/macos/f1_res.ini",
        root / "dist/macos/f1_res.ini",
        errors,
    )
    compare_files(
        "template-ios-fallout",
        root / "gameconfig/ios/fallout.cfg",
        root / "dist/ios/fallout.cfg",
        errors,
    )
    compare_files(
        "template-ios-f1",
        root / "gameconfig/ios/f1_res.ini",
        root / "dist/ios/f1_res.ini",
        errors,
    )

    # Release macOS app resources should match macOS templates.
    mac_fallout = mac_app / "Contents/Resources/fallout.cfg"
    mac_f1 = mac_app / "Contents/Resources/f1_res.ini"
    if mac_app.exists():
        compare_files(
            "artifact-macos-fallout",
            root / "gameconfig/macos/fallout.cfg",
            mac_fallout,
            errors,
        )
        compare_files(
            "artifact-macos-f1",
            root / "gameconfig/macos/f1_res.ini",
            mac_f1,
            errors,
        )
    elif args.require_artifacts:
        errors.append(f"artifact-macos: missing app bundle: {mac_app}")

    # Release IPA payload should include iOS config files matching templates.
    if ios_ipa.exists():
        try:
            with zipfile.ZipFile(ios_ipa, "r") as zf:
                ipa_fallout = find_payload_app_member(zf, "/fallout.cfg")
                ipa_f1 = find_payload_app_member(zf, "/f1_res.ini")

                if ipa_fallout is None:
                    errors.append(f"artifact-ios: missing fallout.cfg in {ios_ipa}")
                else:
                    expected = read_text(root / "gameconfig/ios/fallout.cfg")
                    actual = read_zip_text(zf, ipa_fallout)
                    if actual != expected:
                        errors.append("artifact-ios-fallout: mismatch with gameconfig/ios/fallout.cfg")

                if ipa_f1 is None:
                    errors.append(f"artifact-ios: missing f1_res.ini in {ios_ipa}")
                else:
                    expected = read_text(root / "gameconfig/ios/f1_res.ini")
                    actual = read_zip_text(zf, ipa_f1)
                    if actual != expected:
                        errors.append("artifact-ios-f1: mismatch with gameconfig/ios/f1_res.ini")
        except zipfile.BadZipFile:
            errors.append(f"artifact-ios: invalid ipa/zip: {ios_ipa}")
    elif args.require_artifacts:
        errors.append(f"artifact-ios: missing ipa: {ios_ipa}")

    if errors:
        for err in errors:
            print(f"FAIL: {err}", file=sys.stderr)
        return 1

    print("PASS: template and packaged config alignment is valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
