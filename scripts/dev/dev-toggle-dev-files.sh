#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — Development Files Toggle Script
# =============================================================================
# Toggles development files in .gitignore (journals, docs, game data, etc.)
# Run before pushing to hide dev files, run again to restore for development.
#
# USAGE:
#   ./scripts/dev/dev-toggle-dev-files.sh          # Toggle dev files ignore state
#   ./scripts/dev/dev-toggle-dev-files.sh --status # Show current state
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/../.."

GITIGNORE=".gitignore"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Files/folders to toggle (patterns as they appear in .gitignore)
# Format: "pattern" for matching in gitignore
PATTERNS=(
    "**/JOURNAL.md"
    "**/journal.md"
    "src/README.md"
    ".github/copilot-instructions.md"
    ".github/skills/"
    "development/"
    "scripts/dev/dev-toggle-dev-files.sh"
)

# Check if dev files are currently ignored (not commented out)
is_ignored() {
    # Returns 0 (true) if files ARE being ignored (lines are NOT commented)
    # Check for uncommented **/JOURNAL.md line as the indicator
    if grep -q "^\*\*/JOURNAL\.md$" "$GITIGNORE" 2>/dev/null; then
        return 0
    fi
    return 1
}

show_status() {
    if is_ignored; then
        log_warn "Development files are IGNORED (hidden from git)"
        echo "  Files: JOURNAL.md, src/README.md, copilot-instructions, skills/, development/, dev-toggle-dev-files.sh"
        echo "  Run ./scripts/dev/dev-toggle-dev-files.sh to track them again"
    else
        log_ok "Development files are TRACKED (visible in git)"
        echo "  Files: JOURNAL.md, src/README.md, copilot-instructions, skills/, development/, dev-toggle-dev-files.sh"
        echo "  Run ./scripts/dev/dev-toggle-dev-files.sh to ignore them before pushing"
    fi
}

# Escape pattern for sed (escape special regex chars)
escape_for_sed() {
    echo "$1" | sed 's/[.*\/]/\\&/g'
}

toggle_dev_files() {
    if is_ignored; then
        # Currently ignored -> comment out to track
        log_info "Commenting out dev file ignore rules..."
        
        for pattern in "${PATTERNS[@]}"; do
            escaped=$(escape_for_sed "$pattern")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|^${escaped}$|#${pattern}|" "$GITIGNORE"
            else
                sed -i "s|^${escaped}$|#${pattern}|" "$GITIGNORE"
            fi
        done
        
        log_ok "Development files are now TRACKED"
        echo "  JOURNAL.md, README.md, copilot-instructions, skills/, development/, dev-toggle-dev-files.sh"
        echo "  Run this script again before pushing to hide them"
    else
        # Currently tracked -> uncomment to ignore
        log_info "Uncommenting dev file ignore rules..."
        
        for pattern in "${PATTERNS[@]}"; do
            escaped=$(escape_for_sed "$pattern")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|^#${escaped}$|${pattern}|" "$GITIGNORE"
            else
                sed -i "s|^#${escaped}$|${pattern}|" "$GITIGNORE"
            fi
        done
        
        log_ok "Development files are now IGNORED"
        echo "  JOURNAL.md, README.md, copilot-instructions, skills/, development/, dev-toggle-dev-files.sh"
        echo "  Run this script again to track them for development"
    fi
}

# Main
case "${1:-}" in
    --status|-s)
        show_status
        ;;
    --help|-h)
        head -12 "$0" | tail -10
        ;;
    *)
        toggle_dev_files
        ;;
esac
