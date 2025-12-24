#!/bin/bash
# Test heap buffer overflow fix in CIccTagTextDescription::Read()

echo "=== Heap Buffer Overflow Fix Test ==="
echo ""
echo "Location: IccTagBasic.cpp:2329 (strlen on non-null-terminated buffer)"
echo "Fix: Ensure null termination after Read8()"
echo ""

# Test with crash PoC
echo "Testing crash PoC..."
/home/xss/copilot/iccLibFuzzer/Build/Tools/IccToXml/iccToXml \
  /home/xss/copilot/iccLibFuzzer/fuzzers-local/address/crashes/crash-e4523e17c2de76693b4b205e828e5c053130b45b \
  /tmp/crash_test.xml 2>&1 | grep -E "ERROR|heap-buffer" && echo "FAIL: Still crashes" || echo "PASS: No crash"

echo ""

# Test with valid profile  
echo "Testing valid profile..."
/home/xss/copilot/iccLibFuzzer/Build/Tools/IccToXml/iccToXml \
  /home/xss/copilot/iccLibFuzzer/corpus/sRGB_v4_ICC_preference.icc \
  /tmp/valid_test.xml 2>&1 >/dev/null && echo "PASS: Valid profile works" || echo "FAIL: Valid profile broken"

echo ""
echo "=== Test Complete ==="
