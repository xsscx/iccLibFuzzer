# Standalone icc_fromxml_fuzzer

## Overview

Standalone LibFuzzer binary for testing ICC XML-to-profile conversion using Commodity Injection Signatures from xsscx/Commodity-Injection-Signatures repository.

## Build

```bash
./build-standalone-fromxml-fuzzer.sh address
```

**Output:** `build-standalone-fromxml/icc_fromxml_fuzzer_standalone`

## Corpus

**Location:** `corpus/icc_fromxml_standalone/`  
**Files:** 9 XML files (sRGB_D65_colorimetric_*.xml)  
**Size:** ~60KB each, 540KB total  
**Source:** https://github.com/xsscx/Commodity-Injection-Signatures/tree/master/xml/icc

### Seed Files:
1. sRGB_D65_colorimetric_94578.xml
2. sRGB_D65_colorimetric_8590.xml
3. sRGB_D65_colorimetric_80278.xml
4. sRGB_D65_colorimetric_72115.xml
5. sRGB_D65_colorimetric_61477.xml
6. sRGB_D65_colorimetric_448.xml
7. sRGB_D65_colorimetric_42752.xml
8. sRGB_D65_colorimetric_21981.xml
9. sRGB_D65_colorimetric_20483.xml

## Usage

### Quick Test (100 runs):
```bash
cd build-standalone-fromxml
./icc_fromxml_fuzzer_standalone ../corpus/icc_fromxml_standalone/ -runs=100
```

### Continuous Fuzzing (1 hour):
```bash
./icc_fromxml_fuzzer_standalone \
  ../corpus/icc_fromxml_standalone/ \
  -max_total_time=3600 \
  -print_final_stats=1
```

### Find Crashes:
```bash
mkdir crashes
./icc_fromxml_fuzzer_standalone \
  ../corpus/icc_fromxml_standalone/ \
  -artifact_prefix=crashes/ \
  -max_total_time=7200
```

## Coverage

**Initial Test Results:**
- Coverage: 2075 edges
- Features: 2572
- Corpus growth: 9 → 15 inputs
- Execution rate: ~1000 exec/s
- RSS: ~113MB

## Sanitizers

Build with different sanitizers:

```bash
./build-standalone-fromxml-fuzzer.sh address    # AddressSanitizer
./build-standalone-fromxml-fuzzer.sh undefined  # UBSan
./build-standalone-fromxml-fuzzer.sh memory     # MSan
```

## Targets

**Primary Vulnerability Classes:**
- XML parser errors (malformed tags, invalid chars)
- NULL pointer dereferences in tag parsing
- Heap buffer overflows in unicode processing
- Type confusion in tag conversion
- NaN/Infinity in numeric fields

**Code Paths:**
- `CIccProfileXml::LoadXml()` - XML parsing entry point
- `CIccTagCreator` factories - Tag creation from XML
- `SaveIccProfile()` - XML → ICC binary conversion
- Tag validation and serialization

## Output

Fuzzer artifacts saved to `/tmp/`:
- `/tmp/fuzz_icc_xml_XXXXXX` - Temporary XML input
- `/tmp/fuzz_icc_out_XXXXXX` - Temporary ICC output

## Performance

**Optimizations:**
- Native CPU instructions (`-march=native`)
- -O2 optimization level
- 24-core parallel execution potential

**Expected throughput:**
- ~1000-1500 exec/s (single core)
- ~24K-36K exec/s (24 cores with parallel instances)

## Integration

### ClusterFuzzLite:
Already integrated via `icc_fromxml_fuzzer.cpp` in main fuzzing suite.

### Standalone Use:
Ideal for local development, targeted testing, and crash reproduction.

---
**Created:** 2025-12-21  
**Build Script:** `build-standalone-fromxml-fuzzer.sh`  
**Fuzzer Source:** `fuzzers/icc_fromxml_fuzzer.cpp`
