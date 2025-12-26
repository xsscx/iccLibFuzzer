#!/bin/bash
# Test for CVE-XXXX-XXXXX: Stack overflow via unbounded recursion in CIccMpeCalculator::Read
# Tests that maliciously crafted ICC profiles with recursive calculator elements are rejected

set -e

CRASH_FILE="crash-e4590f7d1b281a9230baa46ae0441afc1aabc3ff"
TOOL="Build/Tools/IccDumpProfile/iccDumpProfile"

echo "Testing recursion depth fix for CIccMpeCalculator::Read..."
echo "============================================================"
echo

if [ ! -f "$CRASH_FILE" ]; then
    echo "ERROR: Test file $CRASH_FILE not found"
    exit 1
fi

if [ ! -x "$TOOL" ]; then
    echo "ERROR: Tool $TOOL not found or not executable"
    exit 1
fi

echo "Test: Processing file with recursive calculator elements"
echo "Expected: Program should exit with error (not crash)"
echo

# Run with timeout to catch any remaining stack overflow
if timeout 5 "$TOOL" -v "$CRASH_FILE" >/dev/null 2>&1; then
    echo "UNEXPECTED: Program succeeded (should have failed)"
    exit 1
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo "FAIL: Program timed out (possible infinite recursion)"
        exit 1
    elif [ $EXIT_CODE -eq 139 ]; then
        echo "FAIL: Program crashed with segmentation fault"
        exit 1
    else
        echo "PASS: Program exited with error code $EXIT_CODE (as expected)"
        echo
        echo "Fix verified: Recursion depth limiting prevents stack overflow"
        exit 0
    fi
fi
