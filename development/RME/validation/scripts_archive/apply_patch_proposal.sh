#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 ISSUE-ID OVERLAY_DIR [branch-prefix]"
  echo "Example: $0 ISSUE-CASE-001 GOG/validation/overlay_casefix"
  exit 1
fi
ISSUE=$1
OVERLAY=$2
BRPREFIX=${3:-fix}
BRANCH="$BRPREFIX/$ISSUE"
TARGET_DIR="data_fixes/${ISSUE}"

echo "Creating branch: $BRANCH" 

git checkout -b "$BRANCH"

mkdir -p "$TARGET_DIR"
cp -a "$OVERLAY/"* "$TARGET_DIR/" || true

git add "$TARGET_DIR"
git commit -m "$ISSUE: add overlay fixes (auto-generated placeholder)"

echo "Run local checks (format + verify):"
echo "  ./scripts/dev/dev-check.sh"
echo "  ./scripts/dev/dev-verify.sh"

echo "When ready, push branch and open a PR:"
echo "  git push -u origin $BRANCH"
echo "  gh pr create --fill --title \"$ISSUE: patch fixes\" --body \"See GOG/validation/ for verification artifacts and `GOG/validation/LLM_fix_mapping.md` for fix rationale.\""

echo "Done. Please manually inspect files under $TARGET_DIR and run the verification scripts before opening the PR."
