#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

MAC_APP="${MAC_APP:-$ROOT_DIR/releases/prod/macOS/Fallout 1 Rebirth.app}"
IOS_IPA="${IOS_IPA:-$ROOT_DIR/releases/prod/iOS/fallout1-rebirth.ipa}"

python3 "$ROOT_DIR/scripts/test/test-rme-config-packaging.py" \
  --mac-app "$MAC_APP" \
  --ios-ipa "$IOS_IPA" \
  --require-artifacts
