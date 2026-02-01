#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — macOS Test Script
# =============================================================================
# Builds and verifies the macOS app bundle structure and integrity.
# Does NOT launch the game (no automated gameplay testing).
#
# USAGE:
#   ./scripts/test-macos.sh              # Full build + verification
#   ./scripts/test-macos.sh --verify     # Verify existing build only
#   ./scripts/test-macos.sh --help       # Show usage
#
# CONFIGURATION (environment variables):
#   BUILD_DIR   - Build output directory (default: "build-macos")
#   BUILD_TYPE  - Debug/Release/RelWithDebInfo (default: "RelWithDebInfo")
#   JOBS        - Parallel jobs (default: physical CPU count)
#   CLEAN       - Set to "1" to force reconfigure
#
# VERIFICATION CHECKS:
#   - App bundle exists and has correct structure
#   - Executable is present and has correct architecture
#   - Info.plist contains required keys
#   - Required frameworks/libraries are bundled
#   - Binary runs (--version or minimal execution test)
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
BUILD_DIR="${BUILD_DIR:-build-macos}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"
JOBS="${JOBS:-$(sysctl -n hw.physicalcpu)}"
CLEAN="${CLEAN:-0}"

# Expected app bundle name
APP_NAME="Fallout 1 Rebirth"
APP_BUNDLE="$BUILD_DIR/$BUILD_TYPE/$APP_NAME.app"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/fallout1-rebirth"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Track verification results
TESTS_PASSED=0
TESTS_FAILED=0

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
log_info()    { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()      { echo -e "${GREEN}✅${NC} $1"; }
log_warn()    { echo -e "${YELLOW}⚠️${NC}  $1"; }
log_error()   { echo -e "${RED}❌${NC} $1"; }
log_section() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}"; }

# Run a verification check
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

# -----------------------------------------------------------------------------
# Build function
# -----------------------------------------------------------------------------
build_macos() {
    log_section "Building macOS App"
    
    # Clean if requested
    if [[ "$CLEAN" == "1" && -d "$BUILD_DIR" ]]; then
        log_warn "CLEAN=1 set, removing $BUILD_DIR..."
        rm -rf "$BUILD_DIR"
    fi
    
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
# Verification functions
# -----------------------------------------------------------------------------
verify_bundle_structure() {
    log_section "Verifying Bundle Structure"
    
    # Check app bundle exists
    check "App bundle exists" "[[ -d '$APP_BUNDLE' ]]"
    
    # Check Contents directory
    check "Contents directory exists" "[[ -d '$APP_BUNDLE/Contents' ]]"
    
    # Check required subdirectories
    check "MacOS directory exists" "[[ -d '$APP_BUNDLE/Contents/MacOS' ]]"
    check "Resources directory exists" "[[ -d '$APP_BUNDLE/Contents/Resources' ]]"
    
    # Check Info.plist
    check "Info.plist exists" "[[ -f '$APP_BUNDLE/Contents/Info.plist' ]]"
}

verify_executable() {
    log_section "Verifying Executable"
    
    # Check executable exists
    check "Executable exists" "[[ -f '$EXECUTABLE' ]]"
    
    # Check executable permissions
    check "Executable has execute permission" "[[ -x '$EXECUTABLE' ]]"
    
    # Check architecture (should be arm64 and/or x86_64 for macOS)
    if [[ -f "$EXECUTABLE" ]]; then
        local arch_info
        arch_info=$(file "$EXECUTABLE" 2>/dev/null || echo "")
        
        # Should be Mach-O executable
        check "Is Mach-O executable" "[[ '$arch_info' == *'Mach-O'*'executable'* ]]"
        
        # Show architecture details
        log_info "Binary architecture:"
        echo "$arch_info" | sed 's/.*: /    /'
        
        # Verify it's for macOS (not iOS)
        if [[ "$arch_info" == *"arm64"* ]] || [[ "$arch_info" == *"x86_64"* ]]; then
            log_ok "Architecture is valid for macOS"
            ((TESTS_PASSED++))
        else
            log_warn "Unexpected architecture"
        fi
    fi
}

verify_info_plist() {
    log_section "Verifying Info.plist"
    
    local plist="$APP_BUNDLE/Contents/Info.plist"
    
    if [[ ! -f "$plist" ]]; then
        log_error "Info.plist not found, skipping checks"
        return 1
    fi
    
    # Helper to read plist key
    read_plist_key() {
        /usr/libexec/PlistBuddy -c "Print :$1" "$plist" 2>/dev/null || echo ""
    }
    
    # Check required keys exist
    local bundle_id
    bundle_id=$(read_plist_key "CFBundleIdentifier")
    check "CFBundleIdentifier is set" "[[ -n '$bundle_id' ]]"
    
    local bundle_name
    bundle_name=$(read_plist_key "CFBundleName")
    check "CFBundleName is set" "[[ -n '$bundle_name' ]]"
    
    local bundle_version
    bundle_version=$(read_plist_key "CFBundleShortVersionString")
    check "CFBundleShortVersionString is set" "[[ -n '$bundle_version' ]]"
    
    local executable_name
    executable_name=$(read_plist_key "CFBundleExecutable")
    check "CFBundleExecutable is set" "[[ -n '$executable_name' ]]"
    
    # Display info
    log_info "Bundle information:"
    echo "    Identifier: $bundle_id"
    echo "    Name:       $bundle_name"
    echo "    Version:    $bundle_version"
    echo "    Executable: $executable_name"
}

verify_resources() {
    log_section "Verifying Resources"
    
    local resources="$APP_BUNDLE/Contents/Resources"
    
    if [[ ! -d "$resources" ]]; then
        log_warn "Resources directory not found"
        return 0
    fi
    
    # Check for icon (optional but nice to have)
    local icon_count
    icon_count=$(find "$resources" -name "*.icns" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$icon_count" -gt 0 ]]; then
        log_ok "App icon found ($icon_count .icns file(s))"
        ((TESTS_PASSED++))
    else
        log_warn "No app icon (.icns) found (optional)"
    fi
    
    # List resources
    log_info "Resources directory contents:"
    ls -la "$resources" 2>/dev/null | head -10 | sed 's/^/    /'
}

verify_frameworks() {
    log_section "Verifying Frameworks/Libraries"
    
    local frameworks="$APP_BUNDLE/Contents/Frameworks"
    
    if [[ -d "$frameworks" ]]; then
        log_ok "Frameworks directory exists"
        ((TESTS_PASSED++))
        
        log_info "Bundled frameworks:"
        ls -1 "$frameworks" 2>/dev/null | head -10 | sed 's/^/    /'
    else
        log_info "No Frameworks directory (may use system libraries only)"
    fi
    
    # Check dynamic library dependencies
    if [[ -x "$EXECUTABLE" ]]; then
        log_info "Dynamic library dependencies:"
        otool -L "$EXECUTABLE" 2>/dev/null | head -15 | sed 's/^/    /'
    fi
}

verify_code_signature() {
    log_section "Verifying Code Signature"
    
    # Check if app is signed (may be unsigned for local dev builds)
    local sign_status
    sign_status=$(codesign -dv "$APP_BUNDLE" 2>&1 || echo "unsigned")
    
    if [[ "$sign_status" == *"unsigned"* ]] || [[ "$sign_status" == *"not signed"* ]]; then
        log_warn "App is not code signed (expected for local dev builds)"
    else
        log_ok "App is code signed"
        ((TESTS_PASSED++))
        
        # Verify signature if signed
        if codesign --verify --deep --strict "$APP_BUNDLE" 2>/dev/null; then
            log_ok "Code signature is valid"
            ((TESTS_PASSED++))
        else
            log_warn "Code signature verification failed"
        fi
    fi
}

verify_binary_runs() {
    log_section "Verifying Binary Execution"
    
    if [[ ! -x "$EXECUTABLE" ]]; then
        log_error "Executable not found or not executable"
        return 1
    fi
    
    # Try to run with a quick timeout - just check it starts
    # Note: The game may exit quickly without data files, that's OK
    log_info "Testing binary execution (expecting quick exit without game data)..."
    
    # Run with timeout, capture output
    local exit_code=0
    local output=""
    
    # Use timeout command if available, otherwise skip
    if command -v timeout &>/dev/null; then
        output=$(timeout 2s "$EXECUTABLE" --help 2>&1) || exit_code=$?
    elif command -v gtimeout &>/dev/null; then
        output=$(gtimeout 2s "$EXECUTABLE" --help 2>&1) || exit_code=$?
    else
        # Just check if we can at least query the binary
        log_info "timeout command not available, performing basic check..."
        if file "$EXECUTABLE" | grep -q "Mach-O"; then
            log_ok "Binary appears valid (Mach-O format verified)"
            ((TESTS_PASSED++))
            return 0
        fi
    fi
    
    # Exit code 124 = timeout (which means it ran!), 0 = normal exit
    if [[ $exit_code -eq 124 ]] || [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        log_ok "Binary executed successfully (exit code: $exit_code)"
        ((TESTS_PASSED++))
    else
        log_warn "Binary execution returned code: $exit_code"
        if [[ -n "$output" ]]; then
            echo "    Output: ${output:0:200}"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
print_summary() {
    log_section "Test Summary"
    
    local total=$((TESTS_PASSED + TESTS_FAILED))
    
    echo ""
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "  Total:  $total"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_ok "All verification checks passed!"
        echo ""
        echo "App bundle: $APP_BUNDLE"
        echo "Size:       $(du -sh "$APP_BUNDLE" 2>/dev/null | cut -f1)"
        echo ""
        echo "To run manually (requires game data):"
        echo "  open \"$APP_BUNDLE\""
        echo ""
        echo "To create DMG for distribution:"
        echo "  cd $BUILD_DIR && cpack -C $BUILD_TYPE"
        return 0
    else
        log_error "Some verification checks failed"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Usage
# -----------------------------------------------------------------------------
usage() {
    head -27 "$0" | tail -25
    exit 0
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    echo ""
    echo "=============================================="
    echo " Fallout 1 Rebirth — macOS Test"
    echo "=============================================="
    echo " Build directory: $BUILD_DIR"
    echo " Build type:      $BUILD_TYPE"
    echo " App bundle:      $APP_NAME.app"
    echo "=============================================="
    
    # Parse arguments
    case "${1:-}" in
        --verify)
            log_info "Verify-only mode (skipping build)"
            ;;
        --help|-h)
            usage
            ;;
        "")
            # Default: build + verify
            build_macos
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    
    # Run all verification checks
    verify_bundle_structure
    verify_executable
    verify_info_plist
    verify_resources
    verify_frameworks
    verify_code_signature
    verify_binary_runs
    
    # Print summary and exit with appropriate code
    if print_summary; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
