#!/bin/bash -eu

# ClusterFuzzLite Build Script
# Host-optimized: W5-2465X 32-core system
# Reference: .llmcjf-config.yaml, llmcjf/profiles/strict_engineering.yaml

# Clean all previous fuzzer binaries
cd $SRC/ipatch/fuzzers
make clean 2>/dev/null || true
rm -f icc_profile_fuzzer icc_roundtrip_fuzzer icc_apply_fuzzer icc_dump_fuzzer icc_link_fuzzer

# Use unique build directory to avoid any caching
BUILD_DIR="build_$(date +%s)_$$"
cd $SRC/ipatch/Build/Cmake

# Remove any old build directories
rm -rf build_* build/ CMakeCache.txt Makefile *.cmake CMakeFiles/

cd $SRC/ipatch/Build/Cmake

cmake -B $BUILD_DIR -S . \
  -DCMAKE_C_COMPILER=$CC \
  -DCMAKE_CXX_COMPILER=$CXX \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS -frtti" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBUILD_SHARED_LIBS=OFF

cmake --build $BUILD_DIR --target IccProfLib2-static -j$(nproc)
cmake --build $BUILD_DIR --target IccXML2-static -j$(nproc) || true

# Build TiffImg object for TIFF-dependent fuzzers
$CXX $CXXFLAGS -frtti \
  -I$SRC/ipatch/IccProfLib \
  -I$SRC/ipatch/Tools/CmdLine/IccCommon \
  -I$SRC/ipatch/Tools/CmdLine/IccApplyProfiles \
  -c $SRC/ipatch/Tools/CmdLine/IccApplyProfiles/TiffImg.cpp \
  -o $BUILD_DIR/TiffImg.o

# Build all fuzzers
for fuzzer in icc_link_fuzzer icc_dump_fuzzer icc_apply_fuzzer icc_applyprofiles_fuzzer icc_roundtrip_fuzzer icc_profile_fuzzer icc_io_fuzzer icc_spectral_fuzzer icc_calculator_fuzzer icc_multitag_fuzzer; do
  $CXX $CXXFLAGS \
    -I$SRC/ipatch/IccProfLib \
    -I$SRC/ipatch/Tools/CmdLine/IccCommon \
    -I$SRC/ipatch/Tools/CmdLine/IccApplyProfiles \
    $SRC/ipatch/fuzzers/${fuzzer}.cpp \
    $BUILD_DIR/IccProfLib/libIccProfLib2-static.a \
    $LIB_FUZZING_ENGINE \
    -o $OUT/${fuzzer}
  
  # Copy seed corpus
  mkdir -p $OUT/${fuzzer}_seed_corpus
  cp $SRC/ipatch/Testing/*.icc $OUT/${fuzzer}_seed_corpus/ 2>/dev/null || true
  
  # Copy dictionary for ICC binary fuzzers
  if [ -f "$SRC/ipatch/fuzzers/icc_profile.dict" ]; then
    cp $SRC/ipatch/fuzzers/icc_profile.dict $OUT/${fuzzer}.dict
  fi
done

# Build XML fuzzers (requires IccXML library)
if [ -f "$BUILD_DIR/IccXML/libIccXML2-static.a" ]; then
  for fuzzer in icc_fromxml_fuzzer icc_toxml_fuzzer; do
    echo "Building $fuzzer with IccXML library..."
    $CXX $CXXFLAGS -frtti \
      -I$SRC/ipatch/IccProfLib \
      -I$SRC/ipatch/IccXML/IccLibXML \
      -I/usr/include/libxml2 \
      -DHAVE_ICCXML \
      $SRC/ipatch/fuzzers/${fuzzer}.cpp \
      $BUILD_DIR/IccXML/libIccXML2-static.a \
      $BUILD_DIR/IccProfLib/libIccProfLib2-static.a \
      -lxml2 \
      $LIB_FUZZING_ENGINE \
      -o $OUT/${fuzzer}
    
    # Copy appropriate seed corpus
    mkdir -p $OUT/${fuzzer}_seed_corpus
    if [ "$fuzzer" = "icc_fromxml_fuzzer" ]; then
      # XML files for fromxml
      find $SRC/ipatch/Testing -name "*.xml" -exec cp {} $OUT/${fuzzer}_seed_corpus/ \; 2>/dev/null || true
    else
      # ICC files for toxml
      cp $SRC/ipatch/Testing/*.icc $OUT/${fuzzer}_seed_corpus/ 2>/dev/null || true
    fi
    echo "$fuzzer built successfully with $(ls $OUT/${fuzzer}_seed_corpus 2>/dev/null | wc -l) seed files"
  done
else
  echo "Warning: IccXML2-static.a not found, skipping XML fuzzers"
fi




