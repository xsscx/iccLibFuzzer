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

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Lint Workflow Diagnostic                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0

test_result() {
  local name="$1"
  local status="$2"
  
  if [ "$status" = "pass" ]; then
    echo -e "${GREEN}✅ PASS${NC}: $name"
    pass_count=$((pass_count + 1))
  else
    echo -e "${RED}❌ FAIL${NC}: $name"
    fail_count=$((fail_count + 1))
  fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Check Workflow File Exists"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

WORKFLOW_FILE="$REPO_ROOT/.github/workflows/ci-pr-lint.yml"
if [ -f "$WORKFLOW_FILE" ]; then
  test_result "Workflow file exists" "pass"
  echo "  Location: $WORKFLOW_FILE"
else
  test_result "Workflow file exists" "fail"
  echo "  Expected: $WORKFLOW_FILE"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Check Sanitizer Exists"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SANITIZER_FILE="$REPO_ROOT/.github/scripts/sanitize.sh"
if [ -f "$SANITIZER_FILE" ]; then
  test_result "Sanitizer file exists" "pass"
  echo "  Location: $SANITIZER_FILE"
else
  test_result "Sanitizer file exists" "fail"
  echo "  Expected: $SANITIZER_FILE"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: Load and Test Sanitizer Functions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$SANITIZER_FILE" ]; then
  # shellcheck disable=SC1090
  source "$SANITIZER_FILE"
  
  # Test sanitize_line function
  if declare -f sanitize_line > /dev/null; then
    test_result "sanitize_line function exists" "pass"
    
    # Test HTML escaping
    result=$(sanitize_line "<script>alert(1)</script>")
    expected="&lt;script&gt;alert(1)&lt;/script&gt;"
    
    if [ "$result" = "$expected" ]; then
      test_result "sanitize_line escapes HTML" "pass"
      echo "  Input:    <script>alert(1)</script>"
      echo "  Output:   $result"
    else
      test_result "sanitize_line escapes HTML" "fail"
      echo "  Input:    <script>alert(1)</script>"
      echo "  Expected: $expected"
      echo "  Got:      $result"
    fi
  else
    test_result "sanitize_line function exists" "fail"
  fi
else
  test_result "Load sanitizer" "fail"
  echo "  Cannot load sanitizer file"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: Check Process Substitution Syntax"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if workflow uses process substitution correctly
if grep -q "done < <(tail" "$WORKFLOW_FILE" 2>/dev/null; then
  test_result "Process substitution syntax found" "pass"
  echo "  Using: done < <(tail ...)"
else
  if grep -q "tail.*|.*while" "$WORKFLOW_FILE" 2>/dev/null; then
    test_result "Process substitution syntax found" "fail"
    echo "  ⚠️  Found pipe syntax: tail | while"
    echo "  Should use: done < <(tail ...)"
  else
    test_result "Process substitution syntax found" "pass"
    echo "  No sanitization loop found (may be OK)"
  fi
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 5: Test Process Substitution with Function"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$SANITIZER_FILE" ]; then
  # shellcheck disable=SC1090
  source "$SANITIZER_FILE"
  
  # Create test data
  TEST_FILE=$(mktemp)
  echo "<script>test1</script>" > "$TEST_FILE"
  echo "<img src=x>" >> "$TEST_FILE"
  
  # Test process substitution
  output=$(
    while IFS= read -r line; do
      sanitize_line "$line"
      echo ""
    done < <(cat "$TEST_FILE")
  )
  
  if echo "$output" | grep -q "&lt;script&gt;"; then
    test_result "Process substitution with sanitize_line" "pass"
    echo "  ✅ Functions work in process substitution"
  else
    test_result "Process substitution with sanitize_line" "fail"
    echo "  ❌ Function not available in loop"
  fi
  
  rm -f "$TEST_FILE"
else
  test_result "Process substitution with sanitize_line" "fail"
  echo "  Cannot test - sanitizer not loaded"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 6: Check Workflow YAML Syntax"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Basic YAML syntax check (requires Python)
if command -v python3 > /dev/null; then
  if python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" 2>/dev/null; then
    test_result "YAML syntax valid" "pass"
  else
    test_result "YAML syntax valid" "fail"
    echo "  Run: python3 -c \"import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))\""
  fi
else
  test_result "YAML syntax check" "pass"
  echo "  ⚠️  Python not available - skipping YAML validation"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 7: Check for Common Issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

issues_found=0

# Check for direct interpolation in run blocks
if grep -E 'run:.*\$\{\{.*github\.(head_ref|base_ref|actor).*\}\}' "$WORKFLOW_FILE" 2>/dev/null; then
  echo "  ❌ Found direct interpolation of user-controlled variables"
  issues_found=$((issues_found + 1))
fi

# Check for missing shell specification
if ! grep -q "shell: bash --noprofile --norc" "$WORKFLOW_FILE" 2>/dev/null; then
  echo "  ⚠️  Shell hardening not found (may be OK)"
fi

# Check for BASH_ENV
if ! grep -q "BASH_ENV: /dev/null" "$WORKFLOW_FILE" 2>/dev/null; then
  echo "  ⚠️  BASH_ENV not set to /dev/null (may be OK)"
fi

if [ $issues_found -eq 0 ]; then
  test_result "No common issues found" "pass"
else
  test_result "No common issues found" "fail"
  echo "  Found $issues_found potential issues"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "Tests Passed: ${GREEN}$pass_count${NC}"
echo -e "Tests Failed: ${RED}$fail_count${NC}"
echo ""

if [ $fail_count -eq 0 ]; then
  echo -e "${GREEN}✅ All diagnostic tests passed!${NC}"
  echo ""
  echo "If the lint workflow is still failing, the issue is likely:"
  echo "  1. Actual linting warnings in the code (working as intended)"
  echo "  2. Build failures (cmake/make errors)"
  echo "  3. Missing dependencies in the runner"
  echo ""
  echo "Check the GitHub Actions logs for specific error messages."
  exit 0
else
  echo -e "${RED}❌ Some diagnostic tests failed${NC}"
  echo ""
  echo "Fix the issues above and try again."
  exit 1
fi
