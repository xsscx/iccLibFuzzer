#!/bin/bash
# Test Heap-Use-After-Free Fix
# Tests icc_calculator_fuzzer and icc_multitag_fuzzer UAF fixes

set -e

echo "=== Testing Heap-Use-After-Free Fix ==="
echo ""

# Check fuzzers exist
if [ ! -f fuzzers-local/address/icc_calculator_fuzzer ]; then
  echo "Building fuzzers first..."
  ./build-fuzzers-local.sh address
fi

echo "1. Test calculator fuzzer with crash files (should pass now):"
for crash in crash-31ff7f659128d0da5ffadb7a52a7c545bcfd312a \
             crash-3c3c6c65ab8b4ba09d67bcb0edfdc2345e8285dd \
             crash-8f10f8c6412d87c820776f392c88006f7439cb41 \
             crash-cce76f368b98b45af59000491b03d2f9423709bc; do
  echo "  Testing $crash..."
  ./fuzzers-local/address/icc_calculator_fuzzer "$crash" 2>&1 | grep -q "ERROR" && echo "    ❌ FAILED - UAF still present" || echo "    ✅ PASSED"
done

echo ""
echo "2. Test multitag fuzzer with crash files (should pass now):"
for crash in crash-31ff7f659128d0da5ffadb7a52a7c545bcfd312a \
             crash-3c3c6c65ab8b4ba09d67bcb0edfdc2345e8285dd \
             crash-8f10f8c6412d87c820776f392c88006f7439cb41 \
             crash-cce76f368b98b45af59000491b03d2f9423709bc; do
  echo "  Testing $crash..."
  ./fuzzers-local/address/icc_multitag_fuzzer "$crash" 2>&1 | grep -q "ERROR" && echo "    ❌ FAILED - UAF still present" || echo "    ✅ PASSED"
done

echo ""
echo "3. Fuzzing test - calculator (1000 runs on valid corpus):"
./fuzzers-local/address/icc_calculator_fuzzer -runs=1000 -detect_leaks=0 Testing/Calc/*.icc 2>&1 | tail -3

echo ""
echo "4. Fuzzing test - multitag (1000 runs on valid corpus):"
./fuzzers-local/address/icc_multitag_fuzzer -runs=1000 -detect_leaks=0 Testing/Display/*.icc 2>&1 | tail -3

echo ""
echo "=== Test Complete ==="
echo "All crash files should pass (no ERROR output)"
