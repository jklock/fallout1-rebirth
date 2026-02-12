#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — Game Data Installer for macOS
# =============================================================================
# Copies game data files (master.dat, critter.dat, data/) into the macOS
# .app bundle's Resources directory for local testing.
# Does NOT apply RME patches; use the patch scripts first.
#
# USAGE:
#   ./scripts/test/test-install-game-data.sh --source /path/to/FalloutData --target "/Applications/Fallout 1 Rebirth.app"
#   ./scripts/test/test-install-game-data.sh --source /path/to/FalloutData
#   ./scripts/test/test-install-game-data.sh --help
#
# OPTIONS:
#   --source PATH   Path to game data directory (default: . or ~/Games/Fallout1)
#   --target PATH   Path to .app bundle (default: /Applications/Fallout 1 Rebirth.app)
#   --help          Show this help message
#
# REQUIRED FILES:
#   The source directory must contain:
#   - master.dat    (main game assets)
#   - critter.dat   (character assets)
#   - data/         (additional game data)
#
# OPTIONAL FILES (copied if present):
#   - fallout.cfg
#   - f1_res.ini
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/../.."

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
DEFAULT_TARGET="/Applications/Fallout 1 Rebirth.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
log_info()  { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()    { echo -e "${GREEN}✅${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠️${NC}  $1"; }
log_error() { echo -e "${RED}❌${NC} $1"; }
log_step()  { echo -e "${CYAN}   →${NC} $1"; }

show_help() {
    cat << 'EOF'
Fallout 1 Rebirth — Game Data Installer for macOS

USAGE:
    ./scripts/test/test-install-game-data.sh [OPTIONS]

OPTIONS:
    --source PATH   Path to directory containing game data files
                    Required for non-interactive use
    
    --target PATH   Path to the .app bundle to install into
                    If omitted, the script will prompt or use /Applications/Fallout 1 Rebirth.app when present
    
    --help          Show this help message and exit

REQUIRED FILES:
    The source directory must contain:
    - master.dat    Main game assets (~300 MB)
    - critter.dat   Character/creature assets (~20 MB)
    - data/         Additional game data folder

EXAMPLES:
    # Interactive prompt (asks for source/target)
    ./scripts/test/test-install-game-data.sh

    # Specify a source folder
    ./scripts/test/test-install-game-data.sh --source /path/to/FalloutData

    # Install to a custom app location
    ./scripts/test/test-install-game-data.sh --target ~/Desktop/Fallout\ 1\ Rebirth.app

    # Full custom paths
    ./scripts/test/test-install-game-data.sh \
        --source /Volumes/Games/Fallout1 \
        --target "/Applications/Fallout 1 Rebirth.app"

NOTES:
    - Game data files are NOT included with Fallout 1 Rebirth
    - Patch data first with scripts/patch/rebirth-patch-app.sh if you need RME content
    - Set GAME_DATA to supply --source non-interactively
    - Files are copied, not moved (originals remain intact)
EOF
    exit 0
}

# -----------------------------------------------------------------------------
# Argument parsing
# -----------------------------------------------------------------------------
SOURCE_PATH=""
TARGET_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            if [[ -z "${2:-}" ]]; then
                log_error "--source requires a path argument"
                exit 1
            fi
            SOURCE_PATH="$2"
            shift 2
            ;;
        --target)
            if [[ -z "${2:-}" ]]; then
                log_error "--target requires a path argument"
                exit 1
            fi
            TARGET_PATH="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Resolve source if not specified
# -----------------------------------------------------------------------------
if [[ -z "$SOURCE_PATH" ]]; then
    if [[ -n "${GAME_DATA:-}" ]]; then
        SOURCE_PATH="$GAME_DATA"
        log_info "Using GAME_DATA: $SOURCE_PATH"
    elif [[ -t 0 ]]; then
        read -r -p "Enter path to game data folder (master.dat/critter.dat/data/): " SOURCE_PATH
    else
        log_error "Missing --source and GAME_DATA, and no interactive prompt available."
        exit 1
    fi
fi

if [[ -z "$SOURCE_PATH" ]]; then
    log_error "Source path cannot be empty."
    exit 1
fi

# Resolve target if not specified
# -----------------------------------------------------------------------------
if [[ -z "$TARGET_PATH" ]]; then
    if [[ -d "$DEFAULT_TARGET" ]]; then
        TARGET_PATH="$DEFAULT_TARGET"
        log_info "Using default app bundle: $TARGET_PATH"
    elif [[ -t 0 ]]; then
        read -r -p "Enter path to Fallout 1 Rebirth.app: " TARGET_PATH
    else
        log_error "Missing --target and default app not found, and no interactive prompt available."
        exit 1
    fi
fi

if [[ -z "$TARGET_PATH" ]]; then
    log_error "Target path cannot be empty."
    exit 1
fi

# Resolve to absolute path
SOURCE_PATH="$(cd "$SOURCE_PATH" 2>/dev/null && pwd)" || {
    log_error "Source path does not exist: $SOURCE_PATH"
    exit 1
}

echo ""
echo "=============================================="
echo " Fallout 1 Rebirth — Game Data Installer"
echo "=============================================="
echo " Source: $SOURCE_PATH"
echo " Target: $TARGET_PATH"
echo "=============================================="
echo ""

# -----------------------------------------------------------------------------
# Validation: Source files
# -----------------------------------------------------------------------------
log_info "Validating source files..."

REQUIRED_FILES=("master.dat" "critter.dat")
OPTIONAL_FILES=("fallout.cfg" "f1_res.ini")
REQUIRED_DIRS=("data")
MISSING=()

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$SOURCE_PATH/$file" ]]; then
        size=$(du -h "$SOURCE_PATH/$file" | cut -f1)
        log_step "$file ($size)"
    else
        MISSING+=("$file")
    fi
done

for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$SOURCE_PATH/$file" ]]; then
        log_step "$file (optional)"
    fi
done

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$SOURCE_PATH/$dir" ]]; then
        size=$(du -sh "$SOURCE_PATH/$dir" | cut -f1)
        log_step "$dir/ ($size)"
    else
        MISSING+=("$dir/")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo ""
    log_error "Missing required files in source directory:"
    for item in "${MISSING[@]}"; do
        echo "       - $item"
    done
    exit 1
fi

log_ok "All required files found"

# -----------------------------------------------------------------------------
# Validation: Target .app bundle
# -----------------------------------------------------------------------------
log_info "Validating target app bundle..."

if [[ ! -d "$TARGET_PATH" ]]; then
    log_error "Target app does not exist: $TARGET_PATH"
    echo ""
    echo "Make sure you have:"
    echo "  1. Built the app with: ./scripts/build/build-macos.sh"
    echo "  2. Copied it to /Applications or specified correct --target path"
    exit 1
fi

if [[ ! -d "$TARGET_PATH/Contents" ]]; then
    log_error "Invalid app bundle (missing Contents): $TARGET_PATH"
    exit 1
fi

RESOURCES_DIR="$TARGET_PATH/Contents/Resources"
if [[ ! -d "$RESOURCES_DIR" ]]; then
    log_info "Creating Resources directory..."
    mkdir -p "$RESOURCES_DIR"
fi

# Check for executable
EXECUTABLE="$TARGET_PATH/Contents/MacOS/fallout1-rebirth"
if [[ ! -x "$EXECUTABLE" ]]; then
    log_warn "Executable not found or not executable: $EXECUTABLE"
    log_warn "The app may not be properly built"
fi

log_ok "Target app bundle is valid"

# -----------------------------------------------------------------------------
# Calculate total size
# -----------------------------------------------------------------------------
log_info "Calculating data size..."
TOTAL_SIZE=0
for file in "${REQUIRED_FILES[@]}"; do
    TOTAL_SIZE=$((TOTAL_SIZE + $(stat -f%z "$SOURCE_PATH/$file")))
done
# Add data directory size
DATA_SIZE=$(du -s "$SOURCE_PATH/data" | cut -f1)
TOTAL_SIZE=$((TOTAL_SIZE + DATA_SIZE * 512))  # du -s returns 512-byte blocks

TOTAL_MB=$((TOTAL_SIZE / 1024 / 1024))
log_step "Total data size: ~${TOTAL_MB} MB"

# Check available space
AVAILABLE=$(df -k "$RESOURCES_DIR" | tail -1 | awk '{print $4}')
AVAILABLE_MB=$((AVAILABLE / 1024))
if [[ $AVAILABLE_MB -lt $TOTAL_MB ]]; then
    log_error "Insufficient disk space. Need ${TOTAL_MB}MB, have ${AVAILABLE_MB}MB"
    exit 1
fi
log_ok "Sufficient disk space available"

# -----------------------------------------------------------------------------
# Copy files
# -----------------------------------------------------------------------------
echo ""
log_info "Copying game data files..."

# Copy master.dat
log_step "Copying master.dat..."
if ! cp "$SOURCE_PATH/master.dat" "$RESOURCES_DIR/"; then
    log_error "Failed to copy master.dat"
    exit 1
fi

# Copy critter.dat
log_step "Copying critter.dat..."
if ! cp "$SOURCE_PATH/critter.dat" "$RESOURCES_DIR/"; then
    log_error "Failed to copy critter.dat"
    exit 1
fi

# Copy data directory
log_step "Copying data/ folder..."
if ! cp -R "$SOURCE_PATH/data" "$RESOURCES_DIR/"; then
    log_error "Failed to copy data/ folder"
    exit 1
fi

# Copy optional config files (if present)
for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$SOURCE_PATH/$file" ]]; then
        log_step "Copying $file..."
        if ! cp "$SOURCE_PATH/$file" "$RESOURCES_DIR/"; then
            log_error "Failed to copy $file"
            exit 1
        fi
    else
        log_warn "Optional file missing: $file"
    fi
done

# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------
log_info "Verifying installation..."

VERIFY_OK=true
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$RESOURCES_DIR/$file" ]]; then
        log_error "Verification failed: $file not found in destination"
        VERIFY_OK=false
    fi
done

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$RESOURCES_DIR/$dir" ]]; then
        log_error "Verification failed: $dir/ not found in destination"
        VERIFY_OK=false
    fi
done

if [[ "$VERIFY_OK" != "true" ]]; then
    log_error "Installation verification failed!"
    exit 1
fi

# Show installed sizes
echo ""
log_ok "Installation complete!"
echo ""
echo "  Installed files:"
for file in "${REQUIRED_FILES[@]}"; do
    size=$(du -h "$RESOURCES_DIR/$file" | cut -f1)
    echo "    - $file ($size)"
done
for dir in "${REQUIRED_DIRS[@]}"; do
    size=$(du -sh "$RESOURCES_DIR/$dir" | cut -f1)
    echo "    - $dir/ ($size)"
done
for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$RESOURCES_DIR/$file" ]]; then
        echo "    - $file"
    fi
done

echo ""
FINAL_SIZE=$(du -sh "$RESOURCES_DIR" | cut -f1)
echo "  Resources folder: $FINAL_SIZE"
echo "  Location: $RESOURCES_DIR"
echo ""
echo "You can now launch the game with:"
echo "  open \"$TARGET_PATH\""
echo ""
