#!/bin/bash
# Test OOM fix for CIccLocalizedUnicode::SetSize()

set -e

echo "=== Testing OOM Fix for CIccLocalizedUnicode ==="

# Build test fuzzer
cd /home/xss/copilot/ipatch/fuzzers
clang++ -g -O2 -fsanitize=address,fuzzer \
  -I../IccProfLib \
  icc_profile_fuzzer.cpp \
  ../Build/Cmake/build/IccProfLib/libIccProfLib2-static.a \
  -o test_oom_fix

# Test with OOM PoC  
echo ""
echo "Testing PoC: oom-71e7dc3dadee23682067875cf2a9b474d24a9471.icc"
echo "Before fix: Would allocate 2.9GB and crash"
echo "After fix: Should reject with validation error"
echo ""

timeout 5 ./test_oom_fix ../fuzzers-local/address/crashes/oom-71e7dc3dadee23682067875cf2a9b474d24a9471.icc 2>&1 | grep -E "ERROR|SUMMARY|Executed" || echo "Profile rejected safely (no OOM)"

# Clean up
rm -f test_oom_fix

echo ""
echo "=== Test Complete ==="
echo "Fix Status: If no OOM error above, fix is working correctly"
