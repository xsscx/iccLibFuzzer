#!/bin/bash
# Demonstrate IccDumpProfile security heuristics

echo "=== IccDumpProfile Security Heuristics Demo ==="
echo

echo "1. Clean profile (sRGB test):"
./Build/Tools/IccDumpProfile/iccDumpProfile Testing/Calc/srgbCalcTest.icc 2>&1 | grep -A 4 "SECURITY.*Heuristic Summary"
echo

echo "2. Malicious profile (duplicate tags + header overlap):"
./Build/Tools/IccDumpProfile/iccDumpProfile /tmp/test_duplicates.icc 2>&1 | grep -A 4 "SECURITY.*Heuristic Summary"
echo

echo "3. Small POC profile:"
./Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc 2>&1 | grep -A 4 "SECURITY.*Heuristic Summary"
echo

echo "=== Heuristic Detection Complete ==="
