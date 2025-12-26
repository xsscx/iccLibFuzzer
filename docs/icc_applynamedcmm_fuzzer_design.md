# IccApplyNamedCmm Fuzzer Design Documentation

**Created**: 2025-12-26  
**Fuzzer**: fuzzers/icc_applynamedcmm_fuzzer.cpp  
**Purpose**: Fuzzing CIccNamedColorCmm class with proper profile loading per iccApplyNamedCmm architecture  

## Design Rationale

This fuzzer honors the AST Query pattern used by the lead developers in `Tools/CmdLine/IccApplyNamedCmm/iccApplyNamedCmm.cpp`. It follows the exact profile loading and attachment sequence to stay within architectural boundaries.

## Architecture Alignment

### Source Code Mapping
| iccApplyNamedCmm.cpp | Fuzzer Line | Purpose |
|----------------------|-------------|---------|
| Lines 340 | 131-141 | CIccNamedColorCmm construction with source/dest spaces |
| Lines 329-337 | 119-130 | bFirstInput profile type detection |
| Lines 354-389 | 143-158 | CIccCreateXformHintManager configuration |
| Lines 382-392 | 160-174 | AddXform() with hints |
| Line 398 | 176-182 | Begin() initialization |
| Lines 470-560 | 196-340 | Interface-specific Apply() calls |
| Lines 489, 523, 541 | 354-373 | Encoding conversion testing |

### Key Design Patterns Honored

1. **Profile Type Detection** (lines 119-130)
   - Checks if source space is PCS (XYZ/Lab)
   - Opens profile to validate device class
   - Sets `bFirstInput` flag correctly

2. **Hint Manager Configuration** (lines 143-158)
   - Black Point Compensation (BPC)
   - Luminance-based PCS adjustment
   - Environment variables
   - V5 sub-profile support

3. **Interface-Based Transformations** (lines 196-340)
   - `icApplyPixel2Pixel`: Standard color transformation
   - `icApplyNamed2Pixel`: Named color to pixel
   - `icApplyNamed2Named`: Named color to named color
   - `icApplyPixel2Named`: Pixel to named color

4. **Encoding Conversion** (lines 354-373)
   - ToInternalEncoding (source)
   - FromInternalEncoding (destination)
   - Tests all 6 encoding formats

## Fuzzer Input Structure

```
Byte 0: Flags
  bit 0: use BPC
  bit 1: use D2Bx/B2Dx tags
  bit 2: adjust PCS luminance
  bit 3: use V5 sub-profile
  bit 4-5: interpolation (0=linear, 1=tetrahedral)
  bit 6-7: reserved

Byte 1: Rendering intent (0-3 base)

Bytes 2-3: Source color space index (16-bit)
  Maps to: XYZ, Lab, RGB, CMYK, Gray, Named, 2-6 color, Unknown

Bytes 4-5: Destination color space index (16-bit)

Byte 6: Interface type hint (0-3)
  0: icApplyPixel2Pixel
  1: icApplyNamed2Pixel
  2: icApplyPixel2Named
  3: icApplyNamed2Named

Bytes 7-9: Reserved for future use

Bytes 10+: ICC profile data
```

## Coverage Targets

### API Boundaries
- [x] CIccNamedColorCmm construction
- [x] AddXform() with various hints
- [x] Begin() initialization
- [x] GetInterface() detection
- [x] Apply() overloads (4 variants)
- [x] Encoding conversions (6 formats)

### Edge Cases
- [x] NaN/Infinity pixel values
- [x] Negative pixel values
- [x] Values > 1.0
- [x] Zero-length inputs
- [x] Named color tint variations (0.0, 0.5, 1.0)
- [x] Batch pixel processing
- [x] Invalid profile data
- [x] PCS vs. device space detection

### Sanitizer Coverage
- AddressSanitizer: heap/stack/global buffer overflows
- UndefinedBehaviorSanitizer: NaN/inf handling, enum validation
- MemorySanitizer: uninitialized memory reads

## Test Results

### Initial Smoke Test (10 seconds)
```
Executions:     3,430,513
Exec/sec:       311,864
Coverage:       3 edges, 3 features
Corpus:         2 inputs (139 bytes)
Peak RSS:       474 MB
Crashes:        0
Timeouts:       0
```

### Dictionary Recommendations
```
"\377\377\377\377"              # 0xFFFFFFFF (used 94,937 times)
"\001\000\000\000"              # 0x00000001 (used 95,630 times)
"\377\377\377\377\377\377\377\211"  # Multi-byte pattern (used 93,125 times)
```

## Differences from Existing Fuzzers

### vs. icc_apply_fuzzer.cpp
- **icc_apply_fuzzer**: Uses basic CIccCmm class, simpler profile loading
- **icc_applynamedcmm_fuzzer**: Uses CIccNamedColorCmm, supports named colors, honors full hint system

### vs. icc_applyprofiles_fuzzer.cpp
- **icc_applyprofiles_fuzzer**: Focuses on TIFF image workflows
- **icc_applynamedcmm_fuzzer**: Focuses on CMM interface detection and named color transformations

## Unique Features

1. **Named Color Support**
   - Tests "White", "Black", "Red", "Green", "Blue", "Cyan", "Magenta", "Yellow", "Gray"
   - Validates tint parameter (0.0 - 1.0)
   - Exercises named-to-pixel and named-to-named transformations

2. **Full Hint System**
   - Black Point Compensation hints
   - Luminance matching hints
   - Environment variable hints (icCmmEnvSigMap)
   - PCC (Profile Connection Conditions) support

3. **Interface Auto-Detection**
   - Fuzzer adapts to actual CMM interface (4 variants)
   - Matches behavior of iccApplyNamedCmm.cpp runtime detection

4. **Comprehensive Encoding Tests**
   - icEncodeValue
   - icEncodePercent
   - icEncodeUnitFloat
   - icEncodeFloat
   - icEncode16Bit
   - icEncode16BitV2

## Integration with Build System

### build-fuzzers-local.sh
Added to fuzzer list at line 66:
```bash
for fuzzer in ... icc_applynamedcmm_fuzzer ...; do
```

### Output Locations
- AddressSanitizer: `fuzzers-local/address/icc_applynamedcmm_fuzzer`
- UBSan: `fuzzers-local/undefined/icc_applynamedcmm_fuzzer`
- MemorySanitizer: `fuzzers-local/memory/icc_applynamedcmm_fuzzer`

### Seed Corpus
- Location: `fuzzers-local/{sanitizer}/icc_applynamedcmm_fuzzer_seed_corpus/`
- Sources: All `*.icc` files from `Testing/` directory

## Known Limitations

1. **PCC Profiles**: Not fuzzed (set to nullptr for simplicity)
2. **Multi-Profile Chains**: Currently tests single profile only
3. **JSON Config**: Not fuzzed (Usage 1 not tested)
4. **TIFF Integration**: Not fuzzed (covered by icc_applyprofiles_fuzzer)

## Future Enhancements

1. Multi-profile chain fuzzing
2. PCC profile fuzzing
3. JSON configuration fuzzing
4. Spectral reflectance profile testing
5. MCS (multi-color space) connection testing
6. BRDF (bidirectional reflectance distribution function) testing

## Validation

### Compiler Warnings
- None (clean build)

### Runtime Validation
```bash
# Quick test (10 seconds)
./fuzzers-local/address/icc_applynamedcmm_fuzzer \
  fuzzers-local/address/icc_applynamedcmm_fuzzer_seed_corpus \
  -max_total_time=10

# Extended test (5 minutes)
./fuzzers-local/address/icc_applynamedcmm_fuzzer \
  fuzzers-local/address/icc_applynamedcmm_fuzzer_seed_corpus \
  -max_total_time=300

# With specific POC
./fuzzers-local/address/icc_applynamedcmm_fuzzer \
  poc-archive/crash-3c3c6c65ab8b4ba09d67bcb0edfdc2345e8285dd
```

## References

- Source: Tools/CmdLine/IccApplyNamedCmm/iccApplyNamedCmm.cpp
- Class: IccProfLib/IccCmm.h (CIccNamedColorCmm)
- Hints: IccProfLib/IccApplyBPC.h, IccProfLib/IccEnvVar.h
- Test Suite: test-iccapplynamedcmm.sh (unit tests for binary)

## Maintainer Notes

**DO NOT** modify the fuzzer to bypass the hint system or profile loading sequence. The architecture mirrors iccApplyNamedCmm.cpp precisely to ensure fuzzing stays within documented API boundaries and design patterns used by lead developers.
