#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — iOS Headless Test Script
# =============================================================================
# Validates iOS app for simulator without keeping simulator running.
# Designed for CI/CD and automated testing with no GUI interaction required.
#
# TESTS PERFORMED:
#   - App bundle exists with correct iOS structure
#   - Binary architecture (arm64 for Apple Silicon, x86_64 for Intel)
#   - Info.plist has all required iOS keys
#   - Headless simulator boot, app install, brief launch, terminate, shutdown
#   - Clean exit code verification
#   - No lingering simulator processes
#
# USAGE:
#   ./scripts/test/test-ios-headless.sh              # Full test cycle
#   ./scripts/test/test-ios-headless.sh --build      # Build first, then test
#   ./scripts/test/test-ios-headless.sh --skip-sim   # Skip simulator tests
#   ./scripts/test/test-ios-headless.sh --help       # Show usage
#
# CONFIGURATION (environment variables):
#   BUILD_DIR       - Build output directory (default: "build-ios-sim")
#   BUILD_TYPE      - Debug/Release/RelWithDebInfo (default: "RelWithDebInfo")
#   SIMULATOR_NAME  - Simulator device name (default: auto-detect iPad)
#   JOBS            - Parallel jobs (default: physical CPU count)
#
# EXIT CODES:
#   0 - All tests passed
#   1 - One or more tests failed
#
# NOTES:
#   - Uses xcrun simctl with --json for reliable parsing
#   - Simulator is booted headless (no GUI window)
#   - All simulators are shut down on completion
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/../.."
ROOT_DIR="$PWD"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
BUILD_DIR="${BUILD_DIR:-build-ios-sim}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
SIMULATOR_NAME="${SIMULATOR_NAME:-}"  # Auto-detect if empty
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"
TOOLCHAIN="cmake/toolchain/ios.toolchain.cmake"
GAME_DATA="${GAME_DATA:-}"
GAMEFILES_ROOT="${FALLOUT_GAMEFILES_ROOT:-${GAMEFILES_ROOT:-}}"

# App details
APP_NAME="fallout1-rebirth"
# iOS Simulator builds output to BUILD_TYPE-iphonesimulator directory
APP_BUNDLE="$BUILD_DIR/$BUILD_TYPE-iphonesimulator/$APP_NAME.app"
EXECUTABLE="$APP_BUNDLE/$APP_NAME"
INFO_PLIST="$APP_BUNDLE/Info.plist"

# Test parameters
LAUNCH_TIMEOUT=5  # seconds to wait for app launch
SIM_BOOT_TIMEOUT=60  # seconds to wait for simulator boot

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Simulator state
SIM_UDID=""
SIM_WAS_BOOTED=false

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
log_info()    { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()      { echo -e "${GREEN}✅${NC} $1"; }
log_warn()    { echo -e "${YELLOW}⚠️${NC}  $1"; }
log_error()   { echo -e "${RED}❌${NC} $1"; }
log_section() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}"; }
log_skip()    { echo -e "${YELLOW}⏭️${NC}  $1"; ((TESTS_SKIPPED++)); }

resolve_game_data_source() {
    local requested="${GAME_DATA:-}"
    if [[ -z "$requested" && -n "$GAMEFILES_ROOT" ]]; then
        requested="$GAMEFILES_ROOT/patchedfiles"
    fi
    if [[ -z "$requested" ]]; then
        log_error "GAME_DATA is not set. Provide GAME_DATA or FALLOUT_GAMEFILES_ROOT."
        return 1
    fi

    requested="$(cd "$requested" 2>/dev/null && pwd || true)"
    if [[ -z "$requested" ]]; then
        log_error "GAME_DATA path is invalid: $GAME_DATA"
        return 1
    fi
    if [[ ! -f "$requested/master.dat" || ! -f "$requested/critter.dat" || ! -d "$requested/data" ]]; then
        log_error "Game data is incomplete at: $requested (need master.dat, critter.dat, data/)"
        return 1
    fi

    GAME_DATA="$requested"
    log_info "Using game data: $GAME_DATA"
    return 0
}

# Run a test check
check() {
    local description="$1"
    local condition="$2"
    
    if eval "$condition"; then
        log_ok "$description"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "$description"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Print usage
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Headless validation tests for the iOS Simulator app bundle.

OPTIONS:
    --build       Build the app before running tests
    --skip-sim    Skip simulator launch tests (bundle validation only)
    --help        Show this help message

ENVIRONMENT VARIABLES:
    BUILD_DIR       Build output directory (default: build-ios-sim)
    BUILD_TYPE      Build type (default: RelWithDebInfo)
    SIMULATOR_NAME  Simulator name (default: auto-detect iPad)
    GAME_DATA       Path to game data (master.dat, critter.dat, data/)
    FALLOUT_GAMEFILES_ROOT Optional root containing patchedfiles/

EXAMPLES:
    $0                              # Test existing build
    $0 --build                      # Build and test
    $0 --skip-sim                   # Bundle tests only
    SIMULATOR_NAME='iPad Air' $0    # Use specific simulator
EOF
    exit 0
}

# Cleanup function - always shutdown simulators
cleanup() {
    log_info "Cleaning up..."
    
    # Shutdown simulator if we booted it
    if [[ -n "$SIM_UDID" ]] && [[ "$SIM_WAS_BOOTED" == false ]]; then
        xcrun simctl shutdown "$SIM_UDID" 2>/dev/null || true
    fi
    
    # Make sure no simulator windows are left
    pkill -f "Simulator.app" 2>/dev/null || true
}

trap cleanup EXIT

# -----------------------------------------------------------------------------
# Simulator utilities (JSON-based)
# -----------------------------------------------------------------------------

# Get list of available iPad simulators (JSON parsing)
get_available_ipads() {
    xcrun simctl list devices available -j 2>/dev/null | \
        jq -r '.devices | to_entries[] | .value[] | select(.name | test("iPad"; "i")) | select(.isAvailable == true) | .name' | \
        sort -u
}

# Get UDID for a simulator by name
get_simulator_udid() {
    local name="$1"
    xcrun simctl list devices available -j 2>/dev/null | \
        jq -r --arg name "$name" \
        '.devices | to_entries[] | .value[] | select(.name == $name and .isAvailable == true) | .udid' | \
        head -1
}

# Get simulator state by UDID
get_simulator_state() {
    local udid="$1"
    xcrun simctl list devices -j 2>/dev/null | \
        jq -r --arg udid "$udid" \
        '.devices | to_entries[] | .value[] | select(.udid == $udid) | .state'
}

# Auto-detect best iPad simulator
auto_detect_ipad() {
    log_info "Auto-detecting iPad simulator..." >&2
    
    local ipads
    ipads=$(get_available_ipads)
    
    if [[ -z "$ipads" ]]; then
        log_error "No iPad simulators available" >&2
        return 1
    fi
    
    # Prefer iPad Pro 13-inch, then any iPad Pro, then any iPad
    local selected=""
    
    # Try to find M4/M5 Pro first
    selected=$(echo "$ipads" | grep -i "iPad Pro.*13.*M[45]" | head -1) || true
    
    # Then any 13-inch Pro
    if [[ -z "$selected" ]]; then
        selected=$(echo "$ipads" | grep -i "iPad Pro.*13" | head -1) || true
    fi
    
    # Then any iPad Pro
    if [[ -z "$selected" ]]; then
        selected=$(echo "$ipads" | grep -i "iPad Pro" | head -1) || true
    fi
    
    # Then any iPad
    if [[ -z "$selected" ]]; then
        selected=$(echo "$ipads" | head -1) || true
    fi
    
    if [[ -z "$selected" ]]; then
        log_error "Could not select an iPad simulator" >&2
        return 1
    fi
    
    echo "$selected"
}

# Check if any simulators are currently booted
get_booted_simulators() {
    xcrun simctl list devices -j 2>/dev/null | \
        jq -r '.devices | to_entries[] | .value[] | select(.state == "Booted") | .udid'
}

# Shutdown all simulators
shutdown_all_simulators() {
    log_info "Shutting down all simulators..."
    xcrun simctl shutdown all 2>/dev/null || true
    sleep 2
    
    # Force kill Simulator app
    pkill -f "Simulator.app" 2>/dev/null || true
    sleep 1
    
    log_ok "Simulators shut down"
}

# Boot simulator in headless mode
boot_simulator_headless() {
    local udid="$1"
    
    log_info "Booting simulator in headless mode..."
    
    # Check current state
    local state
    state=$(get_simulator_state "$udid")
    
    if [[ "$state" == "Booted" ]]; then
        log_ok "Simulator already booted"
        SIM_WAS_BOOTED=true
        return 0
    fi
    
    # Boot without opening Simulator.app GUI
    if ! xcrun simctl boot "$udid" 2>/dev/null; then
        log_error "Failed to boot simulator"
        return 1
    fi
    
    # Wait for boot to complete
    local elapsed=0
    while [[ $elapsed -lt $SIM_BOOT_TIMEOUT ]]; do
        state=$(get_simulator_state "$udid")
        if [[ "$state" == "Booted" ]]; then
            # Verify runtime is ready
            if xcrun simctl spawn "$udid" launchctl print system &>/dev/null; then
                log_ok "Simulator booted and ready (${elapsed}s)"
                return 0
            fi
        fi
        sleep 2
        elapsed=$((elapsed + 2))
        if (( elapsed % 10 == 0 )); then
            log_info "Waiting for boot... (${elapsed}s, state: ${state:-unknown})"
        fi
    done
    
    log_error "Simulator boot timeout after ${SIM_BOOT_TIMEOUT}s"
    return 1
}

# Install app to simulator
install_app_to_simulator() {
    local udid="$1"
    
    log_info "Installing app to simulator..."
    
    if ! xcrun simctl install "$udid" "$APP_BUNDLE" 2>/dev/null; then
        log_error "Failed to install app"
        return 1
    fi
    
    log_ok "App installed"
    return 0
}

copy_game_data_to_simulator() {
    local udid="$1"
    local bundle_id="$2"

    if ! resolve_game_data_source; then
        return 1
    fi

    log_info "Copying game data to simulator container..."

    local container=""
    local attempts=0
    local max_attempts=8

    while [[ -z "$container" && $attempts -lt $max_attempts ]]; do
        container=$(xcrun simctl get_app_container "$udid" "$bundle_id" data 2>/dev/null || true)
        if [[ -z "$container" ]]; then
            ((attempts++))
            if [[ $attempts -eq 1 ]]; then
                # First launch creates Documents in some simulator states.
                xcrun simctl launch "$udid" "$bundle_id" 2>/dev/null || true
                sleep 2
                xcrun simctl terminate "$udid" "$bundle_id" 2>/dev/null || true
            else
                sleep 1
            fi
        fi
    done

    if [[ -z "$container" ]]; then
        log_error "Unable to resolve simulator data container for $bundle_id"
        return 1
    fi

    local target_dir="$container/Documents"
    mkdir -p "$target_dir"

    cp -f "$GAME_DATA/master.dat" "$target_dir/"
    cp -f "$GAME_DATA/critter.dat" "$target_dir/"
    rm -rf "$target_dir/data"
    cp -R "$GAME_DATA/data" "$target_dir/"

    if [[ -f "$GAME_DATA/fallout.cfg" ]]; then
        cp -f "$GAME_DATA/fallout.cfg" "$target_dir/"
    else
        cat > "$target_dir/fallout.cfg" << 'EOF'
[system]
master_dat=master.dat
master_patches=data
critter_dat=critter.dat
critter_patches=data
EOF
    fi

    if [[ -f "$GAME_DATA/f1_res.ini" ]]; then
        cp -f "$GAME_DATA/f1_res.ini" "$target_dir/"
    fi

    log_ok "Game data staged in simulator container"
    return 0
}

# Launch app briefly and check for crash
launch_app_briefly() {
    local udid="$1"
    local bundle_id="$2"
    
    log_info "Launching app briefly (${LAUNCH_TIMEOUT}s test)..."
    
    # Launch the app
    local pid
    if ! pid=$(xcrun simctl launch "$udid" "$bundle_id" 2>&1); then
        log_error "Failed to launch app: $pid"
        return 1
    fi
    
    # Extract PID from output (format: "com.bundle.id: 12345")
    pid=$(echo "$pid" | grep -oE '[0-9]+$' || echo "")
    
    log_info "App launched (PID: ${pid:-unknown})"
    
    # Wait briefly and check if still running
    sleep "$LAUNCH_TIMEOUT"
    
    # Check if app is still running (good sign)
    local running_apps
    running_apps=$(xcrun simctl spawn "$udid" launchctl list 2>/dev/null | grep -c "$bundle_id" || echo "0")
    
    if [[ "$running_apps" -gt 0 ]]; then
        log_ok "App running after ${LAUNCH_TIMEOUT}s (no crash)"
        
        # Terminate the app
        log_info "Terminating app..."
        xcrun simctl terminate "$udid" "$bundle_id" 2>/dev/null || true
        sleep 1
        
        return 0
    else
        # App exited - check if it crashed
        # Look for crash logs
        local crash_log_count
        crash_log_count=$(find ~/Library/Logs/DiagnosticReports -name "*fallout1-rebirth*" -mmin -1 2>/dev/null | wc -l | tr -d ' ')
        
        if [[ $crash_log_count -gt 0 ]]; then
            log_error "App crashed (found $crash_log_count recent crash log(s))"
            return 1
        else
            log_warn "App exited (may be expected without game data)"
            return 0
        fi
    fi
}

# Uninstall app from simulator
uninstall_app_from_simulator() {
    local udid="$1"
    local bundle_id="$2"
    
    xcrun simctl uninstall "$udid" "$bundle_id" 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# Build function
# -----------------------------------------------------------------------------
build_for_simulator() {
    log_section "Building for iOS Simulator"
    
    if [[ ! -f "$TOOLCHAIN" ]]; then
        log_error "iOS toolchain not found: $TOOLCHAIN"
        exit 1
    fi
    
    # Detect simulator architecture
    local platform="SIMULATORARM64"
    if [[ "$(uname -m)" == "x86_64" ]]; then
        platform="SIMULATOR64"
    fi
    
    # Configure if needed
    if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
        log_info "Configuring CMake for Simulator ($platform)..."
        if ! cmake -B "$BUILD_DIR" \
            -D CMAKE_BUILD_TYPE="$BUILD_TYPE" \
            -D CMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
            -D ENABLE_BITCODE=0 \
            -D PLATFORM="$platform" \
            -D DEPLOYMENT_TARGET=15.0 \
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
    
    log_ok "Build completed"
}

# -----------------------------------------------------------------------------
# Test: Bundle Structure
# -----------------------------------------------------------------------------
test_bundle_structure() {
    log_section "Test: Bundle Structure"
    
    check "App bundle exists" "[[ -d '$APP_BUNDLE' ]]" || return 1
    check "Executable exists" "[[ -f '$EXECUTABLE' ]]"
    check "Executable has +x permission" "[[ -x '$EXECUTABLE' ]]"
    check "Info.plist exists" "[[ -f '$INFO_PLIST' ]]"
    
    # iOS-specific structure checks
    # iOS apps have flat structure (no Contents/MacOS)
    if [[ -d "$APP_BUNDLE/Contents" ]]; then
        log_warn "Bundle has macOS-style Contents/ directory (unusual for iOS)"
    fi
    
    # Check for common iOS resources
    local has_assets=false
    if [[ -d "$APP_BUNDLE/Assets.car" ]] || [[ -f "$APP_BUNDLE/Assets.car" ]]; then
        has_assets=true
    fi
    
    log_info "Bundle contents:"
    ls -la "$APP_BUNDLE" 2>/dev/null | head -15 | sed 's/^/    /'
}

# -----------------------------------------------------------------------------
# Test: Binary Architecture
# -----------------------------------------------------------------------------
test_binary_architecture() {
    log_section "Test: Binary Architecture"
    
    if [[ ! -f "$EXECUTABLE" ]]; then
        log_skip "Executable not found"
        return 0
    fi
    
    local file_info
    file_info=$(file "$EXECUTABLE" 2>/dev/null || echo "")
    
    log_info "Binary info:"
    echo "$file_info" | sed 's/.*: /    /'
    
    # Check it's a Mach-O executable
    check "Binary is Mach-O executable" "[[ '$file_info' == *'Mach-O'* ]]"
    
    # Determine expected architecture based on host
    local host_arch
    host_arch=$(uname -m)
    
    if [[ "$host_arch" == "arm64" ]]; then
        # Apple Silicon - expect arm64
        check "Binary has arm64 architecture (Apple Silicon simulator)" "[[ '$file_info' == *'arm64'* ]]"
    else
        # Intel - expect x86_64
        check "Binary has x86_64 architecture (Intel simulator)" "[[ '$file_info' == *'x86_64'* ]]"
    fi
    
    # Verify it's NOT for device (should be simulator)
    if lipo -info "$EXECUTABLE" 2>/dev/null | grep -q "arm64e"; then
        log_warn "Binary contains arm64e (device architecture) - may not work in simulator"
    fi
}

# -----------------------------------------------------------------------------
# Test: Info.plist
# -----------------------------------------------------------------------------
test_info_plist() {
    log_section "Test: Info.plist Validation"
    
    if [[ ! -f "$INFO_PLIST" ]]; then
        log_skip "Info.plist not found"
        return 0
    fi
    
    # Validate syntax
    if plutil -lint "$INFO_PLIST" >/dev/null 2>&1; then
        log_ok "Info.plist has valid syntax"
        ((TESTS_PASSED++))
    else
        log_error "Info.plist has invalid syntax"
        ((TESTS_FAILED++))
        return 1
    fi
    
    # Read keys
    read_plist() {
        /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST" 2>/dev/null || \
        plutil -extract "$1" raw "$INFO_PLIST" 2>/dev/null || echo ""
    }
    
    local bundle_id bundle_name bundle_version executable_name min_ios
    bundle_id=$(read_plist "CFBundleIdentifier")
    bundle_name=$(read_plist "CFBundleName")
    bundle_version=$(read_plist "CFBundleShortVersionString")
    executable_name=$(read_plist "CFBundleExecutable")
    min_ios=$(read_plist "MinimumOSVersion")
    
    check "CFBundleIdentifier is set" "[[ -n '$bundle_id' ]]"
    check "CFBundleName is set" "[[ -n '$bundle_name' ]]"
    check "CFBundleShortVersionString is set" "[[ -n '$bundle_version' ]]"
    check "CFBundleExecutable is set" "[[ -n '$executable_name' ]]"
    
    # iOS-specific
    if [[ -n "$min_ios" ]]; then
        log_ok "MinimumOSVersion is set: $min_ios"
        ((TESTS_PASSED++))
    else
        log_info "MinimumOSVersion not set (may use default)"
    fi
    
    log_info "Bundle information:"
    echo "    Identifier:  $bundle_id"
    echo "    Name:        $bundle_name"
    echo "    Version:     $bundle_version"
    echo "    Executable:  $executable_name"
    echo "    Min iOS:     ${min_ios:-not set}"
    
    # Store bundle ID for simulator tests
    export APP_BUNDLE_ID="$bundle_id"
}

# -----------------------------------------------------------------------------
# Test: Simulator Launch
# -----------------------------------------------------------------------------
test_simulator_launch() {
    log_section "Test: Simulator Launch (Headless)"
    
    # Check dependencies
    if ! command -v jq &>/dev/null; then
        log_skip "jq not installed (required for JSON parsing)"
        return 0
    fi
    
    if [[ -z "${APP_BUNDLE_ID:-}" ]]; then
        # Try to get bundle ID
        APP_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null || echo "")
        if [[ -z "$APP_BUNDLE_ID" ]]; then
            log_skip "Could not determine bundle ID"
            return 0
        fi
    fi
    
    # Shutdown any existing simulators first
    shutdown_all_simulators
    
    # Select simulator
    if [[ -z "$SIMULATOR_NAME" ]]; then
        SIMULATOR_NAME=$(auto_detect_ipad) || {
            log_skip "No iPad simulator available"
            return 0
        }
    fi
    
    log_info "Using simulator: $SIMULATOR_NAME"
    
    # Get UDID
    SIM_UDID=$(get_simulator_udid "$SIMULATOR_NAME")
    if [[ -z "$SIM_UDID" ]]; then
        log_error "Could not find simulator: $SIMULATOR_NAME"
        ((TESTS_FAILED++))
        return 1
    fi
    
    log_info "Simulator UDID: $SIM_UDID"
    
    # Boot simulator (headless)
    if ! boot_simulator_headless "$SIM_UDID"; then
        log_error "Failed to boot simulator"
        ((TESTS_FAILED++))
        return 1
    fi
    log_ok "Simulator booted in headless mode"
    ((TESTS_PASSED++))
    
    # Install app
    if ! install_app_to_simulator "$SIM_UDID"; then
        log_error "Failed to install app"
        ((TESTS_FAILED++))
        return 1
    fi
    log_ok "App installed to simulator"
    ((TESTS_PASSED++))

    # Stage game data before launch.
    if copy_game_data_to_simulator "$SIM_UDID" "$APP_BUNDLE_ID"; then
        log_ok "Simulator game data setup passed"
        ((TESTS_PASSED++))
    else
        log_error "Simulator game data setup failed"
        ((TESTS_FAILED++))
        return 1
    fi
    
    # Launch and check for crash
    if launch_app_briefly "$SIM_UDID" "$APP_BUNDLE_ID"; then
        log_ok "App launch test passed"
        ((TESTS_PASSED++))
    else
        log_error "App launch test failed"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup: uninstall and shutdown
    log_info "Cleaning up simulator..."
    uninstall_app_from_simulator "$SIM_UDID" "$APP_BUNDLE_ID"
    
    if [[ "$SIM_WAS_BOOTED" == false ]]; then
        xcrun simctl shutdown "$SIM_UDID" 2>/dev/null || true
        log_ok "Simulator shut down"
    else
        log_info "Left pre-existing simulator running"
    fi
    
    # Verify no simulator processes left
    sleep 2
    local booted_count
    booted_count=$(get_booted_simulators | wc -l | tr -d ' ')
    
    if [[ "$SIM_WAS_BOOTED" == false ]]; then
        check "No simulators left running" "[[ $booted_count -eq 0 ]]"
    else
        log_info "Pre-existing simulator still running (as expected)"
    fi
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
print_summary() {
    log_section "Test Summary"
    
    local total=$((TESTS_PASSED + TESTS_FAILED))
    
    echo ""
    echo -e "    ${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "    ${RED}Failed:${NC}  $TESTS_FAILED"
    if [[ $TESTS_SKIPPED -gt 0 ]]; then
        echo -e "    ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    fi
    echo -e "    ${BOLD}Total:${NC}   $total"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}$TESTS_FAILED test(s) failed${NC}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    local do_build=false
    local skip_sim=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --build)
                do_build=true
                shift
                ;;
            --skip-sim)
                skip_sim=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
    
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║     Fallout 1 Rebirth — iOS Headless Tests                    ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Testing: $APP_BUNDLE"
    
    # Build if requested
    if [[ "$do_build" == true ]]; then
        build_for_simulator
    fi
    
    # Check if app exists
    if [[ ! -d "$APP_BUNDLE" ]]; then
        log_error "App bundle not found: $APP_BUNDLE"
        log_info "Run with --build to build first, or set BUILD_DIR"
        exit 1
    fi
    
    # Run bundle tests
    test_bundle_structure
    test_binary_architecture
    test_info_plist
    
    # Run simulator tests unless skipped
    if [[ "$skip_sim" == true ]]; then
        log_section "Simulator Tests: SKIPPED"
        log_info "Use without --skip-sim to run simulator tests"
    else
        test_simulator_launch
    fi
    
    # Print summary and exit with appropriate code
    if print_summary; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
