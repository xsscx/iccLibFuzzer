#!/usr/bin/env bash
# icc_xml_roundtrip_test.sh
# Walk CWD recursively, run iccToXml -> iccFromXml, report results.

set -euo pipefail

ICC_TO_XML=iccToXml
ICC_FROM_XML=iccFromXml

REPORT="icc_roundtrip_report.txt"
: > "$REPORT"

echo "[*] ICC XML round-trip test started" | tee -a "$REPORT"
echo "[*] Root: $(pwd)" | tee -a "$REPORT"
echo | tee -a "$REPORT"

find . -type f -iname '*.icc' | while read -r icc; do
    xml="${icc%.icc}-from-icc.xml"
    out="${icc%.icc}-from-xml.icc"

    echo "[TEST] $icc" | tee -a "$REPORT"

    if ! "$ICC_TO_XML" "$icc" "$xml" > /tmp/icc_to_xml.log 2>&1; then
        echo "  FAIL: iccToXml" | tee -a "$REPORT"
        sed 's/^/    /' /tmp/icc_to_xml.log | tee -a "$REPORT"
        echo | tee -a "$REPORT"
        continue
    fi

    if ! "$ICC_FROM_XML" "$xml" "$out" > /tmp/icc_from_xml.log 2>&1; then
        echo "  FAIL: iccFromXml" | tee -a "$REPORT"
        sed 's/^/    /' /tmp/icc_from_xml.log | tee -a "$REPORT"
        echo | tee -a "$REPORT"
        continue
    fi

    echo "  PASS: round-trip succeeded" | tee -a "$REPORT"
    echo | tee -a "$REPORT"
done

echo "[*] Test complete. Report: $REPORT"
