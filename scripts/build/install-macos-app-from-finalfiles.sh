#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth - Install macOS App + Final Files
# =============================================================================
# Copies the built app bundle into /Applications and then copies all files from
# a finalfiles directory into the app's Contents/Resources folder.
#
# Defaults:
#   app source:  releases/prod/macOS/Fallout 1 Rebirth.app
#   finalfiles:  /Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/finalfiles
#   app target:  /Applications/Fallout 1 Rebirth.app
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

APP_SOURCE="${APP_SOURCE:-$ROOT_DIR/releases/prod/macOS/Fallout 1 Rebirth.app}"
FINALFILES_SOURCE="${FINALFILES_SOURCE:-/Volumes/Storage/GitHub/fallout1-rebirth-gamefiles/finalfiles}"
APP_TARGET="${APP_TARGET:-/Applications/Fallout 1 Rebirth.app}"
DRY_RUN=0

usage() {
    cat <<EOF
Install macOS app bundle and final files

USAGE:
  ./scripts/build/install-macos-app-from-finalfiles.sh [OPTIONS]

OPTIONS:
  --app-source PATH    Source .app bundle
                       (default: $APP_SOURCE)
  --finalfiles PATH    Source finalfiles directory
                       (default: $FINALFILES_SOURCE)
  --app-target PATH    Target .app bundle path in Applications
                       (default: $APP_TARGET)
  --dry-run            Print actions only
  --help               Show this help
EOF
}

log_info()  { echo ">>> $1"; }
log_ok()    { echo "PASS: $1"; }
log_error() { echo "FAIL: $1"; }

run() {
    if [[ "$DRY_RUN" == "1" ]]; then
        echo "+ $*"
    else
        "$@"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app-source)
            APP_SOURCE="$2"
            shift 2
            ;;
        --finalfiles)
            FINALFILES_SOURCE="$2"
            shift 2
            ;;
        --app-target)
            APP_TARGET="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 2
            ;;
    esac
done

if [[ ! -d "$APP_SOURCE" ]]; then
    log_error "App source not found: $APP_SOURCE"
    exit 1
fi

if [[ ! -d "$FINALFILES_SOURCE" ]]; then
    log_error "finalfiles directory not found: $FINALFILES_SOURCE"
    exit 1
fi

TARGET_DIR="$(dirname "$APP_TARGET")"
if [[ ! -d "$TARGET_DIR" ]]; then
    log_error "Target directory does not exist: $TARGET_DIR"
    exit 1
fi

log_info "App source:      $APP_SOURCE"
log_info "finalfiles src:  $FINALFILES_SOURCE"
log_info "App target:      $APP_TARGET"

if [[ "$DRY_RUN" != "1" && ! -w "$TARGET_DIR" ]]; then
    log_error "No write access to $TARGET_DIR (run with sudo or adjust permissions)."
    exit 1
fi

log_info "Installing .app bundle into Applications..."
run rm -rf "$APP_TARGET"
run ditto "$APP_SOURCE" "$APP_TARGET"

RESOURCES_DIR="$APP_TARGET/Contents/Resources"
if [[ ! -d "$RESOURCES_DIR" ]]; then
    log_error "Resources directory missing after install: $RESOURCES_DIR"
    exit 1
fi

log_info "Copying finalfiles into app Resources..."
run rsync -a "$FINALFILES_SOURCE/" "$RESOURCES_DIR/"

log_ok "Install complete"
echo "App:       $APP_TARGET"
echo "Resources: $RESOURCES_DIR"
