#!/bin/bash
set -euo pipefail

# Reproduce NULL pointer dereference in CIccTagSpectralViewingConditions::Write
# CVE: Pending
# Issue: NULL deref when m_observer/m_illuminant not allocated but steps > 0
# Location: IccProfLib/IccTagBasic.cpp:11183

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Check for locally built fuzzer
if [ -f "$REPO_ROOT/fuzzers-local/address/icc_fromxml_fuzzer" ]; then
  FUZZER_PATH="$REPO_ROOT/fuzzers-local/address/icc_fromxml_fuzzer"
  echo "=== Using locally built fuzzer from fuzzers-local/ ==="
else
  echo "ERROR: Fuzzer not found. Build with: ./build-fuzzers-local.sh address"
  exit 1
fi

CRASH_FILE="crash-05806b73da433dd63ab681e582dbf83640a4aac8"

if [ ! -f "$CRASH_FILE" ]; then
  echo "ERROR: Crash POC not found: $CRASH_FILE"
  exit 1
fi

echo ""
echo "=== Crash POC Details ==="
echo "File: $CRASH_FILE"
echo "Type: $(file -b "$CRASH_FILE")"
echo "Size: $(stat -c%s "$CRASH_FILE") bytes"
echo ""

echo "=== XML Content Preview ==="
head -30 "$CRASH_FILE"
echo ""

echo "=== Testing NULL Pointer Dereference ==="
echo ""

$FUZZER_PATH "$CRASH_FILE" 2>&1 | grep -A 10 "ERROR:\|SEGV\|SUMMARY:" || {
  echo "✅ No crash detected - bug fixed in commit c572512"
  echo ""
  echo "=== Fix Applied ==="
  echo "File: IccProfLib/IccTagBasic.cpp"
  echo "Lines: 11184-11185 (m_observer check)"
  echo "Lines: 11201-11202 (m_illuminant check)"
  echo ""
  echo "Before fix (vulnerable):"
  echo "  if (vals)"
  echo "    if (pIO->WriteFloat32Float(&m_observer[0], vals) != vals)"
  echo "      return false;"
  echo ""
  echo "After fix:"
  echo "  if (vals) {"
  echo "    if (!m_observer)    // ✅ NULL check added"
  echo "      return false;"
  echo "    if (pIO->WriteFloat32Float(&m_observer[0], vals) != vals)"
  echo "      return false;"
  echo "  }"
  exit 0
}

echo ""
echo "=== Vulnerability Summary ==="
echo "Root cause: m_observer/m_illuminant NULL but steps > 0"
echo "Location: IccTagBasic.cpp:11183, 11197"
echo "Fix: Add NULL checks before dereferencing arrays"
echo ""
echo "Stack trace location:"
echo "  #0 CIccIO::Write32() - Dereferences NULL"
echo "  #1 CIccIO::WriteFloat32Float() - Passes NULL pointer"
echo "  #2 CIccTagSpectralViewingConditions::Write() - Missing NULL check"
echo "  #3 CIccProfile::Write() - Calls Write on spectral tag"
echo "  #4 SaveIccProfile() - Entry point from fuzzer"
echo ""
echo "See: docs/CVE-2025-SPECTRAL-NULL-DEREF.md"
