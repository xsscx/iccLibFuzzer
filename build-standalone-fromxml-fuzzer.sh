#!/bin/bash
set -euo pipefail

# Standalone FromXML Fuzzer Build Script
# Host-optimized: W5-2465X 32-core system  
# Reference: .llmcjf-config.yaml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build-standalone-fromxml"
SANITIZER="${1:-address}"

echo "Building standalone icc_fromxml_fuzzer with $SANITIZER sanitizer..."

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with sanitizer
cmake "$SCRIPT_DIR/Build/Cmake" \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_CXX_FLAGS="-O2 -g -fsanitize=$SANITIZER,fuzzer-no-link -march=native" \
  -DCMAKE_C_FLAGS="-O2 -g -fsanitize=$SANITIZER,fuzzer-no-link -march=native"

# Build libraries (W5-2465X: 32 cores)
make -j32 IccProfLib2-static IccXML2-static

# Build standalone fuzzer
echo "Compiling standalone fuzzer binary..."
clang++ -O2 -g -fsanitize=$SANITIZER,fuzzer \
  -march=native \
  -I"$SCRIPT_DIR/IccProfLib" \
  -I"$SCRIPT_DIR/IccXML/IccLibXML" \
  -I/usr/include/libxml2 \
  "$SCRIPT_DIR/fuzzers/icc_fromxml_fuzzer.cpp" \
  -o icc_fromxml_fuzzer_standalone \
  IccXML/libIccXML2-static.a \
  IccProfLib/libIccProfLib2-static.a \
  -lxml2

echo "✓ Standalone fuzzer built: $BUILD_DIR/icc_fromxml_fuzzer_standalone"
echo ""
echo "Test with:"
echo "  $BUILD_DIR/icc_fromxml_fuzzer_standalone $SCRIPT_DIR/corpus/icc_fromxml_standalone/ -runs=100"
