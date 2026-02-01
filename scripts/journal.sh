#!/usr/bin/env bash
# =============================================================================
# Fallout 1 Rebirth — Journal Toggle Script
# =============================================================================
# Toggles JOURNAL.md and src/README.md entries in .gitignore
# Run before pushing to hide journal files, run again to restore for development.
#
# USAGE:
#   ./scripts/journal.sh          # Toggle journal ignore state
#   ./scripts/journal.sh --status # Show current state
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

GITIGNORE=".gitignore"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}>>>${NC} $1"; }
log_ok()    { echo -e "${GREEN}✅${NC} $1"; }
log_warn()  { echo -e "${YELLOW}⚠️${NC}  $1"; }

# Check if journals are currently ignored (not commented out)
is_ignored() {
    # Returns 0 (true) if journals ARE being ignored (lines are NOT commented)
    # Check for uncommented **/JOURNAL.md line
    if grep -q "^\*\*/JOURNAL\.md$" "$GITIGNORE" 2>/dev/null; then
        return 0
    fi
    return 1
}

show_status() {
    if is_ignored; then
        log_warn "Journal files are IGNORED (hidden from git)"
        echo "  Run ./scripts/journal.sh to track them again"
    else
        log_ok "Journal files are TRACKED (visible in git)"
        echo "  Run ./scripts/journal.sh to ignore them before pushing"
    fi
}

toggle_journals() {
    if is_ignored; then
        # Currently ignored -> comment out to track
        log_info "Commenting out journal ignore rules..."
        
        # Use sed to add # before the journal lines
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS sed requires empty string for -i
            sed -i '' 's|^\*\*/JOURNAL\.md$|#**/JOURNAL.md|' "$GITIGNORE"
            sed -i '' 's|^src/README\.md$|#src/README.md|' "$GITIGNORE"
        else
            sed -i 's|^\*\*/JOURNAL\.md$|#**/JOURNAL.md|' "$GITIGNORE"
            sed -i 's|^src/README\.md$|#src/README.md|' "$GITIGNORE"
        fi
        
        log_ok "Journal files are now TRACKED"
        echo "  JOURNAL.md files will appear in git status"
        echo "  Run this script again before pushing to hide them"
    else
        # Currently tracked -> uncomment to ignore
        log_info "Uncommenting journal ignore rules..."
        
        # Use sed to remove # from the journal lines
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's|^#\*\*/JOURNAL\.md$|**/JOURNAL.md|' "$GITIGNORE"
            sed -i '' 's|^#src/README\.md$|src/README.md|' "$GITIGNORE"
        else
            sed -i 's|^#\*\*/JOURNAL\.md$|**/JOURNAL.md|' "$GITIGNORE"
            sed -i 's|^#src/README\.md$|src/README.md|' "$GITIGNORE"
        fi
        
        log_ok "Journal files are now IGNORED"
        echo "  JOURNAL.md files will be hidden from git"
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
        toggle_journals
        ;;
esac
