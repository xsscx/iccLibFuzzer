#!/bin/bash -eu

# Local fuzzer build script for reproducing ClusterFuzzLite builds
# Output: ./fuzzers-local/{address,undefined,memory}/icc_*_fuzzer

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

SANITIZER="${1:-address}"
OUTPUT_DIR="$REPO_ROOT/fuzzers-local/$SANITIZER"

echo "Building fuzzers with $SANITIZER sanitizer to $OUTPUT_DIR"

# Set compiler flags based on sanitizer
# W5-2465X optimization: 24 threads, NVMe SSD
case "$SANITIZER" in
  address)
    CFLAGS="-O2 -fno-omit-frame-pointer -gline-tables-only -fsanitize=address,fuzzer-no-link -march=native"
    CXXFLAGS="-O2 -fno-omit-frame-pointer -gline-tables-only -fsanitize=address,fuzzer-no-link -march=native"
    LINK_FLAGS="-fsanitize=fuzzer"
    ;;
  undefined)
    CFLAGS="-O2 -fno-omit-frame-pointer -gline-tables-only -fsanitize=undefined,fuzzer-no-link -march=native"
    CXXFLAGS="-O2 -fno-omit-frame-pointer -gline-tables-only -fsanitize=undefined,fuzzer-no-link -march=native"
    LINK_FLAGS="-fsanitize=fuzzer"
    ;;
  memory)
    CFLAGS="-O2 -fno-omit-frame-pointer -gline-tables-only -fsanitize=memory,fuzzer-no-link -fsanitize-memory-track-origins -march=native"
    CXXFLAGS="-O2 -fno-omit-frame-pointer -gline-tables-only -fsanitize=memory,fuzzer-no-link -fsanitize-memory-track-origins -stdlib=libc++ -march=native"
    LINK_FLAGS="-fsanitize=fuzzer -stdlib=libc++"
    ;;
  *)
    echo "Unknown sanitizer: $SANITIZER"
    echo "Usage: $0 [address|undefined|memory]"
    exit 1
    ;;
esac

# Build directory
BUILD_DIR="Build/Cmake/build_local_${SANITIZER}_$(date +%s)"
mkdir -p "$BUILD_DIR"

# Build IccProfLib
cd "$REPO_ROOT/Build/Cmake"
cmake -B "$BUILD_DIR" -S . \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBUILD_SHARED_LIBS=OFF

cmake --build "$BUILD_DIR" --target IccProfLib2-static -j24
cmake --build "$BUILD_DIR" --target IccXML2-static -j24

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build fuzzers
cd "$REPO_ROOT"
for fuzzer in icc_link_fuzzer icc_dump_fuzzer icc_apply_fuzzer icc_applyprofiles_fuzzer icc_roundtrip_fuzzer icc_profile_fuzzer icc_io_fuzzer icc_spectral_fuzzer icc_calculator_fuzzer icc_multitag_fuzzer; do
  echo "Building $fuzzer..."
  clang++ $CXXFLAGS \
    -I"$REPO_ROOT/IccProfLib" \
    -I"$REPO_ROOT/Tools/CmdLine/IccCommon" \
    -I"$REPO_ROOT/Tools/CmdLine/IccApplyProfiles" \
    "$REPO_ROOT/fuzzers/${fuzzer}.cpp" \
    "$REPO_ROOT/Build/Cmake/$BUILD_DIR/IccProfLib/libIccProfLib2-static.a" \
    $LINK_FLAGS \
    -o "$OUTPUT_DIR/${fuzzer}"
  
  # Copy seed corpus
  mkdir -p "$OUTPUT_DIR/${fuzzer}_seed_corpus"
  cp "$REPO_ROOT"/Testing/*.icc "$OUTPUT_DIR/${fuzzer}_seed_corpus/" 2>/dev/null || true
done

# Build XML fuzzers separately (requires IccXML library)
for fuzzer in icc_fromxml_fuzzer icc_toxml_fuzzer; do
  echo "Building $fuzzer..."
  clang++ $CXXFLAGS \
    -I"$REPO_ROOT/IccProfLib" \
    -I"$REPO_ROOT/IccXML/IccLibXML" \
    -I/usr/include/libxml2 \
    -DHAVE_ICCXML \
    "$REPO_ROOT/fuzzers/${fuzzer}.cpp" \
    "$REPO_ROOT/Build/Cmake/$BUILD_DIR/IccXML/libIccXML2-static.a" \
    "$REPO_ROOT/Build/Cmake/$BUILD_DIR/IccProfLib/libIccProfLib2-static.a" \
    -lxml2 \
    $LINK_FLAGS \
    -o "$OUTPUT_DIR/${fuzzer}"
  
  # Copy appropriate seed corpus
  mkdir -p "$OUTPUT_DIR/${fuzzer}_seed_corpus"
  if [ "$fuzzer" = "icc_fromxml_fuzzer" ]; then
    find "$REPO_ROOT/Testing" -name "*.xml" -exec cp {} "$OUTPUT_DIR/${fuzzer}_seed_corpus/" \; 2>/dev/null || true
  else
    cp "$REPO_ROOT"/Testing/*.icc "$OUTPUT_DIR/${fuzzer}_seed_corpus/" 2>/dev/null || true
  fi
done

echo "✓ Fuzzers built in: $OUTPUT_DIR"
echo ""
echo "Available fuzzers:"
ls -1 "$OUTPUT_DIR"/icc_*_fuzzer 2>/dev/null | xargs -n1 basename
echo ""
echo "Run examples:"
echo "  $OUTPUT_DIR/icc_profile_fuzzer $OUTPUT_DIR/icc_profile_fuzzer_seed_corpus -max_total_time=60"
echo "  $OUTPUT_DIR/icc_fromxml_fuzzer $OUTPUT_DIR/icc_fromxml_fuzzer_seed_corpus -max_total_time=60"
echo "  $OUTPUT_DIR/icc_spectral_fuzzer $OUTPUT_DIR/icc_spectral_fuzzer_seed_corpus -max_total_time=60"
