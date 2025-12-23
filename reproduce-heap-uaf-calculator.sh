#!/bin/bash
set -euo pipefail

# Reproduce heap-use-after-free in icc_calculator_fuzzer
# Found by: ClusterFuzzLite Run #20398797129
# Issue: Double-free of CIccMemIO pointer
# Location: fuzzers/icc_calculator_fuzzer.cpp:74-75

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Check for locally built fuzzers
if [ -f "$REPO_ROOT/fuzzers-local/address/icc_calculator_fuzzer" ]; then
  FUZZER_PATH="$REPO_ROOT/fuzzers-local/address/icc_calculator_fuzzer"
  echo "=== Using locally built fuzzer from fuzzers-local/ ==="
else
  echo "ERROR: Fuzzer not found. Build with: ./build-fuzzers-local.sh address"
  exit 1
fi

echo ""
echo "=== Testing crash files for heap-use-after-free ==="
echo ""

for crash in crash-31ff7f659128d0da5ffadb7a52a7c545bcfd312a \
             crash-3c3c6c65ab8b4ba09d67bcb0edfdc2345e8285dd \
             crash-8f10f8c6412d87c820776f392c88006f7439cb41 \
             crash-cce76f368b98b45af59000491b03d2f9423709bc; do
  
  if [ ! -f "$crash" ]; then
    echo "Skipping $crash (not found)"
    continue
  fi
  
  echo "--- Testing: $crash ---"
  $FUZZER_PATH "$crash" 2>&1 | grep -A 3 "ERROR:\|SUMMARY:" || echo "No errors"
  echo ""
done

echo "=== Summary ==="
echo "Heap-use-after-free root cause:"
echo "  Line 40: pProfile->Attach(pIO)  // Takes ownership"
echo "  Line 74: delete pProfile        // Frees pIO internally"
echo "  Line 75: delete pIO             // ❌ DOUBLE-FREE!"
echo ""
echo "Fix: Remove line 75 (pIO deletion)"

echo "=== Summary ==="
echo "Heap-use-after-free root cause:"
echo "  Line 40: pProfile->Attach(pIO)  // Takes ownership"
echo "  Line 74: delete pProfile        // Frees pIO internally"
echo "  Line 75: delete pIO             // ❌ DOUBLE-FREE!"
echo ""
echo "Fix: Remove line 75 (pIO deletion)"
