#!/bin/bash
# Test script for CIccTagSparseMatrixArray heap corruption fix
# PoC: crash-sparse-matrix-heap (329 bytes)
# Issue: Heap metadata corruption in destructor
# Root causes:
#   1. Reset() calculated size with old m_nChannelsPerMatrix value
#   2. Copy assignment operator used wrong calloc size
# Fix: Use new channel count for size calculation

set -e

echo "=== Testing CIccTagSparseMatrixArray Heap Corruption Fix ==="
echo ""
echo "Building UBSan fuzzer..."
./build-fuzzers-local.sh undefined > /dev/null 2>&1

echo "Testing with PoC (crash-sparse-matrix-heap)..."
if [ ! -f crash-sparse-matrix-heap ]; then
    echo "ERROR: PoC file not found"
    exit 1
fi

# Run with UBSan to detect any heap corruption
if timeout 10 ./fuzzers-local/undefined/icc_toxml_fuzzer crash-sparse-matrix-heap 2>&1 | grep -q "deadly signal\|SEGV\|free().*invalid\|heap-buffer-overflow"; then
    echo "❌ FAIL: Heap corruption still detected"
    exit 1
fi

echo "✅ PASS: No heap corruption detected"
echo ""
echo "Fix details:"
echo "  Location 1: IccTagBasic.cpp:5048 (Reset method)"
echo "    Before: icUInt32Number nSize = nNumMatrices * GetBytesPerMatrix();"
echo "    After:  icUInt32Number nBytesPerMatrix = nChannelsPerMatrix * sizeof(icFloatNumber);"
echo "            icUInt32Number nSize = nNumMatrices * nBytesPerMatrix;"
echo ""
echo "  Location 2: IccTagBasic.cpp:4539 (Copy assignment operator)"
echo "    Before: m_RawData = (icUInt8Number*)calloc(m_nSize, m_nChannelsPerMatrix);"
echo "    After:  m_RawData = (icUInt8Number*)calloc(m_nSize, GetBytesPerMatrix());"
echo ""
echo "Test completed successfully!"
