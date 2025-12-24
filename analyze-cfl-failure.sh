#!/bin/bash
# Analyze ClusterFuzzLite failures from the paste

echo "=== ClusterFuzzLite Failure Analysis ==="
echo ""

# Issues from the paste:
cat << 'ISSUES'
IDENTIFIED ISSUES:
==================

1. CORPUS NOT UPLOADED
   - Cause: corpus/ directory is gitignored
   - Impact: Fuzzers run with minimal/no seed corpus
   - Fix: Either commit corpus or use GCS bucket

2. DYNAMIC CAST IN RELEASE BUILD  
   - Error: dynamic_cast used in non-polymorphic type
   - File: IccMpeXml.cpp:978 (CIccFormulaCurveSegmentXml)
   - File: IccMpeXml.cpp:982 (CIccSampledCurveSegmentXml)
   - Cause: RTTI disabled or base class has no virtual methods
   - Fix: Verify base classes have virtual destructor

3. BUILD WARNINGS/ERRORS
   - Multiple dynamic_cast failures in IccMpeXml.cpp
   - Line 978: CIccFormulaCurveSegmentXml cast
   - Line 982: CIccSampledCurveSegmentXml cast
   - These are the fixes we JUST applied!

4. FUZZER EXECUTION ISSUES
   - Some fuzzers may not have proper corpus paths
   - Minimal seed corpus (sRGB_v4_ICC_preference.icc only)

ISSUES

echo ""
echo "=== Detailed Analysis ==="
echo ""

echo "1. Corpus Issue:"
echo "   - corpus/ is gitignored (see .gitignore line 31)"
echo "   - ClusterFuzzLite expects corpus in repo or GCS"
echo "   - Current state: corpus exists locally but not in GitHub"
echo ""

echo "2. Dynamic Cast Issue:"
echo "   - We replaced C-style casts with dynamic_cast"
echo "   - But base classes may not be polymorphic"
echo "   - Need to verify CIccCurveSegment has virtual methods"
echo ""

echo "3. Checking Base Classes:"
grep -n "class CIccCurveSegment" IccProfLib/*.h 2>/dev/null | head -5
grep -n "class CIccFormulaCurveSegment" IccProfLib/*.h 2>/dev/null | head -5
grep -n "class CIccSampledCurveSegment" IccProfLib/*.h 2>/dev/null | head -5
echo ""

echo "4. Corpus Status:"
echo "   Local corpus files: $(find corpus/ -type f | wc -l)"
echo "   Total size: $(du -sh corpus/ 2>/dev/null | cut -f1)"
echo ""

echo "=== Recommended Actions ==="
echo ""
echo "PRIORITY 1: Fix Dynamic Cast Issue"
echo "  - Check if base classes are polymorphic"
echo "  - If not, revert to safe C-style cast with runtime checks"
echo "  - Or add virtual destructor to base classes"
echo ""

echo "PRIORITY 2: Fix Corpus"
echo "  - Option A: Commit small corpus to repo"
echo "  - Option B: Configure GCS bucket in project.yaml"
echo "  - Option C: Use Testing/ files as seed corpus"
echo ""

echo "PRIORITY 3: Verify RTTI"
echo "  - Check build flags include -frtti"
echo "  - Verify no -fno-rtti in CMake files"
echo ""

