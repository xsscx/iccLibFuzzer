#!/bin/bash
###############################################################
#
# Copyright (©) 2025 International Color Consortium. 
#                 All rights reserved. 
#                 https://color.org
#
# Quick Manual Test Script for newest-sanitizer.sh
# 
# Usage: ./quick-test-sanitizer.sh
#
###############################################################

set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source the sanitizer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/newest-sanitizer.sh"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Quick Manual Test - newest-sanitizer.sh                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Counter
PASSED=0
FAILED=0

# Test helper
run_test() {
  local name="$1"
  local input="$2"
  local expected="$3"
  local result
  
  result=$(sanitize_line "$input")
  
  echo -e "${BLUE}Test:${NC} $name"
  echo "  Input:    $input"
  echo "  Expected: $expected"
  echo "  Result:   $result"
  
  if [[ "$result" == "$expected" ]]; then
    echo -e "  ${GREEN}✓ PASS${NC}"
    ((PASSED++))
  else
    echo -e "  ${RED}✗ FAIL${NC}"
    ((FAILED++))
  fi
  echo ""
}

# Run Tests
echo -e "${YELLOW}=== Basic XSS Tests ===${NC}"
echo ""

run_test "Script tag" \
  '<script>alert(1)</script>' \
  '&lt;script&gt;alert(1)&lt;/script&gt;'

run_test "IMG onerror" \
  '<img src=x onerror=alert(1)>' \
  '&lt;img src=x onerror=alert(1)&gt;'

run_test "SVG onload" \
  '<svg onload=alert(1)>' \
  '&lt;svg onload=alert(1)&gt;'

echo -e "${YELLOW}=== Special Characters ===${NC}"
echo ""

run_test "Ampersand" \
  'Build & Deploy' \
  'Build &amp; Deploy'

run_test "Quotes" \
  'Say "hello" to the world' \
  'Say &quot;hello&quot; to the world'

echo -e "${YELLOW}=== Ref/Filename Tests ===${NC}"
echo ""

echo -e "${BLUE}Test:${NC} Branch name sanitization"
result=$(sanitize_ref "feature/PR#123:bug-fix")
echo "  Input:  feature/PR#123:bug-fix"
echo "  Result: $result"
if [[ "$result" == "feature/PR-123-bug-fix" ]]; then
  echo -e "  ${GREEN}✓ PASS${NC}"
  ((PASSED++))
else
  echo -e "  ${RED}✗ FAIL${NC}"
  ((FAILED++))
fi
echo ""

echo -e "${BLUE}Test:${NC} Filename with slashes"
result=$(sanitize_filename "path/to/file.txt")
echo "  Input:  path/to/file.txt"
echo "  Result: $result"
if [[ "$result" == "path_to_file.txt" ]]; then
  echo -e "  ${GREEN}✓ PASS${NC}"
  ((PASSED++))
else
  echo -e "  ${RED}✗ FAIL${NC}"
  ((FAILED++))
fi
echo ""

# Summary
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Test Summary                                            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Total Tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [[ $FAILED -gt 0 ]]; then
  echo -e "${RED}Failed: $FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
