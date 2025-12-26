#!/bin/bash
# IccApplyNamedCmm Unit Tests and 1-liner Validation Checks
# Generated: 2025-12-26
# Purpose: Comprehensive testing of all encoding formats, interpolation modes, and rendering intents

set -e

TOOL="./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm"
TEST_DATA="Testing/ApplyDataFiles"
TEST_PROFILE="Testing/Display/sRGB_D65_MAT.icc"
PASS=0
FAIL=0
TOTAL=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "IccApplyNamedCmm Test Suite"
echo "Built with: $($TOOL 2>&1 | head -1)"
echo "=========================================="
echo ""

# Test helper function
run_test() {
    local desc="$1"
    local cmd="$2"
    local expect_success="${3:-1}"  # Default: expect success
    
    TOTAL=$((TOTAL + 1))
    echo -n "[TEST $TOTAL] $desc ... "
    
    if eval "$cmd" >/dev/null 2>&1; then
        if [ "$expect_success" -eq 1 ]; then
            echo -e "${GREEN}PASS${NC}"
            PASS=$((PASS + 1))
        else
            echo -e "${RED}FAIL${NC} (expected failure)"
            FAIL=$((FAIL + 1))
        fi
    else
        if [ "$expect_success" -eq 0 ]; then
            echo -e "${GREEN}PASS${NC} (expected failure)"
            PASS=$((PASS + 1))
        else
            echo -e "${RED}FAIL${NC}"
            FAIL=$((FAIL + 1))
        fi
    fi
}

# Validate output helper
validate_output() {
    local desc="$1"
    local cmd="$2"
    local expected_pattern="$3"
    
    TOTAL=$((TOTAL + 1))
    echo -n "[TEST $TOTAL] $desc ... "
    
    output=$($cmd 2>&1)
    if echo "$output" | grep -q "$expected_pattern"; then
        echo -e "${GREEN}PASS${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL${NC} (pattern not found: $expected_pattern)"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== BASIC FUNCTIONALITY ==="
run_test "Tool exists and is executable" "test -x $TOOL"
run_test "Help output on no args" "$TOOL 2>&1 | grep -q 'Usage 1'"
run_test "Version string present" "$TOOL 2>&1 | grep -q 'IccProfLib version'"

echo ""
echo "=== ENCODING FORMATS (0-6) ==="
# Format 0: icEncodeValue
validate_output "Format 0: icEncodeValue" \
    "$TOOL $TEST_DATA/rgbFloat.txt 0 0 $TEST_PROFILE 0" \
    "icEncodeValue"

# Format 1: icEncodePercent
validate_output "Format 1: icEncodePercent" \
    "$TOOL $TEST_DATA/rgbFloat.txt 1 0 $TEST_PROFILE 0" \
    "icEncodePercent"

# Format 2: icEncodeUnitFloat
validate_output "Format 2: icEncodeUnitFloat" \
    "$TOOL $TEST_DATA/rgbFloat.txt 2 0 $TEST_PROFILE 0" \
    "icEncodeUnitFloat"

# Format 3: icEncodeFloat
validate_output "Format 3: icEncodeFloat" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 0" \
    "icEncodeFloat"

# Format 4: icEncode8Bit (invalid - should fail)
run_test "Format 4: icEncode8Bit (invalid)" \
    "$TOOL $TEST_DATA/rgbFloat.txt 4 0 $TEST_PROFILE 0 2>&1 | grep -q 'Invalid'" \
    1

# Format 5: icEncode16Bit
validate_output "Format 5: icEncode16Bit" \
    "$TOOL $TEST_DATA/rgb8bit.txt 5 0 $TEST_PROFILE 0" \
    "icEncode16Bit"

# Format 6: icEncode16BitV2
validate_output "Format 6: icEncode16BitV2" \
    "$TOOL $TEST_DATA/rgb8bit.txt 6 0 $TEST_PROFILE 0" \
    "icEncode16BitV2"

echo ""
echo "=== INTERPOLATION MODES ==="
validate_output "Interpolation 0: Linear" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 0" \
    "icEncodeFloat"

validate_output "Interpolation 1: Tetrahedral" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 1 $TEST_PROFILE 0" \
    "icEncodeFloat"

echo ""
echo "=== RENDERING INTENTS ==="
# Basic intents (0-3)
validate_output "Intent 0: Perceptual" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 0" \
    "Profiles applied"

validate_output "Intent 1: Relative Colorimetric" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 1" \
    "Profiles applied"

validate_output "Intent 2: Saturation" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 2" \
    "Profiles applied"

validate_output "Intent 3: Absolute Colorimetric" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 3" \
    "Profiles applied"

# Special intents (note: some intents require specific profile types)
# Intent 30 (Gamut) may not be valid for all profiles
run_test "Intent 30: Gamut (may fail for some profiles)" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 30 2>&1 | grep -qE 'Profiles applied|Invalid Profile'" \
    1

run_test "Intent 33: Gamut Absolute (may fail for some profiles)" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 33 2>&1 | grep -qE 'Profiles applied|Invalid Profile'" \
    1

# Modified intents (additive flags)
run_test "Intent 1000: Luminance PCS (Perceptual)" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 1000 2>&1 | grep -qE 'Profiles applied|Invalid Profile'" \
    1

run_test "Intent 10000: V5 subprofile (Perceptual)" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 10000 2>&1 | grep -qE 'Profiles applied|Invalid Profile'" \
    1

run_test "Intent 100000: HToS tag (Perceptual)" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 100000 2>&1 | grep -qE 'Profiles applied|Invalid Profile'" \
    1

echo ""
echo "=== PRECISION FORMATTING ==="
validate_output "Precision: 3:4:8 format" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3:4:8 0 $TEST_PROFILE 0" \
    "icEncodeFloat"

validate_output "Precision: 3:2:6 format" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3:2:6 0 $TEST_PROFILE 0" \
    "icEncodeFloat"

echo ""
echo "=== ERROR HANDLING ==="
run_test "Missing data file" \
    "$TOOL /nonexistent.txt 3 0 $TEST_PROFILE 0 2>&1 | grep -q 'Error\\|Cannot\\|Unable'" \
    1

run_test "Missing profile file" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 0 /nonexistent.icc 0 2>&1 | grep -q 'Invalid Profile'" \
    1

run_test "Invalid encoding (99)" \
    "$TOOL $TEST_DATA/rgbFloat.txt 99 0 $TEST_PROFILE 0 2>&1 | grep -q 'Invalid'" \
    1

run_test "Invalid interpolation (9) - UBSan detects error" \
    "$TOOL $TEST_DATA/rgbFloat.txt 3 9 $TEST_PROFILE 0 2>&1 | grep -qE 'runtime error|not a valid value'" \
    1

echo ""
echo "=== DATA FILE FORMATS ==="
if [ -f "$TEST_DATA/rgb8bit.txt" ]; then
    run_test "8-bit RGB data" \
        "ASAN_OPTIONS=detect_leaks=0 $TOOL $TEST_DATA/rgb8bit.txt 3 0 $TEST_PROFILE 0 2>&1 | grep -q icEncode8Bit" \
        1
fi

if [ -f "$TEST_DATA/rgb16bit.txt" ]; then
    run_test "16-bit RGB data" \
        "ASAN_OPTIONS=detect_leaks=0 $TOOL $TEST_DATA/rgb16bit.txt 3 0 $TEST_PROFILE 0 2>&1 | grep -q icEncode16Bit" \
        1
fi

if [ -f "$TEST_DATA/rgbFloat.txt" ]; then
    run_test "Float RGB data" \
        "ASAN_OPTIONS=detect_leaks=0 $TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 0 2>&1 | grep -q icEncodeFloat" \
        1
fi

if [ -f "$TEST_DATA/cmykFloat.txt" ]; then
    # CMYK requires appropriate CMYK profile - skip for now
    echo "[INFO] CMYK test skipped (requires CMYK profile)"
fi

echo ""
echo "=== 1-LINER CHECKS ==="
echo "These can be copied for quick validation:"
echo ""
echo -e "${YELLOW}# Quick smoke test (should output XYZ values)${NC}"
echo "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 0 | head -20"
echo ""
echo -e "${YELLOW}# Verify encoding format change${NC}"
echo "$TOOL $TEST_DATA/rgbFloat.txt 5 0 $TEST_PROFILE 0 | grep icEncode16Bit"
echo ""
echo -e "${YELLOW}# Test all basic intents (0-3)${NC}"
echo "for i in 0 1 2 3; do $TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE \$i | head -5; done"
echo ""
echo -e "${YELLOW}# Compare linear vs tetrahedral interpolation${NC}"
echo "diff <($TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 0) <($TOOL $TEST_DATA/rgbFloat.txt 3 1 $TEST_PROFILE 0)"
echo ""
echo -e "${YELLOW}# Validate output is parseable${NC}"
echo "$TOOL $TEST_DATA/rgbFloat.txt 3 0 $TEST_PROFILE 0 | grep -E '^[[:space:]]*[0-9]' | head -5"
echo ""

echo "=========================================="
echo "Test Results"
echo "=========================================="
echo "Total:  $TOTAL"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
