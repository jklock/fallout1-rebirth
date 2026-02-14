#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — Build Releases
# =============================================================================
# Prepares a clean environment, runs full tests, and builds release artifacts:
#   - iOS IPA
#   - macOS .app bundle
#   - macOS DMG
# Then copies them into /releases.
#
# USAGE:
#   ./scripts/build/build-releases.sh
#   RELEASE_VERSION=V2 ./scripts/build/build-releases.sh
#
# CONFIGURATION (environment variables):
#   RELEASE_VERSION - Release folder under releases/ (default: "V1")
#   BUILD_TYPE      - Debug/Release/RelWithDebInfo (default: "RelWithDebInfo")
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RELEASE_VERSION="${RELEASE_VERSION:-V1}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"

RELEASES_DIR="$ROOT_DIR/releases"
RELEASE_IOS_DIR="$RELEASES_DIR/iOS/$RELEASE_VERSION"
RELEASE_MAC_DIR="$RELEASES_DIR/macos/$RELEASE_VERSION"

APP_NAME="Fallout 1 Rebirth.app"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()      { echo -e "${GREEN}✅${NC} $1"; }
log_warn()    { echo -e "${YELLOW}⚠️${NC}  $1"; }
log_error()   { echo -e "${RED}❌${NC} $1"; }
log_section() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}"; }

log_section "Preparing clean environment"

# Shut down any running simulators (best-effort)
"$ROOT_DIR/scripts/test/test-ios-simulator.sh" --shutdown >/dev/null 2>&1 || true

# Clean build artifacts
"$ROOT_DIR/scripts/dev/dev-clean.sh"

# Clean build outputs to avoid stale artifacts
rm -rf "$ROOT_DIR/build-outputs/iOS" "$ROOT_DIR/build-outputs/macOS"

# Prepare release directories
mkdir -p "$RELEASE_IOS_DIR" "$RELEASE_MAC_DIR"

# Remove old artifacts in release folders
rm -f "$RELEASE_IOS_DIR"/*.ipa 2>/dev/null || true
rm -f "$RELEASE_MAC_DIR"/*.dmg 2>/dev/null || true
rm -rf "$RELEASE_MAC_DIR/$APP_NAME" 2>/dev/null || true

log_section "Running tests"
"$ROOT_DIR/scripts/rme/rme-ensure-patched-data.sh" --quiet
"$ROOT_DIR/scripts/dev/dev-check.sh"
"$ROOT_DIR/scripts/dev/dev-verify.sh"
"$ROOT_DIR/scripts/test/test-macos.sh"
GAME_DATA="$ROOT_DIR/GOG/patchedfiles" "$ROOT_DIR/scripts/test/test-ios-headless.sh" --build

log_section "Building release artifacts"
export BUILD_TYPE

# iOS IPA
"$ROOT_DIR/scripts/build/build-ios-ipa.sh"

# macOS app + DMG
"$ROOT_DIR/scripts/build/build-macos.sh"
"$ROOT_DIR/scripts/build/build-macos-dmg.sh"

log_section "Collecting artifacts"

IPA_PATH=$(ls -t "$ROOT_DIR/build-outputs/iOS"/*.ipa 2>/dev/null | head -1 || true)
if [[ -z "${IPA_PATH}" ]]; then
    log_error "No IPA found in build-outputs/iOS"
    exit 1
fi

DMG_PATH=$(ls -t "$ROOT_DIR/build-outputs/macOS"/*.dmg 2>/dev/null | head -1 || true)
if [[ -z "${DMG_PATH}" ]]; then
    log_error "No DMG found in build-outputs/macOS"
    exit 1
fi

APP_PATH="$ROOT_DIR/build-macos/$BUILD_TYPE/$APP_NAME"
if [[ ! -d "$APP_PATH" ]]; then
    APP_PATH=$(find "$ROOT_DIR/build-macos" -name "$APP_NAME" -maxdepth 3 -print -quit)
fi

if [[ -z "${APP_PATH}" || ! -d "$APP_PATH" ]]; then
    log_error "macOS app bundle not found: $APP_NAME"
    exit 1
fi

log_ok "Found IPA: $IPA_PATH"
log_ok "Found DMG: $DMG_PATH"
log_ok "Found app bundle: $APP_PATH"

log_section "Copying artifacts to releases"

cp -f "$IPA_PATH" "$RELEASE_IOS_DIR/"
cp -f "$DMG_PATH" "$RELEASE_MAC_DIR/"

ditto "$APP_PATH" "$RELEASE_MAC_DIR/$APP_NAME"

log_ok "Release artifacts copied"

echo ""
echo "Release folders:"
echo "  iOS:  $RELEASE_IOS_DIR"
echo "  macOS: $RELEASE_MAC_DIR"
echo ""

echo "Artifacts:"
echo "  - $(basename "$IPA_PATH")"
echo "  - $(basename "$DMG_PATH")"
echo "  - $APP_NAME"
echo ""
