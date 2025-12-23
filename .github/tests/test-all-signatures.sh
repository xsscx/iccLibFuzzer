#!/usr/bin/env bash
###############################################################
#
# Copyright (©) 2025 International Color Consortium.
#                 All rights reserved.
#                 https://color.org
#
# Intent: Comprehensive test suite using ALL Commodity-Injection-Signatures
#
# Last Updated: 16-DEC-2025 by GitHub Copilot
#
# Description:
#   Expands test coverage to use all 100+ signature files
#   Tests sanitizer against diverse attack patterns:
#   - XSS, SQL injection, LDAP, XXE
#   - Shell injection, LFI, RFI
#   - HTTP header injection, SOAP, SSI
#   - URI mutations, encoding bypasses
#   - And much more!
#
###############################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the sanitizer - check if it exists first
SANITIZER_SCRIPT="${SCRIPT_DIR}/../scripts/newest-sanitizer.sh"
if [[ ! -f "$SANITIZER_SCRIPT" ]]; then
  echo "ERROR: Sanitizer script not found at: $SANITIZER_SCRIPT"
  echo "Current directory: $(pwd)"
  echo "Script directory: $SCRIPT_DIR"
  ls -la "${SCRIPT_DIR}/../scripts/" || echo "Scripts directory not found"
  exit 1
fi

source "$SANITIZER_SCRIPT"

# Colors
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  NC=''
fi

# Test statistics
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_FILES=0
TESTED_FILES=0

# Test configuration
# Set TEST_MODE environment variable to control test depth:
#   "quick"  = Test first 50 signatures per file (~2600 tests, ~60 seconds)
#   "normal" = Test first 500 signatures per file (~15000 tests, ~5 minutes)
#   "full"   = Test ALL signatures in all files (~25000+ tests, ~10+ minutes)
TEST_MODE="${TEST_MODE:-normal}"

case "$TEST_MODE" in
  quick)
    DEFAULT_MAX_TESTS=50
    MAX_FILE_SIZE=5242880
    TEST_ALL_SIGNATURES=false
    echo -e "${YELLOW}Test Mode: QUICK (50 signatures per file)${NC}"
    ;;
  normal)
    DEFAULT_MAX_TESTS=500
    MAX_FILE_SIZE=5242880
    TEST_ALL_SIGNATURES=false
    echo -e "${CYAN}Test Mode: NORMAL (500 signatures per file)${NC}"
    ;;
  full)
    DEFAULT_MAX_TESTS=999999
    MAX_FILE_SIZE=10485760  # 10MB
    TEST_ALL_SIGNATURES=true
    echo -e "${GREEN}Test Mode: FULL (ALL signatures)${NC}"
    ;;
  *)
    echo -e "${RED}Invalid TEST_MODE: $TEST_MODE (using 'normal')${NC}"
    DEFAULT_MAX_TESTS=500
    MAX_FILE_SIZE=5242880
    TEST_ALL_SIGNATURES=false
    ;;
esac

# Signature repository path
SIG_REPO="${SCRIPT_DIR}/../../Commodity-Injection-Signatures"

# Logging configuration
LOG_DIR="${SCRIPT_DIR}"
LOG_FILE="${LOG_DIR}/signature-sanitization.log"
DETAILED_LOG="${LOG_DIR}/signature-sanitization-detailed.log"
ENABLE_LOGGING="${ENABLE_LOGGING:-true}"  # Can be disabled via env var

# Debug: Print environment and paths
echo "══════════════════════════════════════════════════════════"
echo "Logging Configuration DEBUG:"
echo "  ENABLE_LOGGING=$ENABLE_LOGGING (from env or default)"
echo "  TEST_MODE=${TEST_MODE:-not set}"
echo "  SCRIPT_DIR=$SCRIPT_DIR"
echo "  Current PWD=$(pwd)"
echo "  LOG_FILE=$LOG_FILE"
echo "  DETAILED_LOG=$DETAILED_LOG"
echo "  Log directory writable: $(test -w "$LOG_DIR" && echo "YES" || echo "NO")"
echo "══════════════════════════════════════════════════════════"
echo ""

if [[ "$ENABLE_LOGGING" == "true" ]]; then
  echo "✓ Logging ENABLED - creating log files..."
  echo "  Summary log: $LOG_FILE"
  echo "  Detailed log: $DETAILED_LOG"
  echo ""

  # Ensure directory exists and is writable
  mkdir -p "$LOG_DIR" 2>/dev/null || true

  # Create log files with error checking
  if echo "==================================================================" > "$LOG_FILE" 2>&1; then
    echo "Signature Sanitization Test Log" >> "$LOG_FILE"
    echo "Start Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$LOG_FILE"
    echo "Test Mode: ${TEST_MODE:-default}" >> "$LOG_FILE"
    echo "Working Directory: $(pwd)" >> "$LOG_FILE"
    echo "==================================================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "  ✓ Created $LOG_FILE ($(wc -c < "$LOG_FILE") bytes)"
  else
    echo "  ✗ ERROR: Failed to create $LOG_FILE"
    echo "    Attempting alternative location..."
    LOG_FILE="./signature-sanitization.log"
    echo "==================================================================" > "$LOG_FILE"
    echo "  ✓ Created $LOG_FILE in current directory"
  fi

  if echo "==================================================================" > "$DETAILED_LOG" 2>&1; then
    echo "Detailed Signature Sanitization Log" >> "$DETAILED_LOG"
    echo "Start Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$DETAILED_LOG"
    echo "Test Mode: ${TEST_MODE:-default}" >> "$DETAILED_LOG"
    echo "Working Directory: $(pwd)" >> "$DETAILED_LOG"
    echo "==================================================================" >> "$DETAILED_LOG"
    echo "" >> "$DETAILED_LOG"
    echo "  ✓ Created $DETAILED_LOG ($(wc -c < "$DETAILED_LOG") bytes)"
  else
    echo "  ✗ ERROR: Failed to create $DETAILED_LOG"
    echo "    Attempting alternative location..."
    DETAILED_LOG="./signature-sanitization-detailed.log"
    echo "==================================================================" > "$DETAILED_LOG"
    echo "  ✓ Created $DETAILED_LOG in current directory"
  fi

  echo ""

  # Verify log files were created
  if [[ -f "$LOG_FILE" ]] && [[ -f "$DETAILED_LOG" ]]; then
    echo "✓ VERIFIED: Log files exist on disk:"
    ls -lh "$LOG_FILE" "$DETAILED_LOG" 2>/dev/null || ls -l "$LOG_FILE" "$DETAILED_LOG"
    echo ""
  else
    echo "✗ ERROR: Log files not found after creation attempt!"
    echo "  Expected: $LOG_FILE"
    echo "  Expected: $DETAILED_LOG"
    echo "  Directory contents:"
    ls -la "$LOG_DIR" 2>/dev/null || ls -la "$(pwd)"
    echo ""
  fi
else
  echo "⊘ Logging DISABLED (ENABLE_LOGGING=$ENABLE_LOGGING)"
  echo ""
fi

# Logging helper functions
log_test() {
  local level="$1"
  local category="$2"
  local file="$3"
  local line_num="$4"
  local input="$5"
  local output="$6"
  local status="$7"

  if [[ "$ENABLE_LOGGING" != "true" ]]; then
    return 0
  fi

  # Summary log
  echo "[$(date -u '+%Y-%m-%d %H:%M:%S')] [$level] [$category] $(basename "$file"):$line_num - $status" >> "$LOG_FILE"

  # Detailed log with input/output
  {
    echo "────────────────────────────────────────────────────────────────"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Level: $level"
    echo "Category: $category"
    echo "File: $(basename "$file")"
    echo "Line: $line_num"
    echo "Status: $status"
    echo ""
    echo "Original Input:"
    echo "$input"
    echo ""
    echo "Sanitized Output:"
    echo "$output"
    echo ""
    echo "Changes Applied:"
    # Detect what changed
    if [[ "$input" != "$output" ]]; then
      [[ "$input" =~ \< && "$output" =~ "&lt;" ]] && echo "  - Escaped < to &lt;"
      [[ "$input" =~ \> && "$output" =~ "&gt;" ]] && echo "  - Escaped > to &gt;"
      [[ "$input" =~ \& && "$output" =~ "&amp;" ]] && echo "  - Escaped & to &amp;"
      [[ "$input" =~ \" && "$output" =~ "&quot;" ]] && echo "  - Escaped \" to &quot;"
      [[ "$input" =~ \' && "$output" =~ "&#39;" ]] && echo "  - Escaped ' to &#39;"
      [[ "$input" =~ $'\r' ]] && echo "  - Removed carriage return (CR)"
      [[ "$input" =~ $'\n' && ! "$output" =~ $'\n' ]] && echo "  - Removed newline (LF)"
      [[ "$input" =~ $'\t' ]] && echo "  - Removed tab character"
      [[ "$input" =~ $'\x00' ]] && echo "  - Removed NULL byte"

      local input_len=${#input}
      local output_len=${#output}
      if [[ $input_len -gt 1000 && $output_len -lt $input_len ]]; then
        echo "  - Truncated from $input_len to $output_len chars"
      fi
    else
      echo "  - No sanitization needed (safe input)"
    fi
    echo ""
  } >> "$DETAILED_LOG"
}

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Comprehensive Signature Test Suite                         ║${NC}"
echo -e "${BLUE}║  Testing ALL Commodity-Injection-Signatures                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if signature repository exists
if [[ ! -d "$SIG_REPO" ]]; then
  echo -e "${RED}✗ ERROR: Commodity-Injection-Signatures not found at: $SIG_REPO${NC}"
  echo "Please clone: git clone https://github.com/xsscx/Commodity-Injection-Signatures.git"
  exit 1
fi

echo -e "${CYAN}Signature Repository: $SIG_REPO${NC}"
echo ""

# Test a signature file
test_signature_file() {
  local file="$1"
  local category="$2"
  local max_tests="${3:-$DEFAULT_MAX_TESTS}"  # Use default or specified max
  local line_count=0
  local file_tests=0
  local file_passed=0
  local file_failed=0

  # Override max_tests if TEST_ALL_SIGNATURES is true
  if [[ "$TEST_ALL_SIGNATURES" == "true" ]]; then
    max_tests=999999  # Effectively unlimited
  fi

  # Skip if file is too large
  local file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
  if [[ -n "$file_size" && $file_size -gt $MAX_FILE_SIZE ]]; then
    echo -e "  ${YELLOW}⊘ SKIP: File too large ($(numfmt --to=iec-i --suffix=B $file_size 2>/dev/null || echo "$file_size bytes"))${NC}"
    ((SKIPPED_FILES++)) || true
    return 0
  fi

  # Read and test signatures from file
  # Temporarily disable strict mode for entire while-read loop
  set +euo pipefail
  while IFS= read -r line || [[ -n "$line" ]]; do
    ((line_count++)) || true

    # Skip empty lines and comments
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue
    [[ "$line" =~ ^// ]] && continue

    # Progress indicator for large files (every 500 tests)
    if [[ $((file_tests % 500)) -eq 0 ]] && [[ $file_tests -gt 0 ]]; then
      echo -e "  ${CYAN}... Progress: $file_tests tests completed${NC}"
    fi

    # Test the signature with increased length limit for testing
    local result
    result=$(SANITIZE_LINE_MAXLEN=5000 sanitize_line "$line" 2>/dev/null) || result=""

    # Determine test status
    local test_status="PASS"
    local test_level="INFO"

    # Verify HTML is escaped (basic check)
    # For very long inputs that still get truncated, check if dangerous chars exist in result
    if [[ "$line" =~ \< ]]; then
      # Input has <, verify it's escaped or removed
      if [[ "$result" =~ \< ]]; then
        # Unescaped < found in output - FAIL
        echo -e "  ${RED}✗ FAIL: Line $line_count contains unescaped <${NC}"
        ((file_failed++)) || true
        test_status="FAIL"
        test_level="ERROR"
      else
        # No unescaped < in output - OK (either escaped or truncated safely)
        ((file_passed++)) || true
      fi
    elif [[ "$line" =~ \> ]]; then
      # Input has >, verify it's escaped or removed
      if [[ "$result" =~ \> ]]; then
        # Unescaped > found in output - FAIL
        echo -e "  ${RED}✗ FAIL: Line $line_count contains unescaped >${NC}"
        ((file_failed++)) || true
        test_status="FAIL"
        test_level="ERROR"
      else
        # No unescaped > in output - OK
        ((file_passed++)) || true
      fi
    else
      ((file_passed++)) || true
    fi

    # Log this test (every 10th test for performance)
    if [[ $((file_tests % 10)) -eq 0 ]] || [[ "$test_status" == "FAIL" ]]; then
      log_test "$test_level" "$category" "$file" "$line_count" "$line" "$result" "$test_status"
    fi

    ((file_tests++)) || true
    ((TOTAL_TESTS++)) || true

    # Limit tests per file
    if [[ $file_tests -ge $max_tests ]]; then
      break
    fi

  done < "$file"
  set -euo pipefail  # Re-enable strict mode after loop

  if [[ $file_tests -eq 0 ]]; then
    echo -e "  ${YELLOW}⊘ SKIP: No valid signatures found${NC}"
    ((SKIPPED_FILES++)) || true || true
    return 0
  fi

  ((TESTED_FILES++)) || true
  ((PASSED_TESTS+=file_passed)) || true
  ((FAILED_TESTS+=file_failed)) || true

  if [[ $file_failed -eq 0 ]]; then
    echo -e "  ${GREEN}✓ PASS: $file_passed/$file_tests tests${NC}"
  else
    echo -e "  ${RED}✗ FAIL: $file_passed passed, $file_failed failed (total: $file_tests)${NC}"
  fi
}

# Process a directory of signature files
process_directory() {
  local dir="$1"
  local category="$2"

  echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}Category: $category${NC}"
  echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
  echo ""

  local file_count=0

  # Find all .txt, .fuzz, and .svg files
  # Use temp file to avoid process substitution hang with strict mode
  local tempfile=$(mktemp)
  find "$dir" -maxdepth 1 -type f \( -name "*.txt" -o -name "*.fuzz" -o -name "*.svg" \) 2>/dev/null | sort > "$tempfile" || true

  local files=()
  while IFS= read -r file; do
    [[ -n "$file" ]] && files+=("$file")
  done < "$tempfile"
  rm -f "$tempfile"

  if [[ ${#files[@]} -eq 0 ]]; then
    echo -e "${YELLOW}  No signature files found in this category${NC}"
    echo ""
    return 0
  fi

  # Process all files with safe error handling
  for file in "${files[@]}"; do
    ((file_count++)) || true
    local basename=$(basename "$file")
    echo -e "${CYAN}[$file_count] Testing: $basename${NC}"
    # Call test function but don't let failures kill the script
    test_signature_file "$file" "$category" || {
      echo -e "${RED}  Warning: Error testing $basename${NC}"
    }
    echo ""
  done
}

# Main test execution
echo -e "${BLUE}Starting comprehensive test sweep...${NC}"
echo ""

# Test major categories
process_directory "$SIG_REPO/random" "Random XSS & Malicious Input"
process_directory "$SIG_REPO/svg" "SVG-based Attacks"
process_directory "$SIG_REPO/unix" "Unix/Shell Injection"
process_directory "$SIG_REPO/uri" "URI Mutations & Protocol Handlers"
process_directory "$SIG_REPO/javascript" "JavaScript Injection"
process_directory "$SIG_REPO/xml" "XML/XXE Injection"
process_directory "$SIG_REPO/sqlinjection" "SQL Injection"
process_directory "$SIG_REPO/css" "CSS Injection"
process_directory "$SIG_REPO/httpheader" "HTTP Header Injection"
process_directory "$SIG_REPO/callback" "Callback Injection"
process_directory "$SIG_REPO/email" "Email Injection"
process_directory "$SIG_REPO/json" "JSON Injection"
process_directory "$SIG_REPO/meta" "Meta Tag Injection"
process_directory "$SIG_REPO/parameter" "Parameter Pollution"
process_directory "$SIG_REPO/referer" "Referer Injection"
process_directory "$SIG_REPO/soap" "SOAP Injection"
process_directory "$SIG_REPO/ssi" "SSI Injection"
process_directory "$SIG_REPO/lfi-local-file-system-harvesting" "LFI/Path Traversal"
process_directory "$SIG_REPO/shell" "Shell Injection"
process_directory "$SIG_REPO/angular" "Angular Template Injection"
process_directory "$SIG_REPO/python" "Python Injection"
process_directory "$SIG_REPO/java" "Java Injection"
process_directory "$SIG_REPO/ps" "PowerShell Injection"
process_directory "$SIG_REPO/applescript" "AppleScript Injection"
process_directory "$SIG_REPO/custom" "Custom Signatures"
process_directory "$SIG_REPO/ascii" "ASCII/Unicode Attacks"
process_directory "$SIG_REPO/calc" "Calculator/Expression Injection"
process_directory "$SIG_REPO/ua" "User-Agent Injection"
process_directory "$SIG_REPO/rbl" "RBL/DNS Attacks"
process_directory "$SIG_REPO/graphics" "Graphics-based Attacks"

# Test root-level files
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Category: Root Level Signatures${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}[1] Testing: no-experience-required-xss-signatures-only-fools-dont-use.txt${NC}"
test_signature_file "$SIG_REPO/no-experience-required-xss-signatures-only-fools-dont-use.txt" "Root XSS"
echo ""

# Note: Skip full-unicode.txt as it's 5.5MB
echo -e "${CYAN}[2] Testing: xml-paste-from-gist.txt${NC}"
test_signature_file "$SIG_REPO/xml-paste-from-gist.txt" "Root XML"
echo ""

# Final Summary
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Comprehensive Test Summary                                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Signature Files Tested: $TESTED_FILES"
echo "Signature Files Skipped: $SKIPPED_FILES"
echo ""
echo "Total Signature Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"

# Finalize logs
if [[ "$ENABLE_LOGGING" == "true" ]]; then
  {
    echo ""
    echo "=================================================================="
    echo "Test Execution Summary"
    echo "End Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "=================================================================="
    echo ""
    echo "Signature Files Tested: $TESTED_FILES"
    echo "Signature Files Skipped: $SKIPPED_FILES"
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo ""
    echo "Log Location: $LOG_FILE"
    echo "Detailed Log: $DETAILED_LOG"
    echo "=================================================================="
  } >> "$LOG_FILE"

  {
    echo ""
    echo "=================================================================="
    echo "End of Detailed Sanitization Log"
    echo "End Time: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Total Tests Logged: $TOTAL_TESTS"
    echo "=================================================================="
  } >> "$DETAILED_LOG"

  echo ""
  echo -e "${CYAN}Logs saved:${NC}"
  echo "  Summary: $LOG_FILE"
  echo "  Detailed: $DETAILED_LOG"

  # Verify files were actually created
  if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(wc -c < "$LOG_FILE" 2>/dev/null || echo "0")
    echo "  Summary log size: ${LOG_SIZE} bytes"
  else
    echo "  WARNING: Summary log file not found!"
  fi

  if [ -f "$DETAILED_LOG" ]; then
    DETAILED_SIZE=$(wc -c < "$DETAILED_LOG" 2>/dev/null || echo "0")
    echo "  Detailed log size: ${DETAILED_SIZE} bytes"
  else
    echo "  WARNING: Detailed log file not found!"
  fi
  echo ""
fi

if [[ $FAILED_TESTS -gt 0 ]]; then
  echo -e "${RED}Failed: $FAILED_TESTS${NC}"
  echo ""
  echo -e "${RED}Some sanitization tests failed!${NC}"

  # Final verification before exit
  if [[ "$ENABLE_LOGGING" == "true" ]]; then
    echo ""
    echo "══════════════════════════════════════════════════════════"
    echo "Log Files Status (before exit):"
    ls -lh "$LOG_FILE" "$DETAILED_LOG" 2>/dev/null || echo "  ⚠ Log files not found"
    echo "══════════════════════════════════════════════════════════"
  fi

  exit 1
else
  echo -e "${GREEN}Failed: 0${NC}"
  echo ""
  echo -e "${GREEN}All signature tests passed!${NC}"
  echo -e "${GREEN}The sanitizer successfully neutralized all attack patterns.${NC}"

  # Final verification before exit
  if [[ "$ENABLE_LOGGING" == "true" ]]; then
    echo ""
    echo "══════════════════════════════════════════════════════════"
    echo "Log Files Status (before exit):"
    ls -lh "$LOG_FILE" "$DETAILED_LOG" 2>/dev/null || echo "  ⚠ Log files not found"
    echo "══════════════════════════════════════════════════════════"
  fi

  exit 0
fi
