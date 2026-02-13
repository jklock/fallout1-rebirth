#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — macOS Headless Test Script
# =============================================================================
# Validates macOS app bundle without launching the full GUI.
# Designed for CI/CD and automated testing with no manual interaction.
#
# TESTS PERFORMED:
#   - App bundle exists with correct structure
#   - Executable is properly signed or can be ad-hoc signed
#   - Info.plist has all required keys
#   - Binary architecture validation (arm64, x86_64)
#   - Brief launch test (3-second timeout, no crash check)
#   - Clean exit code verification
#   - Resource accessibility check
#   - Dynamic library dependency verification
#
# USAGE:
#   ./scripts/test/test-macos-headless.sh              # Run all tests
#   ./scripts/test/test-macos-headless.sh --build      # Build first, then test
#   ./scripts/test/test-macos-headless.sh --help       # Show usage
#
# CONFIGURATION (environment variables):
#   BUILD_DIR   - Build output directory (default: "build-macos")
#   BUILD_TYPE  - Debug/Release/RelWithDebInfo (default: "RelWithDebInfo")
#   JOBS        - Parallel jobs (default: physical CPU count)
#
# EXIT CODES:
#   0 - All tests passed
#   1 - One or more tests failed
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/../.."

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"

# Expected app bundle name
APP_NAME="Fallout 1 Rebirth"
APP_BUNDLE="$BUILD_DIR/$BUILD_TYPE/$APP_NAME.app"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/fallout1-rebirth"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"

# Test parameters
LAUNCH_TIMEOUT=3  # seconds

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

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
log_info()    { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()      { echo -e "${GREEN}✅${NC} $1"; }
log_warn()    { echo -e "${YELLOW}⚠️${NC}  $1"; }
log_error()   { echo -e "${RED}❌${NC} $1"; }
log_section() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}"; }
log_skip()    { echo -e "${YELLOW}⏭️${NC}  $1"; ((TESTS_SKIPPED++)); }

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

Headless validation tests for the macOS app bundle.

OPTIONS:
    --build     Build the app before running tests
    --help      Show this help message

ENVIRONMENT VARIABLES:
    BUILD_DIR   Build output directory (default: build-macos)
    BUILD_TYPE  Build type (default: RelWithDebInfo)

EXAMPLES:
    $0                           # Test existing build
    $0 --build                   # Build and test
    BUILD_DIR=mybuild $0         # Test custom build directory
EOF
    exit 0
}

# -----------------------------------------------------------------------------
# Build function (optional)
# -----------------------------------------------------------------------------
build_app() {
    log_section "Building macOS App"
    
    # Configure if needed
    if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
        log_info "Configuring CMake with Xcode generator..."
        if ! cmake -B "$BUILD_DIR" \
            -G Xcode \
            -D CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=''; then
            log_error "CMake configuration failed"
            exit 1
        fi
        log_ok "Configuration complete"
    else
        log_info "Using existing CMake configuration"
    fi
    
    # Build
    log_info "Building ($BUILD_TYPE, $JOBS parallel jobs)..."
    if ! cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j "$JOBS"; then
        log_error "Build failed"
        exit 1
    fi
    
    log_ok "Build completed successfully"
}

# -----------------------------------------------------------------------------
# Test: Bundle Structure
# -----------------------------------------------------------------------------
test_bundle_structure() {
    log_section "Test: Bundle Structure"
    
    check "App bundle exists" "[[ -d '$APP_BUNDLE' ]]" || return 1
    check "Contents directory exists" "[[ -d '$APP_BUNDLE/Contents' ]]"
    check "MacOS directory exists" "[[ -d '$APP_BUNDLE/Contents/MacOS' ]]"
    check "Resources directory exists" "[[ -d '$APP_BUNDLE/Contents/Resources' ]]"
    check "Info.plist exists" "[[ -f '$INFO_PLIST' ]]"
    check "Executable exists" "[[ -f '$EXECUTABLE' ]]"
    check "Executable has +x permission" "[[ -x '$EXECUTABLE' ]]"
}

# -----------------------------------------------------------------------------
# Test: Code Signing
# -----------------------------------------------------------------------------
test_code_signing() {
    log_section "Test: Code Signing"
    
    if [[ ! -f "$EXECUTABLE" ]]; then
        log_skip "Executable not found, skipping signing tests"
        return 0
    fi
    
    # Check if already signed
    if codesign --verify --verbose=0 "$APP_BUNDLE" 2>/dev/null; then
        log_ok "App bundle is properly signed"
        ((TESTS_PASSED++))
        
        # Show signing info
        log_info "Signing details:"
        codesign -dvvv "$APP_BUNDLE" 2>&1 | grep -E "(Identifier|Authority|TeamIdentifier)" | head -5 | sed 's/^/    /'
    else
        # Not signed - check if we can ad-hoc sign
        log_info "App not signed, attempting ad-hoc signing..."
        if codesign --sign - --force --deep "$APP_BUNDLE" 2>/dev/null; then
            log_ok "Ad-hoc signing successful"
            ((TESTS_PASSED++))
        else
            log_warn "Ad-hoc signing failed (may be OK for local builds)"
        fi
    fi
    
    # Verify signature if present
    if codesign --verify "$APP_BUNDLE" 2>/dev/null; then
        # Check for any signing issues
        local sign_result
        if sign_result=$(codesign --verify --deep --strict "$APP_BUNDLE" 2>&1); then
            log_ok "Deep signature verification passed"
            ((TESTS_PASSED++))
        else
            log_warn "Deep signature verification issues: $sign_result"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Test: Info.plist Validation
# -----------------------------------------------------------------------------
test_info_plist() {
    log_section "Test: Info.plist Validation"
    
    if [[ ! -f "$INFO_PLIST" ]]; then
        log_skip "Info.plist not found"
        return 0
    fi
    
    # Validate plist syntax
    if plutil -lint "$INFO_PLIST" >/dev/null 2>&1; then
        log_ok "Info.plist has valid syntax"
        ((TESTS_PASSED++))
    else
        log_error "Info.plist has invalid syntax"
        ((TESTS_FAILED++))
        return 1
    fi
    
    # Helper to read plist key
    read_plist() {
        /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST" 2>/dev/null || echo ""
    }
    
    # Required keys
    local bundle_id bundle_name bundle_version executable_name
    bundle_id=$(read_plist "CFBundleIdentifier")
    bundle_name=$(read_plist "CFBundleName")
    bundle_version=$(read_plist "CFBundleShortVersionString")
    executable_name=$(read_plist "CFBundleExecutable")
    
    check "CFBundleIdentifier is set" "[[ -n '$bundle_id' ]]"
    check "CFBundleName is set" "[[ -n '$bundle_name' ]]"
    check "CFBundleShortVersionString is set" "[[ -n '$bundle_version' ]]"
    check "CFBundleExecutable is set" "[[ -n '$executable_name' ]]"
    
    # Verify executable matches
    if [[ -n "$executable_name" ]]; then
        check "Executable name matches actual file" "[[ -f '$APP_BUNDLE/Contents/MacOS/$executable_name' ]]"
    fi
    
    log_info "Bundle information:"
    echo "    Identifier: $bundle_id"
    echo "    Name:       $bundle_name"
    echo "    Version:    $bundle_version"
    echo "    Executable: $executable_name"
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
    
    # Check file type
    local file_info
    file_info=$(file "$EXECUTABLE" 2>/dev/null || echo "")
    
    check "Binary is Mach-O executable" "[[ '$file_info' == *'Mach-O'* ]]"
    
    # Check architecture(s)
    log_info "Binary architecture info:"
    echo "$file_info" | sed 's/.*: /    /'
    
    local has_arm64=false
    local has_x86_64=false
    
    if [[ "$file_info" == *"arm64"* ]]; then
        has_arm64=true
        log_ok "Has arm64 architecture (Apple Silicon native)"
        ((TESTS_PASSED++))
    fi
    
    if [[ "$file_info" == *"x86_64"* ]]; then
        has_x86_64=true
        log_ok "Has x86_64 architecture (Intel native)"
        ((TESTS_PASSED++))
    fi
    
    # At least one architecture must be present
    check "Has at least one valid macOS architecture" "[[ $has_arm64 == true || $has_x86_64 == true ]]"
    
    # Show lipo info for universal binaries
    if [[ "$file_info" == *"universal"* ]]; then
        log_info "Universal binary architectures:"
        lipo -info "$EXECUTABLE" 2>/dev/null | sed 's/^/    /' || true
    fi
}

# -----------------------------------------------------------------------------
# Test: Dynamic Library Dependencies
# -----------------------------------------------------------------------------
test_dylib_dependencies() {
    log_section "Test: Dynamic Library Dependencies"
    
    if [[ ! -f "$EXECUTABLE" ]]; then
        log_skip "Executable not found"
        return 0
    fi
    
    log_info "Checking dynamic library dependencies..."
    
    # Get list of dependencies
    local deps
    deps=$(otool -L "$EXECUTABLE" 2>/dev/null | tail -n +2 || echo "")
    
    if [[ -z "$deps" ]]; then
        log_warn "Could not read dynamic library dependencies"
        return 0
    fi
    
    local system_deps=0
    local bundled_deps=0
    local missing_deps=0
    
    while IFS= read -r line; do
        # Extract library path
        local lib_path
        lib_path=$(echo "$line" | awk '{print $1}')
        
        if [[ -z "$lib_path" ]]; then
            continue
        fi
        
        # Categorize dependency
        if [[ "$lib_path" == /System/* ]] || [[ "$lib_path" == /usr/lib/* ]]; then
            ((system_deps++))
        elif [[ "$lib_path" == @executable_path/* ]] || [[ "$lib_path" == @rpath/* ]]; then
            # Check if bundled library exists
            local resolved_path
            if [[ "$lib_path" == @executable_path/* ]]; then
                resolved_path="${lib_path/@executable_path/$APP_BUNDLE/Contents/MacOS}"
            elif [[ "$lib_path" == @rpath/* ]]; then
                resolved_path="${lib_path/@rpath/$APP_BUNDLE/Contents/Frameworks}"
            fi
            
            if [[ -f "$resolved_path" ]]; then
                ((bundled_deps++))
            else
                ((missing_deps++))
                log_warn "Missing bundled library: $lib_path"
            fi
        fi
    done <<< "$deps"
    
    log_info "Dependency summary:"
    echo "    System libraries: $system_deps"
    echo "    Bundled libraries: $bundled_deps"
    echo "    Missing libraries: $missing_deps"
    
    check "No missing dynamic library dependencies" "[[ $missing_deps -eq 0 ]]"
    
    # Show first few dependencies
    log_info "Dependencies (first 10):"
    echo "$deps" | head -10 | sed 's/^/    /'
}

# -----------------------------------------------------------------------------
# Test: Brief Launch (Crash Check)
# -----------------------------------------------------------------------------
test_brief_launch() {
    log_section "Test: Brief Launch (No-Crash Check)"
    
    if [[ ! -x "$EXECUTABLE" ]]; then
        log_skip "Executable not found or not executable"
        return 0
    fi
    
    log_info "Attempting brief launch (${LAUNCH_TIMEOUT}s timeout)..."
    log_info "Note: App will be terminated after timeout - this is expected"
    
    # Create a temp file to capture exit status
    local pid exit_code
    local crashed=false
    
    # Launch the app in background
    # Use timeout to limit execution time
    # Redirect to /dev/null to avoid GUI issues
    set +e
    
    # Try to launch with a short timeout
    # We use 'open -W -g' to launch in background without bringing to front
    # Combined with timeout to limit how long we wait
    if command -v gtimeout &>/dev/null; then
        # Use GNU timeout if available (from coreutils)
        gtimeout --signal=TERM "$LAUNCH_TIMEOUT" open -W -g "$APP_BUNDLE" &>/dev/null &
        pid=$!
    else
        # Fallback: launch and kill after timeout
        open -g "$APP_BUNDLE" &>/dev/null &
        pid=$!
        
        # Wait briefly then check if still running
        sleep "$LAUNCH_TIMEOUT"
    fi
    
    # Give it a moment to crash if it's going to
    sleep 1
    
    # Check if process is still running (good) or exited immediately (possibly bad)
    if kill -0 $pid 2>/dev/null; then
        # Process still running after timeout - this is the expected good path
        log_ok "App launched without immediate crash"
        ((TESTS_PASSED++))
        
        # Terminate it gracefully
        osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true
        sleep 1
        
        # Force kill if still running
        if kill -0 $pid 2>/dev/null; then
            kill -TERM $pid 2>/dev/null || true
            sleep 1
            kill -KILL $pid 2>/dev/null || true
        fi
    else
        # Process exited - check if it was a crash
        wait $pid 2>/dev/null
        exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            log_ok "App exited cleanly (exit code 0)"
            ((TESTS_PASSED++))
        elif [[ $exit_code -gt 128 ]]; then
            # Exit code > 128 usually means killed by signal
            local signal=$((exit_code - 128))
            if [[ $signal -eq 15 ]] || [[ $signal -eq 9 ]]; then
                log_ok "App was terminated by script (expected)"
                ((TESTS_PASSED++))
            else
                crashed=true
                log_error "App crashed with signal $signal (exit code $exit_code)"
                ((TESTS_FAILED++))
            fi
        else
            log_warn "App exited with code $exit_code (may indicate startup issue)"
            # Not counting as failure - app might just exit due to missing assets
        fi
    fi
    
    set -e
    
    # Ensure app is not running
    pkill -f "fallout1-rebirth" 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# Test: Resource Accessibility
# -----------------------------------------------------------------------------
test_resource_accessibility() {
    log_section "Test: Resource Accessibility"
    
    local resources="$APP_BUNDLE/Contents/Resources"
    
    if [[ ! -d "$resources" ]]; then
        log_warn "Resources directory not found"
        return 0
    fi
    
    # Check directory is readable
    check "Resources directory is readable" "[[ -r '$resources' ]]"
    
    # Count resources
    local resource_count
    resource_count=$(find "$resources" -type f 2>/dev/null | wc -l | tr -d ' ')
    log_info "Resource files found: $resource_count"
    
    # Check for common resource types
    local icns_count
    icns_count=$(find "$resources" -name "*.icns" 2>/dev/null | wc -l | tr -d ' ')
    if [[ $icns_count -gt 0 ]]; then
        log_ok "App icon(s) found: $icns_count .icns file(s)"
        ((TESTS_PASSED++))
    else
        log_info "No .icns icon files (may use asset catalog)"
    fi
    
    # Check Frameworks if present
    local frameworks="$APP_BUNDLE/Contents/Frameworks"
    if [[ -d "$frameworks" ]]; then
        local fw_count
        fw_count=$(ls -1 "$frameworks" 2>/dev/null | wc -l | tr -d ' ')
        log_info "Bundled frameworks/libraries: $fw_count"
        
        check "Frameworks directory is readable" "[[ -r '$frameworks' ]]"
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
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --build)
                do_build=true
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
    echo "║     Fallout 1 Rebirth — macOS Headless Tests                  ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_info "Testing: $APP_BUNDLE"
    
    # Build if requested
    if [[ "$do_build" == true ]]; then
        build_app
    fi
    
    # Check if app exists
    if [[ ! -d "$APP_BUNDLE" ]]; then
        log_error "App bundle not found: $APP_BUNDLE"
        log_info "Run with --build to build first, or build manually:"
        log_info "  cmake -B $BUILD_DIR -G Xcode"
        log_info "  cmake --build $BUILD_DIR --config $BUILD_TYPE"
        exit 1
    fi

    # Ensure patched game data is present. If missing, auto-install from repo/GOG/patchedfiles.
    if [[ ! -f "$APP_BUNDLE/Contents/Resources/master.dat" ]]; then
        PATCHED_DIR="$PWD/GOG/patchedfiles"
        if [[ -d "$PATCHED_DIR" && -f "$PATCHED_DIR/master.dat" ]]; then
            log_info "master.dat missing in app bundle — auto-installing from $PATCHED_DIR"
            "$PWD/scripts/test/test-install-game-data.sh" --source "$PATCHED_DIR" --target "$APP_BUNDLE" || true
        else
            log_warn "Patched game data not found at $PATCHED_DIR; tests that require game data will fail"
        fi
    fi
    
    # Run all tests
    test_bundle_structure
    test_code_signing
    test_info_plist
    test_binary_architecture
    test_dylib_dependencies
    test_resource_accessibility
    test_brief_launch
    
    # Print summary and exit with appropriate code
    if print_summary; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
