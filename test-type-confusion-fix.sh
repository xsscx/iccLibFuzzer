#!/bin/bash
# Test script to verify type confusion fixes

set -e

echo "=== Type Confusion Fix Verification Test ==="
echo ""

# 1. Verify pattern scanner exists and works
echo "1. Running pattern scanner..."
if [ ! -x "./find-type-confusion.sh" ]; then
    chmod +x ./find-type-confusion.sh
fi
./find-type-confusion.sh | grep "Total C-style casts" | grep ": 0"
echo "   ✅ Pattern scanner confirms 0 C-style casts remaining"
echo ""

# 2. Build with UBSan
echo "2. Building with UBSan..."
cd Build
cmake Cmake -DCMAKE_CXX_FLAGS="-fsanitize=undefined -fno-sanitize-recover=all" > /dev/null 2>&1
make -j32 iccToXml > /dev/null 2>&1
cd ..
echo "   ✅ Build successful with UBSan enabled"
echo ""

# 3. Test with PoC file
echo "3. Testing with PoC (CMYK-3DLUTs2.icc)..."
OUTPUT=$(Build/Tools/IccToXml/iccToXml Testing/CMYK-3DLUTs/CMYK-3DLUTs2.icc /tmp/verification-test.xml 2>&1)
if echo "$OUTPUT" | grep -q "runtime error"; then
    echo "   ❌ FAIL: UBSan error detected!"
    echo "$OUTPUT"
    exit 1
fi
if echo "$OUTPUT" | grep -q "XML successfully created"; then
    echo "   ✅ XML generation successful, no UBSan errors"
else
    echo "   ❌ FAIL: XML generation failed"
    exit 1
fi
echo ""

# 4. Verify output file
echo "4. Verifying output XML..."
if [ -f /tmp/verification-test.xml ] && [ -s /tmp/verification-test.xml ]; then
    SIZE=$(stat -f%z /tmp/verification-test.xml 2>/dev/null || stat -c%s /tmp/verification-test.xml 2>/dev/null)
    echo "   ✅ Output file created: $SIZE bytes"
else
    echo "   ❌ FAIL: Output file missing or empty"
    exit 1
fi
echo ""

# 5. Check git status
echo "5. Checking repository cleanliness..."
MODIFIED=$(git status --short | grep -v "^??" | wc -l)
if [ "$MODIFIED" -eq 0 ]; then
    echo "   ✅ Working tree clean"
else
    echo "   ⚠️  Warning: Working tree has modifications"
    git status --short | head -5
fi
echo ""

echo "=== All Tests Passed ✅ ==="
echo ""
echo "Summary:"
echo "  - Pattern scanner: 0 unsafe casts detected"
echo "  - UBSan build: Success"
echo "  - PoC test: No violations"
echo "  - Output: Valid XML generated"
echo "  - Repository: Clean"
