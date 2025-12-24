#!/bin/bash
# Reproduce all PoC artifacts in poc-archive
# Run with UBSan/ASan to verify bugs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== PoC Reproduction Suite ==="
echo "Directory: $SCRIPT_DIR"
echo ""

# Check for fuzzer binaries
BUILD_DIR="../Build"
if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: Build directory not found at $BUILD_DIR"
    echo "Please build fuzzers first:"
    echo "  cd Build && cmake Cmake && make -j32"
    exit 1
fi

# Find fuzzer binaries
FUZZERS=$(find "$BUILD_DIR" -name "icc_*_fuzzer" -type f -executable 2>/dev/null | head -5)
if [ -z "$FUZZERS" ]; then
    echo "ERROR: No fuzzer binaries found"
    echo "Build fuzzers with: cd Build && make -j32"
    exit 1
fi

echo "Found fuzzers:"
echo "$FUZZERS" | while read f; do echo "  - $(basename $f)"; done
echo ""

# Test mode
TEST_MODE="${1:-validate}"  # validate, full, or leak-only

case "$TEST_MODE" in
    validate)
        echo "Mode: VALIDATE (quick check)"
        TIMEOUT=1
        ;;
    full)
        echo "Mode: FULL (complete reproduction)"
        TIMEOUT=10
        ;;
    leak-only)
        echo "Mode: LEAK-ONLY"
        TIMEOUT=5
        ;;
    *)
        echo "Usage: $0 [validate|full|leak-only]"
        exit 1
        ;;
esac
echo ""

# Process each artifact
TOTAL=0
REPRODUCED=0

for artifact in crash-* leak-* oom-*; do
    [ -f "$artifact" ] || continue
    
    TOTAL=$((TOTAL + 1))
    TYPE=$(echo "$artifact" | cut -d'-' -f1)
    
    # Skip OOMs in validate mode
    if [ "$TEST_MODE" = "leak-only" ] && [ "$TYPE" != "leak" ]; then
        continue
    fi
    
    echo "[$TOTAL] Testing: $artifact ($TYPE)"
    
    # Try each fuzzer with the artifact
    FOUND=false
    for fuzzer_path in $FUZZERS; do
        FUZZER=$(basename "$fuzzer_path")
        
        # Run with timeout
        OUTPUT=$(timeout $TIMEOUT "$fuzzer_path" "$artifact" 2>&1 || true)
        
        # Check for expected sanitizer output
        if echo "$OUTPUT" | grep -q -E "(ERROR|SUMMARY|LeakSanitizer|AddressSanitizer|UndefinedBehaviorSanitizer)"; then
            echo "  ✓ Reproduced with $FUZZER"
            REPRODUCED=$((REPRODUCED + 1))
            FOUND=true
            
            # Show first error line
            echo "$OUTPUT" | grep -E "(ERROR|SUMMARY)" | head -1 | sed 's/^/    /'
            break
        fi
    done
    
    if [ "$FOUND" = "false" ]; then
        echo "  - Could not reproduce (may be fixed)"
    fi
    echo ""
done

echo "=== Summary ==="
echo "Total artifacts: $TOTAL"
echo "Reproduced: $REPRODUCED"
echo "Fixed/non-repro: $((TOTAL - REPRODUCED))"
