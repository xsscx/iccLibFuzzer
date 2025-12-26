#!/bin/bash
set -e

echo "=== PSSwopCustom22228.icc Vulnerability Reproduction ==="
echo ""

# Check file exists
if [ ! -f "PSSwopCustom22228.icc" ]; then
    echo "ERROR: PSSwopCustom22228.icc not found"
    exit 1
fi

# Test 1: IccDumpProfile
echo "[1/4] Testing IccDumpProfile (should show tag count 60171)..."
./Build/Tools/IccDumpProfile/iccDumpProfile PSSwopCustom22228.icc 2>&1 | \
    grep -E "(Tag Count|AToB0Tag)" | head -5
echo ""

# Test 2: IccToXml
echo "[2/4] Testing IccToXml (should fail with 'Unable to read')..."
./Build/Tools/IccToXml/iccToXml PSSwopCustom22228.icc /tmp/test.xml 2>&1 || \
    echo "Exit code: $?"
echo ""

# Test 3: ASan fuzzer
echo "[3/4] Testing ASan fuzzer (should SEGV in CIccTagCurve::Apply)..."
timeout 5 ./fuzzers-local/address/icc_profile_fuzzer PSSwopCustom22228.icc 2>&1 | \
    grep -E "(SEGV|IccTagLut.cpp:599)" || echo "Crash detected"
echo ""

# Test 4: UBSan fuzzer
echo "[4/4] Testing UBSan fuzzer (should report NaN conversion UB)..."
timeout 5 ./fuzzers-local/undefined/icc_profile_fuzzer PSSwopCustom22228.icc 2>&1 | \
    grep -E "(runtime error|nan)" || echo "UB detected"
echo ""

echo "=== Reproduction complete ==="
