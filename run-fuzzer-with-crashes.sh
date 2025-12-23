#!/bin/bash -e

# Run fuzzer with crash preservation
# Usage: ./run-fuzzer-with-crashes.sh [sanitizer] [fuzzer] [duration]

SANITIZER="${1:-address}"
FUZZER="${2:-icc_profile_fuzzer}"
DURATION="${3:-300}"

CRASH_DIR="$(pwd)/fuzzer-crashes-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CRASH_DIR"

echo "Running fuzzer with crash preservation..."
echo "Sanitizer: $SANITIZER"
echo "Fuzzer: $FUZZER"
echo "Duration: ${DURATION}s"
echo "Crashes will be saved to: $CRASH_DIR"
echo ""

docker run --rm \
  -v "$CRASH_DIR:/fuzzers/crashes" \
  -e SANITIZER="$SANITIZER" \
  -e FUZZER="$FUZZER" \
  -e DURATION="$DURATION" \
  -e JOBS="$(nproc)" \
  lf:latest

echo ""
echo "========================================"
echo "Fuzzing complete!"
echo "Crash files: $CRASH_DIR"
ls -lh "$CRASH_DIR/" 2>/dev/null || echo "No crashes found (good!)"
echo "========================================"
