#!/bin/bash -e

# Reproduce a crash from saved crash file
# Usage: ./reproduce-crash.sh <crash-file> [sanitizer]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <crash-file> [sanitizer]"
    echo ""
    echo "Example:"
    echo "  $0 ./fuzzers-local/address/crashes/crash-65ef4d68b9130afc31c6bd25338629678b0933c3"
    echo "  $0 ./fuzzers-local/address/crashes/crash-65ef4d68b9130afc31c6bd25338629678b0933c3 address"
    exit 1
fi

CRASH_FILE="$1"
SANITIZER="${2:-address}"

if [ ! -f "$CRASH_FILE" ]; then
    echo "Error: Crash file not found: $CRASH_FILE"
    exit 1
fi

# Extract fuzzer name from crash file directory structure
FUZZER_DIR="$(pwd)/fuzzers-local/$SANITIZER"

echo "========================================"
echo "Reproducing crash with all fuzzers"
echo "Crash file: $CRASH_FILE"
echo "Sanitizer: $SANITIZER"
echo "========================================"
echo ""

# Try all fuzzers to see which one crashes
for FUZZER_BIN in "$FUZZER_DIR"/icc_*_fuzzer; do
    if [ -x "$FUZZER_BIN" ]; then
        FUZZER_NAME=$(basename "$FUZZER_BIN")
        echo "Testing $FUZZER_NAME..."
        
        # Run fuzzer with crash file (will exit non-zero if it crashes)
        if ! "$FUZZER_BIN" "$CRASH_FILE" 2>&1 | head -100; then
            echo ""
            echo "========================================"
            echo "CRASH REPRODUCED with: $FUZZER_NAME"
            echo "========================================"
            exit 0
        fi
    fi
done

echo ""
echo "========================================"
echo "No crash reproduced (bug may be fixed)"
echo "========================================"
