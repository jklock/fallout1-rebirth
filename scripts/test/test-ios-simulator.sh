#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — iOS Simulator Test Script
# =============================================================================
# PRIMARY TARGET: iPad (the main use case for this project)
#
# REQUIREMENTS:
#   - Xcode with iOS Simulator runtimes installed
#   - Game data files (master.dat, critter.dat, data/)
#   - ~8GB free RAM (simulator is memory-intensive)
#
# LIMITS & RULES:
#   - ONE SIMULATOR AT A TIME — multiple simulators cause memory pressure
#   - Simulator architecture: arm64 (Apple Silicon) or x86_64 (Intel)
#   - App bundle is read-only at runtime; game data goes in data container
#
# USAGE:
#   ./scripts/test/test-ios-simulator.sh              # Build + install + launch
#   ./scripts/test/test-ios-simulator.sh --build-only # Just build
#   ./scripts/test/test-ios-simulator.sh --launch     # Launch existing install
#   ./scripts/test/test-ios-simulator.sh --shutdown   # Shutdown all simulators
#   ./scripts/test/test-ios-simulator.sh --list       # List available iPad sims
#
# CONFIGURATION (environment variables):
#   SIMULATOR_NAME  - Device name (default: "iPad Pro 13-inch (M5)")
#   GAME_DATA       - Path to game files (master.dat, critter.dat, data/)
#   BUILD_DIR       - Build output dir (default: "build-ios-sim")
#   BUILD_TYPE      - Debug/Release/RelWithDebInfo (default: "RelWithDebInfo")
#   CLEAN           - Set to "1" to force reconfigure
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/../.."

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
# Preferred iPad simulator — change this to match your installed runtimes
SIMULATOR_NAME="${SIMULATOR_NAME:-iPad Pro 13-inch (M5)}"

GAME_DATA="${GAME_DATA:-}"
BUILD_DIR="${BUILD_DIR:-build-ios-sim}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"
CLEAN="${CLEAN:-0}"
TOOLCHAIN="cmake/toolchain/ios.toolchain.cmake"

# iOS Simulator output directory suffix
SIM_SUFFIX="iphonesimulator"

# Bundle ID will be auto-detected from built app (not hardcoded)
APP_BUNDLE_ID=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
log_info()  { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()    { echo -e "${GREEN}✅${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠️${NC}  $1"; }
log_error() { echo -e "${RED}❌${NC} $1"; }

# Auto-detect bundle ID from built app's Info.plist
detect_bundle_id() {
    local app_path="$BUILD_DIR/$BUILD_TYPE-$SIM_SUFFIX/fallout1-rebirth.app"
    local plist="$app_path/Info.plist"
    
    if [[ ! -f "$plist" ]]; then
        log_error "Info.plist not found: $plist"
        log_info "Build the app first with: ./scripts/test/test-ios-simulator.sh --build-only"
        exit 1
    fi
    
    APP_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist" 2>/dev/null || \
                    plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null || \
                    echo "")
    
    if [[ -z "$APP_BUNDLE_ID" ]]; then
        log_error "Could not read CFBundleIdentifier from $plist"
        exit 1
    fi
    
    log_ok "Detected bundle ID: $APP_BUNDLE_ID"
}

# Wait for simulator to be fully ready (with retries)
wait_for_simulator_ready() {
    local udid="$1"
    local max_wait="${2:-120}"
    local wait_count=0
    
    log_info "Waiting for simulator to be fully ready (up to ${max_wait}s)..."
    
    while [[ $wait_count -lt $max_wait ]]; do
        # Check if device is booted
        local state
        state=$(xcrun simctl list devices -j | jq -r --arg udid "$udid" \
            '.devices | to_entries[] | .value[] | select(.udid == $udid) | .state' 2>/dev/null || echo "")
        
        if [[ "$state" == "Booted" ]]; then
            # Verify we can actually communicate with the simulator
            if xcrun simctl spawn "$udid" launchctl print system &>/dev/null; then
                log_ok "Simulator ready after ${wait_count}s"
                return 0
            fi
        fi
        
        sleep 1
        ((wait_count++))
        if (( wait_count % 15 == 0 )); then
            log_info "Still waiting... (${wait_count}s, state: ${state:-unknown})"
        fi
    done
    
    log_warn "Timeout waiting for simulator after ${max_wait}s"
    return 1
}

# Retry a command with exponential backoff
retry_with_backoff() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local cmd=("$@")
    
    for ((attempt=1; attempt<=max_attempts; attempt++)); do
        if "${cmd[@]}" 2>/dev/null; then
            return 0
        fi
        if [[ $attempt -lt $max_attempts ]]; then
            log_info "Retry $attempt/$max_attempts in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))
            if [[ $delay -gt 30 ]]; then delay=30; fi
        fi
    done
    return 1
}

# Get UDID for a simulator by name
get_simulator_udid() {
    local name="$1"
    xcrun simctl list devices available -j | \
        jq -r --arg name "$name" \
        '.devices | to_entries[] | .value[] | select(.name == $name and .isAvailable == true) | .udid' | \
        head -1
}

# Check if any simulators are booted
get_booted_simulators() {
    xcrun simctl list devices -j | \
        jq -r '.devices | to_entries[] | .value[] | select(.state == "Booted") | "\(.name) (\(.udid))"'
}

# Shutdown all booted simulators
shutdown_all_simulators() {
    log_info "Checking for running simulators..."
    local booted
    booted=$(get_booted_simulators)
    
    if [[ -n "$booted" ]]; then
        log_warn "Shutting down running simulators:"
        echo "$booted" | while read -r sim; do
            echo "  - $sim"
        done
        xcrun simctl shutdown all
        sleep 2
        log_ok "All simulators shut down"
    else
        log_ok "No simulators running"
    fi
}

# List available iPad simulators
list_ipad_simulators() {
    echo ""
    echo "=== Available iPad Simulators ==="
    xcrun simctl list devices available | grep -i "ipad" || echo "(none found)"
    echo ""
    echo "To use a different simulator, set SIMULATOR_NAME:"
    echo "  SIMULATOR_NAME='iPad Air (5th generation)' ./scripts/test/test-ios-simulator.sh"
}

# Build for simulator
build_for_simulator() {
    log_info "Building for iOS Simulator (arm64)..."
    
    if [[ ! -f "$TOOLCHAIN" ]]; then
        log_error "iOS toolchain not found: $TOOLCHAIN"
        log_info "Ensure you're running from the project root"
        exit 1
    fi
    
    # Clean if requested
    if [[ "$CLEAN" == "1" && -d "$BUILD_DIR" ]]; then
        log_warn "CLEAN=1 set, removing $BUILD_DIR..."
        rm -rf "$BUILD_DIR"
    fi
    
    # Configure if needed
    if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
        log_info "Configuring CMake for Simulator..."
        if ! cmake -B "$BUILD_DIR" \
            -D CMAKE_BUILD_TYPE="$BUILD_TYPE" \
            -D CMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
            -D ENABLE_BITCODE=0 \
            -D PLATFORM=SIMULATORARM64 \
            -D DEPLOYMENT_TARGET=26.0 \
            -G Xcode \
            -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY='' \
            -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO; then
            log_error "CMake configuration failed"
            exit 1
        fi
        log_ok "Configuration complete"
    else
        log_info "Using existing CMake configuration"
    fi
    
    # Build
    log_info "Compiling ($BUILD_TYPE, $JOBS parallel jobs)..."
    if ! cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j "$JOBS" -- \
        EXCLUDED_ARCHS=""; then
        log_error "Build failed"
        exit 1
    fi
    
    # Verify executable exists
    local app_path="$BUILD_DIR/$BUILD_TYPE-$SIM_SUFFIX/fallout1-rebirth.app"
    if [[ -f "$app_path/fallout1-rebirth" ]]; then
        log_ok "Build complete: $app_path"
        file "$app_path/fallout1-rebirth"
    else
        log_error "Build failed: executable not found"
        exit 1
    fi
}

# Install app to simulator (with retries)
install_to_simulator() {
    local udid="$1"
    local app_path="$BUILD_DIR/$BUILD_TYPE-$SIM_SUFFIX/fallout1-rebirth.app"
    
    log_info "Installing to simulator..."
    
    if [[ ! -d "$app_path" ]]; then
        log_error "App bundle not found: $app_path"
        log_info "Run with --build-only first, or without arguments to build and install"
        exit 1
    fi
    
    # Retry install with backoff (simulator may not be fully ready)
    if ! retry_with_backoff 5 2 xcrun simctl install "$udid" "$app_path"; then
        log_error "Failed to install app after retries"
        exit 1
    fi
    
    log_ok "App installed"
}

# Copy game data to simulator's data container (robust version)
copy_game_data() {
    local udid="$1"
    
    log_info "Setting up game data..."
    
    # Ensure bundle ID is detected
    if [[ -z "$APP_BUNDLE_ID" ]]; then
        detect_bundle_id
    fi
    
    # Check game data exists
    if [[ -z "$GAME_DATA" ]]; then
        log_error "GAME_DATA is not set"
        echo "  Set GAME_DATA=/path/to/FalloutData (master.dat, critter.dat, data/)"
        exit 1
    fi

    if [[ ! -f "$GAME_DATA/master.dat" ]]; then
        log_error "Game data not found at: $GAME_DATA"
        echo "  Expected files: master.dat, critter.dat, data/"
        echo "  Set GAME_DATA=/path/to/FalloutData"
        exit 1
    fi
    
    # Get app's data container with retries
    local container=""
    local attempts=0
    local max_attempts=10
    
    log_info "Looking for app data container..."
    
    while [[ -z "$container" && $attempts -lt $max_attempts ]]; do
        container=$(xcrun simctl get_app_container "$udid" "$APP_BUNDLE_ID" data 2>/dev/null || true)
        
        if [[ -z "$container" ]]; then
            ((attempts++))
            if [[ $attempts -eq 1 ]]; then
                # First failure: try launching app briefly to create container
                log_info "Container not found. Launching app briefly to create it..."
                xcrun simctl launch "$udid" "$APP_BUNDLE_ID" 2>/dev/null || true
                sleep 3
                xcrun simctl terminate "$udid" "$APP_BUNDLE_ID" 2>/dev/null || true
                sleep 1
            elif [[ $attempts -lt $max_attempts ]]; then
                log_info "Retry $attempts/$max_attempts..."
                sleep 2
            fi
        fi
    done
    
    if [[ -z "$container" ]]; then
        log_error "Could not get data container after $max_attempts attempts"
        log_info "Bundle ID: $APP_BUNDLE_ID"
        log_info "Try: xcrun simctl get_app_container $udid $APP_BUNDLE_ID data"
        exit 1
    fi
    
    log_ok "Found data container: $container"
    
    # Determine target directory (Documents is typical for iOS apps)
    local target_dir="$container/Documents"
    mkdir -p "$target_dir"
    
    log_info "Copying game files to: $target_dir"
    
    # Copy files
    cp -v "$GAME_DATA/master.dat" "$target_dir/"
    cp -v "$GAME_DATA/critter.dat" "$target_dir/"
    
    if [[ -d "$GAME_DATA/data" ]]; then
        cp -Rv "$GAME_DATA/data" "$target_dir/"
    fi
    
    # Copy or create fallout.cfg
    if [[ -f "$GAME_DATA/fallout.cfg" ]]; then
        cp -v "$GAME_DATA/fallout.cfg" "$target_dir/"
    else
        # Create minimal config pointing to the right paths
        log_info "Creating fallout.cfg..."
        cat > "$target_dir/fallout.cfg" << 'EOF'
[system]
master_dat=master.dat
master_patches=data
critter_dat=critter.dat
critter_patches=data
EOF
    fi
    
    # Copy f1_res.ini (display and input settings)
    if [[ -f "$GAME_DATA/f1_res.ini" ]]; then
        cp -v "$GAME_DATA/f1_res.ini" "$target_dir/"
    fi
    
    log_ok "Game data copied to Documents folder"
    echo "  Container: $container"
    ls -la "$target_dir/" | head -10
}

# Launch app in simulator (with retries)
launch_app() {
    local udid="$1"
    
    # Ensure bundle ID is detected
    if [[ -z "$APP_BUNDLE_ID" ]]; then
        detect_bundle_id
    fi
    
    log_info "Launching $APP_BUNDLE_ID..."
    
    # Retry launch with backoff
    local result=""
    local attempts=0
    local max_attempts=5
    local delay=2
    
    while [[ $attempts -lt $max_attempts ]]; do
        result=$(xcrun simctl launch "$udid" "$APP_BUNDLE_ID" 2>&1) && break
        ((attempts++))
        if [[ $attempts -lt $max_attempts ]]; then
            log_warn "Launch attempt $attempts failed: $result"
            log_info "Retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))
        fi
    done
    
    if [[ $attempts -ge $max_attempts ]]; then
        log_error "Failed to launch app after $max_attempts attempts"
        log_error "Last error: $result"
        exit 1
    fi
    
    log_ok "App launched: $result"
    echo ""
    echo "=== Simulator Running ==="
    echo "To view logs:"
    echo "  xcrun simctl spawn $udid log stream --predicate 'processImagePath contains \"fallout\"'"
    echo ""
    echo "To terminate:"
    echo "  xcrun simctl terminate $udid $APP_BUNDLE_ID"
    echo ""
    echo "To shutdown simulator:"
    echo "  ./scripts/test/test-ios-simulator.sh --shutdown"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "=============================================="
    echo " Fallout 1 Rebirth — iOS Simulator Testing"
    echo "=============================================="
    echo " Target: $SIMULATOR_NAME"
    echo " Game data: $GAME_DATA"
    echo " Build dir: $BUILD_DIR"
    echo "=============================================="
    echo ""
    
    # Parse arguments
    case "${1:-}" in
        --shutdown)
            shutdown_all_simulators
            exit 0
            ;;
        --list)
            list_ipad_simulators
            exit 0
            ;;
        --build-only)
            build_for_simulator
            exit 0
            ;;
        --launch)
            # Just launch existing install
            ;;
        --help|-h)
            head -30 "$0" | tail -28
            exit 0
            ;;
        "")
            # Full flow: build + install + launch
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    
    # Step 1: Ensure only one simulator
    shutdown_all_simulators
    
    # Step 2: Find simulator UDID
    log_info "Looking for simulator: $SIMULATOR_NAME"
    SIMULATOR_UDID=$(get_simulator_udid "$SIMULATOR_NAME")
    
    if [[ -z "$SIMULATOR_UDID" ]]; then
        log_error "Simulator not found: $SIMULATOR_NAME"
        list_ipad_simulators
        exit 1
    fi
    log_ok "Found: $SIMULATOR_UDID"
    
    # Step 3: Boot simulator
    log_info "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
    
    # Open Simulator.app to see the device
    open -a Simulator
    
    # Wait for simulator to be fully ready
    wait_for_simulator_ready "$SIMULATOR_UDID" 180
    
    # Step 4: Build (unless --launch)
    if [[ "${1:-}" != "--launch" ]]; then
        build_for_simulator
        
        # Detect bundle ID from built app
        detect_bundle_id
        
        install_to_simulator "$SIMULATOR_UDID"
        copy_game_data "$SIMULATOR_UDID"
    else
        # For --launch, still need to detect bundle ID
        detect_bundle_id
    fi
    
    # Step 5: Launch
    launch_app "$SIMULATOR_UDID"
    
    echo ""
    log_ok "Done! Check the Simulator window for gameplay."
    echo ""
    echo "=== Memory Warning ==="
    echo "The iOS Simulator uses significant RAM. If you experience"
    echo "system slowdowns, run: ./scripts/test/test-ios-simulator.sh --shutdown"
}

main "$@"
