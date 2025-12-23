#!/bin/bash
# PR #333 Local Testing One-Liners
# Copy/paste each command to test individually

echo "=== PR #333 Testing One-Liners ==="
echo ""

echo "1. Clone and setup:"
echo "git clone https://github.com/xsscx/ipatch.git && cd ipatch"
echo ""

echo "2. Checkout PR #333:"
echo "cd iccDEV && git fetch origin pull/333/head:pr-333 && git checkout pr-333 && cd .."
echo ""

echo "3. Build fuzzers with PR #333:"
echo "./build-fuzzers-local.sh address"
echo ""

echo "4. Test heap-use-after-free reproducers (known bug in fuzzer, not PR):"
echo "./reproduce-heap-uaf-calculator.sh"
echo ""

echo "5. Test NULL pointer dereference (fixed):"
echo "./reproduce-npd-spectral.sh"
echo ""

echo "6. Quick fuzzing test - icc_calculator_fuzzer (10 runs):"
echo "./fuzzers-local/address/icc_calculator_fuzzer -runs=10 -detect_leaks=0 Testing/Calc/*.icc"
echo ""

echo "7. Quick fuzzing test - icc_spectral_fuzzer (100 runs):"
echo "./fuzzers-local/address/icc_spectral_fuzzer -runs=100 -detect_leaks=0 Testing/Display/*.icc"
echo ""

echo "8. Quick fuzzing test - icc_fromxml_fuzzer (50 runs):"
echo "./fuzzers-local/address/icc_fromxml_fuzzer -runs=50 -detect_leaks=0 Testing/Calc/*.xml"
echo ""

echo "9. Full 30-second fuzzing test:"
echo "./fuzzers-local/address/icc_profile_fuzzer ./fuzzers-local/address/icc_profile_fuzzer_seed_corpus -max_total_time=30 -detect_leaks=0 -rss_limit_mb=512"
echo ""

echo "10. Test all crash files for regression:"
echo "for f in crash-*; do echo \"Testing \$f\"; ./fuzzers-local/address/icc_calculator_fuzzer \$f 2>&1 | grep -q ERROR && echo \"  ✓ Crash reproduced (expected)\"; done"
echo ""

echo "11. Verify build products:"
echo "ls -lh fuzzers-local/address/icc_*_fuzzer"
echo ""

echo "12. Clean build (if needed):"
echo "rm -rf Build/Cmake/Build/Cmake/build_local_address_* fuzzers-local/address"
echo ""

echo "=== Expected Results ==="
echo "✓ All fuzzers build successfully"
echo "✓ Heap-UAF crashes still reproduce (fuzzer bug, not PR)"
echo "✓ NPD test shows bug is fixed"
echo "✓ No new crashes from PR #333 changes"
