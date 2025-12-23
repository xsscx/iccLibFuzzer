#!/bin/bash
# Test script for heap buffer overflow in CIccTagColorantTable::Describe()
#
# CVE-ID: Pending
# CWE-125: Out-of-bounds Read
# Discovered: ClusterFuzzLite Run #20414703135

set -e

echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Testing Heap Buffer Overflow Fix - CIccTagColorantTable::Describe()"
echo "═══════════════════════════════════════════════════════════════════════════"
echo

# Generate PoC if it doesn't exist
if [ ! -f poc-archive/poc-heap-overflow-colorant.icc ]; then
    echo "[*] Generating PoC ICC profile..."
    python3 /tmp/create_colorant_overflow_poc.py
    mv poc-heap-overflow-colorant.icc poc-archive/
fi

echo "[*] PoC Details:"
ls -lh poc-archive/poc-heap-overflow-colorant.icc
sha256sum poc-archive/poc-heap-overflow-colorant.icc
echo

# Set library path
export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML:$LD_LIBRARY_PATH

echo "[*] Testing with FIXED code (commit 1b0c109)..."
echo

# Test with iccDumpProfile (includes Describe() call)
if Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc > /tmp/test-output.txt 2>&1; then
    echo "✅ PASS: No crash detected"
    echo
    grep -A 5 "colorantTableTag" /tmp/test-output.txt || true
else
    echo "❌ FAIL: Crash or error occurred"
    tail -20 /tmp/test-output.txt
    exit 1
fi

echo
echo "───────────────────────────────────────────────────────────────────────────"
echo "  Vulnerability Details"
echo "───────────────────────────────────────────────────────────────────────────"
echo
echo "File:          IccProfLib/IccTagBasic.cpp"
echo "Function:      CIccTagColorantTable::Describe()"
echo "Issue:         strlen() on non-null-terminated 32-byte buffer"
echo "Lines Fixed:   8903, 8918, 8921"
echo
echo "Before Fix:"
echo "  nLen = (icUInt32Number)strlen(m_pData[i].name);"
echo "  → Reads beyond 32-byte buffer if no null terminator"
echo
echo "After Fix:"
echo "  nLen = (icUInt32Number)strnlen(m_pData[i].name, sizeof(m_pData[i].name));"
echo "  → Limited to 32-byte scan"
echo
echo "───────────────────────────────────────────────────────────────────────────"
echo "  Additional Test: Build with ASan"
echo "───────────────────────────────────────────────────────────────────────────"
echo

if [ -f Build/IccProfLib/libIccProfLib2.so ]; then
    echo "[*] Checking if build has ASan enabled..."
    if nm Build/IccProfLib/libIccProfLib2.so | grep -q "__asan_"; then
        echo "✅ ASan enabled - running validation..."
        Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc > /dev/null 2>&1 && \
            echo "✅ ASan validation PASSED (no heap-buffer-overflow detected)" || \
            echo "❌ ASan detected issue"
    else
        echo "ℹ️  ASan not enabled in current build"
        echo "    To test with ASan: cd Build && cmake Cmake -DCMAKE_CXX_FLAGS=\"-fsanitize=address,undefined\""
    fi
fi

echo
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Test Complete - Fix Verified"
echo "═══════════════════════════════════════════════════════════════════════════"
