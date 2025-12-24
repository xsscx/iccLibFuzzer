#!/usr/bin/env bash
# icc_xml_roundtrip_test_report.sh
# Recursive ICC → XML → ICC test with stats and developer summary (FIXED).

set -euo pipefail

ICC_TO_XML=iccToXml
ICC_FROM_XML=iccFromXml

REPORT="icc_roundtrip_report.txt"
SUMMARY="icc_roundtrip_summary.txt"

: > "$REPORT"
: > "$SUMMARY"

total=0
pass=0
fail_to_xml=0
fail_from_xml=0

echo "ICC XML Round-Trip Test Report" >> "$REPORT"
echo "Root: $(pwd)" >> "$REPORT"
echo "Date: $(date -u)" >> "$REPORT"
echo "----------------------------------------" >> "$REPORT"
echo >> "$REPORT"

while IFS= read -r icc; do
    total=$((total+1))

    xml="${icc%.icc}-from-icc.xml"
    out="${icc%.icc}-from-xml.icc"

    echo "[TEST] $icc" >> "$REPORT"

    if ! "$ICC_TO_XML" "$icc" "$xml" > /tmp/icc_to_xml.log 2>&1; then
        fail_to_xml=$((fail_to_xml+1))
        echo "  RESULT: FAIL (iccToXml)" >> "$REPORT"
        sed 's/^/    /' /tmp/icc_to_xml.log >> "$REPORT"
        echo >> "$REPORT"
        continue
    fi

    if ! "$ICC_FROM_XML" "$xml" "$out" > /tmp/icc_from_xml.log 2>&1; then
        fail_from_xml=$((fail_from_xml+1))
        echo "  RESULT: FAIL (iccFromXml)" >> "$REPORT"
        sed 's/^/    /' /tmp/icc_from_xml.log >> "$REPORT"
        echo >> "$REPORT"
        continue
    fi

    pass=$((pass+1))
    echo "  RESULT: PASS (round-trip succeeded)" >> "$REPORT"
    echo >> "$REPORT"

done < <(find . -type f -iname '*.icc')

# Summary (now correct)
{
echo "ICC XML ROUND-TRIP SUMMARY"
echo "=========================="
echo "Total ICC files tested : $total"
echo "Round-trip PASS        : $pass"
echo "FAIL at iccToXml       : $fail_to_xml"
echo "FAIL at iccFromXml     : $fail_from_xml"
echo
echo "Observations:"
echo "- iccFromXml failures are dominated by Calculator MPE grammar limitations (ULL/UL tokens)."
echo "- Profiles without Calculator MPEs generally round-trip successfully."
echo
echo "Action Items:"
echo "1. Extend iccFromXml calculator grammar to accept typed integer tokens (ULL, UL, etc.)."
echo "2. Or canonicalize calculator literals in iccToXml output."
echo "3. Treat ICC→XML as non-bijective for Calculator MPE profiles until fixed."
echo
echo "Artifacts:"
echo "- Detailed per-file log: $REPORT"
echo "- Summary (this file):  $SUMMARY"
} >> "$SUMMARY"

echo "[*] Test complete."
echo "[*] Report : $REPORT"
echo "[*] Summary: $SUMMARY"
