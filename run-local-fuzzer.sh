#!/bin/bash -e

# Run local fuzzer with crash preservation
# Usage: ./run-local-fuzzer.sh [sanitizer] [fuzzer] [duration]
# Defaults: address icc_profile_fuzzer 60

SANITIZER="${1:-address}"
FUZZER="${2:-icc_profile_fuzzer}"
DURATION="${3:-60}"

FUZZER_DIR="$(pwd)/fuzzers-local/$SANITIZER"
CRASH_DIR="$FUZZER_DIR/crashes"
CORPUS_DIR="$FUZZER_DIR/${FUZZER}_seed_corpus"

if [ ! -x "$FUZZER_DIR/$FUZZER" ]; then
    echo "Error: Fuzzer not found: $FUZZER_DIR/$FUZZER"
    echo "Available sanitizers: address, undefined, memory"
    echo "Run: ./build-fuzzers-local.sh $SANITIZER"
    exit 1
fi

if [ ! -d "$CORPUS_DIR" ]; then
    echo "Error: Corpus not found: $CORPUS_DIR"
    echo "Run: ./populate-corpus.sh"
    exit 1
fi

CORPUS_COUNT=$(find "$CORPUS_DIR" -type f | wc -l)

mkdir -p "$CRASH_DIR"
CRASH_DIR_ABS="$(realpath "$CRASH_DIR")"
CORPUS_DIR_ABS="$(realpath "$CORPUS_DIR")"

echo "========================================"
echo "Running: $FUZZER"
echo "Sanitizer: $SANITIZER"
echo "Duration: ${DURATION}s"
echo "Corpus: $CORPUS_DIR_ABS ($CORPUS_COUNT files)"
echo "Crash dir: $CRASH_DIR_ABS"
echo "========================================"
echo ""

cd "$FUZZER_DIR"
./$FUZZER \
    "$CORPUS_DIR_ABS/" \
    -artifact_prefix="$CRASH_DIR_ABS/" \
    -max_total_time=$DURATION \
    -timeout=120 \
    -rss_limit_mb=6144 \
    -max_len=10000000 \
    -detect_leaks=0 \
    || true

echo ""
echo "========================================"
echo "Fuzzing complete!"
echo "Crash dir: $CRASH_DIR"
CRASH_COUNT=$(find "$CRASH_DIR" -type f \( -name "crash-*" -o -name "leak-*" -o -name "oom-*" -o -name "timeout-*" \) 2>/dev/null | wc -l)
if [ "$CRASH_COUNT" -gt 0 ]; then
    echo "Found $CRASH_COUNT artifact(s):"
    find "$CRASH_DIR" -type f \( -name "crash-*" -o -name "leak-*" -o -name "oom-*" -o -name "timeout-*" \) -exec ls -lh {} \;
else
    echo "No crashes found"
fi
echo "========================================"
