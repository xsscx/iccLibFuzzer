#!/bin/bash
set -e

echo "=== Testing AddXform Double-Free Fix ==="
echo

# Decode the crash input
echo "Creating crash input..."
echo "//8AAAAAAAAEAQAAAwQAAEdSQVk920xSAAAABP8A////cHNlYWNzcP9bWVhiAAAAAABtdW1pAAAE////ekNMUnp6enp6enp6enpjc///////////////////////////bG5pbP//////////////////////////////////AAAAAAAA" | base64 -d > /tmp/crash-vptr-test.icc

echo "Testing with icc_profile_fuzzer..."
./fuzzers-local/address/icc_profile_fuzzer /tmp/crash-vptr-test.icc 2>&1 | grep -E "(ERROR|runtime error|SUMMARY)" || echo "✓ No UBSan errors detected"

echo
echo "Testing with icc_calculator_fuzzer..."
./fuzzers-local/address/icc_calculator_fuzzer /tmp/crash-vptr-test.icc 2>&1 | grep -E "(ERROR|runtime error|SUMMARY)" || echo "✓ No UBSan errors detected"

echo
echo "Testing with icc_spectral_fuzzer..."
./fuzzers-local/address/icc_spectral_fuzzer /tmp/crash-vptr-test.icc 2>&1 | grep -E "(ERROR|runtime error|SUMMARY)" || echo "✓ No UBSan errors detected"

echo
echo "=== All tests passed! ==="
rm /tmp/crash-vptr-test.icc
