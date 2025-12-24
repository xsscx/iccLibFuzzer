#!/bin/bash
# Automated type confusion pattern scanner for ICC codebase

echo "=== Type Confusion Pattern Analysis ==="
echo ""

echo "1. C-style casts to *Xml types (DANGEROUS):"
grep -rn '([[:space:]]*CIcc[^)]*Xml[[:space:]]*\*[[:space:]]*)' IccXML/ --include="*.cpp" | \
  grep -v "new CIcc" | grep -v "//" | head -30
echo ""

echo "2. Casts in ToXml* functions (HIGH PRIORITY):"
grep -B3 -A3 'ToXml.*Xml\*' IccXML/IccLibXML/*.cpp | grep -E "^[^-].*:[0-9]+:" | head -20
echo ""

echo "3. GetExtension() usage patterns:"
grep -n 'GetExtension()' IccXML/IccLibXML/*.cpp | head -20
echo ""

echo "4. dynamic_cast usage (should be added):"
grep -rn 'dynamic_cast' IccXML/ --include="*.cpp"
echo "  [Count: $(grep -r 'dynamic_cast' IccXML/ --include="*.cpp" | wc -l)]"
echo ""

echo "5. All ToXmlCurve/ToXmlSegment locations:"
grep -n 'ToXml.*(' IccXML/IccLibXML/IccMpeXml.cpp | grep -E '(Curve|Segment)' | head -10
echo ""

echo "=== Summary ==="
echo "Files with Xml casts:"
grep -rl 'CIcc.*Xml\*' IccXML/IccLibXML/*.cpp
echo ""
echo "Total C-style casts to Xml types: $(grep -r '([[:space:]]*CIcc[^)]*Xml[[:space:]]*\*)' IccXML/ --include="*.cpp" | wc -l)"
echo "Total GetExtension calls: $(grep -r 'GetExtension()' IccXML/ --include="*.cpp" | wc -l)"
