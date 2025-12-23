#!/bin/bash
# Test ClusterFuzzLite build configuration locally

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "=========================================="
echo "ClusterFuzzLite Build Verification"
echo "=========================================="

# Simulate ClusterFuzzLite environment variables
export SRC="$REPO_ROOT"
export OUT="$REPO_ROOT/cfl-test-output"
export CC=clang
export CXX=clang++
export CFLAGS="-O1 -fno-omit-frame-pointer -gline-tables-only -fsanitize=address,fuzzer-no-link"
export CXXFLAGS="-O1 -fno-omit-frame-pointer -gline-tables-only -fsanitize=address,fuzzer-no-link"
export LIB_FUZZING_ENGINE="-fsanitize=fuzzer"

# Clean up previous test output
rm -rf "$OUT"
mkdir -p "$OUT"

echo ""
echo "Environment:"
echo "  SRC=$SRC"
echo "  OUT=$OUT"
echo "  CC=$CC"
echo "  CXX=$CXX"
echo ""

# Run the build script
echo "Running .clusterfuzzlite/build.sh..."
bash .clusterfuzzlite/build.sh

echo ""
echo "=========================================="
echo "Build Results"
echo "=========================================="

# List built fuzzers
echo ""
echo "Fuzzers built:"
ls -lh "$OUT"/*_fuzzer 2>/dev/null || echo "  No fuzzers found!"

# Count seed corpus files
echo ""
echo "Seed corpus:"
for corpus_dir in "$OUT"/*_seed_corpus; do
  if [ -d "$corpus_dir" ]; then
    count=$(ls -1 "$corpus_dir" 2>/dev/null | wc -l)
    echo "  $(basename "$corpus_dir"): $count files"
  fi
done

# Test each fuzzer with minimal run
echo ""
echo "=========================================="
echo "Quick Smoke Test (5 seconds each)"
echo "=========================================="

for fuzzer in "$OUT"/*_fuzzer; do
  if [ -f "$fuzzer" ]; then
    fuzzer_name=$(basename "$fuzzer")
    corpus_dir="${fuzzer}_seed_corpus"
    
    echo ""
    echo "Testing $fuzzer_name..."
    
    if [ -d "$corpus_dir" ]; then
      timeout 10 "$fuzzer" "$corpus_dir" \
        -max_total_time=5 \
        -detect_leaks=0 \
        -rss_limit_mb=1024 2>&1 | tail -5 || true
    else
      echo "  No seed corpus found, skipping"
    fi
  fi
done

echo ""
echo "=========================================="
echo "Verification Complete"
echo "=========================================="
echo ""
echo "Output directory: $OUT"
echo "To run a fuzzer manually:"
echo "  $OUT/icc_fromxml_fuzzer $OUT/icc_fromxml_fuzzer_seed_corpus -max_total_time=60"
echo ""
