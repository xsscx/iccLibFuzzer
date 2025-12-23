#!/bin/bash -eu
#
# Test PR 329 fix for heap-buffer-overflow in CIccLocalizedUnicode::GetText()
# Issue: https://github.com/InternationalColorConsortium/iccDEV/issues/328
# PR: https://github.com/InternationalColorConsortium/iccDEV/pull/329
#

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

SANITIZER="${1:-address}"
TEST_DURATION="${2:-300}"

echo "========================================="
echo "Testing PR 329 Fix"
echo "Issue: heap-buffer-overflow CIccLocalizedUnicode::GetText()"
echo "Sanitizer: $SANITIZER"
echo "Duration: ${TEST_DURATION}s"
echo "========================================="
echo ""

# Build fuzzers with fix
if [ ! -x "fuzzers-local/$SANITIZER/icc_profile_fuzzer" ]; then
  echo "Building fuzzer..."
  ./build-fuzzers-local.sh "$SANITIZER"
fi

# Run fuzzer with known crash
CRASH_FILE="crash-3c3c6c65ab8b4ba09d67bcb0edfdc2345e8285dd"
if [ -f "$CRASH_FILE" ]; then
  echo "Testing with known crash file: $CRASH_FILE"
  echo ""
  
  # Test crash file - should NOT crash with fix
  "fuzzers-local/$SANITIZER/icc_profile_fuzzer" "$CRASH_FILE" 2>&1 | head -20
  
  RESULT=$?
  echo ""
  if [ $RESULT -eq 0 ]; then
    echo "✅ Known crash file handled without error"
  else
    echo "❌ Crash file triggered error (exit code: $RESULT)"
  fi
  echo ""
fi

# Run extended fuzzing
echo "Running extended fuzzing test..."
./run-local-fuzzer.sh "$SANITIZER" icc_profile_fuzzer "$TEST_DURATION"

echo ""
echo "========================================="
echo "Test complete!"
echo "========================================="
