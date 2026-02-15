#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PATCHED_DIR="${PATCHED_DIR:-${GAME_DATA:-}}"
GAMEFILES_ROOT="${FALLOUT_GAMEFILES_ROOT:-${GAMEFILES_ROOT:-}}"
MAC_CONFIG_DIR="${MAC_CONFIG_DIR:-$ROOT_DIR/gameconfig/macos}"

TARGET_APP=""
TARGET_RESOURCES=""
PRINT_SOURCE=0
QUIET=0

log() {
  if [[ "$QUIET" != "1" ]]; then
    printf ">>> %s\n" "$*"
  fi
}

fail() {
  printf "[ERROR] %s\n" "$*" >&2
  exit 2
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  else
    fail "No SHA256 tool found (need shasum or openssl)"
  fi
}

show_help() {
  cat <<'USAGE'
Usage: ./scripts/test/test-rme-ensure-patched-data.sh [OPTIONS]

Ensures the patched RME test data source exists and,
when a target app/resources path is supplied, ensures that exact data is
installed in the app bundle.

OPTIONS:
  --patched-dir PATH       Source directory containing master.dat/critter.dat/data
  --target-app PATH        Path to Fallout 1 Rebirth .app bundle
  --target-resources PATH  Path to app Contents/Resources
  --print-source           Print resolved patched data source path and exit
  --quiet                  Suppress informational output
  --help                   Show this help
USAGE
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --patched-dir)
      PATCHED_DIR="$2"
      shift 2
      ;;
    --target-app)
      TARGET_APP="$2"
      shift 2
      ;;
    --target-resources)
      TARGET_RESOURCES="$2"
      shift 2
      ;;
    --print-source)
      PRINT_SOURCE=1
      shift
      ;;
    --quiet)
      QUIET=1
      shift
      ;;
    --help|-h)
      show_help
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

if [[ -z "$PATCHED_DIR" && -n "$GAMEFILES_ROOT" ]]; then
  PATCHED_DIR="$GAMEFILES_ROOT/patchedfiles"
fi

if [[ -z "$PATCHED_DIR" ]]; then
  fail "Missing patched data source. Set --patched-dir, GAME_DATA, PATCHED_DIR, or FALLOUT_GAMEFILES_ROOT."
fi

if [[ -d "$PATCHED_DIR" ]]; then
  PATCHED_DIR="$(cd "$PATCHED_DIR" && pwd)"
fi

if [[ ! -d "$PATCHED_DIR" ]]; then
  fail "Patched data directory is missing: $PATCHED_DIR"
fi
if [[ ! -f "$PATCHED_DIR/master.dat" || ! -f "$PATCHED_DIR/critter.dat" || ! -d "$PATCHED_DIR/data" ]]; then
  fail "Patched data is incomplete at $PATCHED_DIR (need master.dat, critter.dat, data/)"
fi

if [[ "$PRINT_SOURCE" == "1" ]]; then
  printf "%s\n" "$PATCHED_DIR"
fi

if [[ -n "$TARGET_RESOURCES" && -z "$TARGET_APP" ]]; then
  # Derive .app bundle path from .../Contents/Resources
  base_name="$(basename "$TARGET_RESOURCES")"
  parent_name="$(basename "$(dirname "$TARGET_RESOURCES")")"
  if [[ "$base_name" != "Resources" || "$parent_name" != "Contents" ]]; then
    fail "--target-resources must point to '<app>.app/Contents/Resources': $TARGET_RESOURCES"
  fi
  TARGET_APP="$(cd "$TARGET_RESOURCES/../.." && pwd)"
fi

if [[ -n "$TARGET_APP" && -z "$TARGET_RESOURCES" ]]; then
  TARGET_RESOURCES="$TARGET_APP/Contents/Resources"
fi

if [[ -z "$TARGET_APP" && -z "$TARGET_RESOURCES" ]]; then
  exit 0
fi

if [[ ! -d "$TARGET_APP" ]]; then
  fail "Target app bundle not found: $TARGET_APP"
fi

if [[ ! -d "$TARGET_RESOURCES" ]]; then
  log "Creating missing Resources directory: $TARGET_RESOURCES"
  mkdir -p "$TARGET_RESOURCES"
fi

src_master_hash="$(sha256_file "$PATCHED_DIR/master.dat")"
src_critter_hash="$(sha256_file "$PATCHED_DIR/critter.dat")"

need_install=0
reason=""

if [[ ! -f "$TARGET_RESOURCES/master.dat" || ! -f "$TARGET_RESOURCES/critter.dat" || ! -d "$TARGET_RESOURCES/data" ]]; then
  need_install=1
  reason="missing required files in target resources"
else
  dst_master_hash="$(sha256_file "$TARGET_RESOURCES/master.dat")"
  dst_critter_hash="$(sha256_file "$TARGET_RESOURCES/critter.dat")"
  if [[ "$src_master_hash" != "$dst_master_hash" || "$src_critter_hash" != "$dst_critter_hash" ]]; then
    need_install=1
    reason="target DAT hashes do not match patched source"
  fi
fi

if [[ "$need_install" == "1" ]]; then
  log "Installing patched data into app ($reason)"
  "$ROOT_DIR/scripts/build/build-install-game-data.sh" --source "$PATCHED_DIR" --target "$TARGET_APP"
fi

if [[ ! -f "$TARGET_RESOURCES/master.dat" || ! -f "$TARGET_RESOURCES/critter.dat" || ! -d "$TARGET_RESOURCES/data" ]]; then
  fail "Target resources still missing required data after install: $TARGET_RESOURCES"
fi

verify_master_hash="$(sha256_file "$TARGET_RESOURCES/master.dat")"
verify_critter_hash="$(sha256_file "$TARGET_RESOURCES/critter.dat")"

if [[ "$src_master_hash" != "$verify_master_hash" || "$src_critter_hash" != "$verify_critter_hash" ]]; then
  fail "Target resources DAT hashes do not match patched source after install"
fi

if [[ -f "$MAC_CONFIG_DIR/fallout.cfg" ]]; then
  cp "$MAC_CONFIG_DIR/fallout.cfg" "$TARGET_RESOURCES/fallout.cfg"
fi
if [[ -f "$MAC_CONFIG_DIR/f1_res.ini" ]]; then
  cp "$MAC_CONFIG_DIR/f1_res.ini" "$TARGET_RESOURCES/f1_res.ini"
fi

log "Patched data is installed and verified"
