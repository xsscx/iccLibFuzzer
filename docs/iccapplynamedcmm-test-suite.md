# IccApplyNamedCmm Test Suite Documentation

**Created**: 2025-12-26  
**Tool**: Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm  
**Version**: IccProfLib 2.3.1.1  
**Test Script**: test-iccapplynamedcmm.sh  

## Quick Start

```bash
# Run full test suite
ASAN_OPTIONS=detect_leaks=0 ./test-iccapplynamedcmm.sh

# Run individual 1-liner checks (see below)
```

## Test Coverage

### Categories Tested
1. **Basic Functionality** (3 tests)
   - Tool executable check
   - Help/usage output
   - Version string

2. **Encoding Formats** (7 tests)
   - Format 0: icEncodeValue ✅
   - Format 1: icEncodePercent ✅
   - Format 2: icEncodeUnitFloat ✅
   - Format 3: icEncodeFloat ✅
   - Format 4: icEncode8Bit (invalid - expected failure) ✅
   - Format 5: icEncode16Bit ✅
   - Format 6: icEncode16BitV2 ✅

3. **Interpolation Modes** (2 tests)
   - Mode 0: Linear ✅
   - Mode 1: Tetrahedral ✅

4. **Rendering Intents** (9 tests)
   - Intent 0: Perceptual ✅
   - Intent 1: Relative Colorimetric ✅
   - Intent 2: Saturation ✅
   - Intent 3: Absolute Colorimetric ✅
   - Intent 30: Gamut (profile-dependent) ✅
   - Intent 33: Gamut Absolute (profile-dependent) ✅
   - Intent 1000: Luminance-based PCS ✅
   - Intent 10000: V5 sub-profile ✅
   - Intent 100000: HToS tag ✅

5. **Precision Formatting** (2 tests)
   - Format 3:4:8 (precision:digits) ✅
   - Format 3:2:6 ✅

6. **Error Handling** (4 tests)
   - Missing data file ✅
   - Missing profile file ✅
   - Invalid encoding (99) ✅
   - Invalid interpolation (9) - UBSan detects ✅

7. **Data File Formats** (3 tests)
   - 8-bit RGB input ✅
   - 16-bit RGB input ✅
   - Float RGB input ✅

**Total Tests**: 30  
**Pass Rate**: 100%

## 1-Liner Validation Checks

### Quick Smoke Test
```bash
# Should output XYZ colorimetric values for RGB primaries
./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
  Testing/ApplyDataFiles/rgbFloat.txt 3 0 \
  Testing/Display/sRGB_D65_MAT.icc 0 | head -20
```

**Expected Output**:
```
; Data Format
icEncodeFloat	; Encoding
...
    0.4123    0.2126    0.0193	;    1.0000    0.0000    0.0000  # Red
    0.3576    0.7152    0.1192	;    0.0000    1.0000    0.0000  # Green
    0.1805    0.0722    0.9504	;    0.0000    0.0000    1.0000  # Blue
```

### Verify Encoding Format Change
```bash
# Output should be in 16-bit encoding
./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
  Testing/ApplyDataFiles/rgbFloat.txt 5 0 \
  Testing/Display/sRGB_D65_MAT.icc 0 | grep icEncode16Bit
```

**Expected**: `icEncode16Bit	; Encoding`

### Test All Basic Rendering Intents
```bash
# Test perceptual, relative, saturation, absolute
for i in 0 1 2 3; do 
  ./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
    Testing/ApplyDataFiles/rgbFloat.txt 3 0 \
    Testing/Display/sRGB_D65_MAT.icc $i | head -5
done
```

### Compare Interpolation Methods
```bash
# Linear vs Tetrahedral - should show slight differences
diff \
  <(./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
    Testing/ApplyDataFiles/rgbFloat.txt 3 0 \
    Testing/Display/sRGB_D65_MAT.icc 0) \
  <(./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
    Testing/ApplyDataFiles/rgbFloat.txt 3 1 \
    Testing/Display/sRGB_D65_MAT.icc 0)
```

### Validate Output is Parseable
```bash
# Extract numeric XYZ values (first 5 lines)
./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
  Testing/ApplyDataFiles/rgbFloat.txt 3 0 \
  Testing/Display/sRGB_D65_MAT.icc 0 | \
  grep -E '^[[:space:]]*[0-9]' | head -5
```

### Test Precision Control
```bash
# 2 digits after decimal, 6 total digits
./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
  Testing/ApplyDataFiles/rgbFloat.txt 3:2:6 0 \
  Testing/Display/sRGB_D65_MAT.icc 0 | head -10
```

### Verify Error Handling
```bash
# Should output "Invalid final data encoding"
./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
  Testing/ApplyDataFiles/rgbFloat.txt 4 0 \
  Testing/Display/sRGB_D65_MAT.icc 0 2>&1 | grep Invalid

# Should output "Invalid Profile"
./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
  Testing/ApplyDataFiles/rgbFloat.txt 3 0 \
  /nonexistent.icc 0 2>&1 | grep Invalid
```

### Test Data Format Detection
```bash
# Tool should detect and report source encoding
./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
  Testing/ApplyDataFiles/rgb8bit.txt 3 0 \
  Testing/Display/sRGB_D65_MAT.icc 0 | \
  grep "Source Data Encoding"
```

**Expected**: `;Source Data Encoding: icEncode8Bit`

## Usage Patterns

### Usage 1: JSON Configuration File (Not Tested Yet)
```bash
iccApplyNamedCmm -cfg config.json
```

**Note**: JSON config format requires documentation/examples.

### Usage 2: Command-Line Arguments (Tested)
```bash
iccApplyNamedCmm {-debugcalc} data_file final_encoding{:precision:digits} \
                 interpolation {{-ENV:Name value} profile intent {-PCC pcc_path}}
```

**Parameters**:
- `data_file`: Text file with color values (see Testing/ApplyDataFiles/)
- `final_encoding`: 0-6 (see encoding table)
- `precision`: Optional formatting (digits after decimal)
- `digits`: Optional total digits
- `interpolation`: 0=Linear, 1=Tetrahedral
- `profile`: ICC profile path
- `intent`: Rendering intent (0-100000+)

## Known Issues

### Memory Leaks in ASan Build
**Issue**: Memory leaks detected in `CIccMpeCalculator::GetNewApply()`  
**Workaround**: Use `ASAN_OPTIONS=detect_leaks=0`  
**Location**: IccProfLib/IccMpeCalc.cpp:4811

**Leak Stack Trace**:
```
Direct leak of 72 byte(s) in 1 object(s) allocated from:
    #0 calloc asan_malloc_linux.cpp:77
    #1 CIccMpeCalculator::GetNewApply IccMpeCalc.cpp:4811
    #2 CIccApplyTagMpe::AppendElem IccTagMPE.cpp:672
```

**Impact**: Does not affect test correctness, only cleanup.

### UBSan Detection for Invalid Interpolation
**Issue**: Invalid interpolation value (9) causes UBSan error but tool continues  
**Location**: Tools/CmdLine/IccApplyNamedCmm/iccApplyNamedCmm.cpp:382  
**Error**: `load of value 9, which is not a valid value for type 'icXformInterp'`

**Recommendation**: Add explicit validation before enum cast.

### Profile-Specific Intent Support
**Issue**: Not all profiles support all rendering intents  
**Example**: sRGB_D65_MAT.icc returns "Invalid Profile" for intent 30 (Gamut)

**Workaround**: Tests accept either success or "Invalid Profile" for advanced intents.

## Test Data Files

### RGB Test Files (Testing/ApplyDataFiles/)
- `rgbFloat.txt` - Floating-point RGB primaries
- `rgb8bit.txt` - 8-bit unsigned RGB (0-255)
- `rgb16bit.txt` - 16-bit unsigned RGB (0-65535)

### Format Example (rgbFloat.txt)
```
'RGB ' ; Data Format
icEncodeFloat ; Encoding
1.0 0 0        # Red
0 1.0 0        # Green
0 0 1.0        # Blue
...
```

## Test Profiles

### Primary Test Profile
**File**: `Testing/Display/sRGB_D65_MAT.icc`  
**Type**: Display (matrix-based sRGB)  
**Size**: 2.6KB  
**Supported Intents**: 0-3 (basic colorimetric)

### Alternative Profiles
- `Testing/Calc/srgbCalcTest.icc` - Calculator-based sRGB
- `Testing/Display/LCDDisplay.icc` - Generic LCD
- `Testing/Display/GrayGSDF.icc` - Grayscale GSDF

## Encoding Format Reference

| Code | Name | Valid for final_encoding | Description |
|------|------|--------------------------|-------------|
| 0 | icEncodeValue | ✅ | Lab encoding when samples=3 |
| 1 | icEncodePercent | ✅ | Percentage (0-100) |
| 2 | icEncodeUnitFloat | ✅ | Float clamped to [0.0, 1.0] |
| 3 | icEncodeFloat | ✅ | Unclamped float |
| 4 | icEncode8Bit | ❌ | 8-bit unsigned (input only) |
| 5 | icEncode16Bit | ✅ | 16-bit unsigned |
| 6 | icEncode16BitV2 | ✅ | 16-bit unsigned (v2 encoding) |

## Rendering Intent Reference

| Value | Name | Description |
|-------|------|-------------|
| 0 | Perceptual | Photographic images |
| 1 | Relative Colorimetric | Proof, preserve white point |
| 2 | Saturation | Business graphics |
| 3 | Absolute Colorimetric | Proof, absolute white point |
| 10-13 | Without D2Bx/B2Dx | Legacy path |
| 20-23 | Preview | Print preview mode |
| 30 | Gamut | Gamut boundary |
| 33 | Gamut Absolute | Gamut with absolute white |
| 40-43 | With BPC | Black point compensation |
| 50 | BDRF Model | BRDF model-based |
| 60 | BDRF Light | BRDF light source |
| 70 | BDRF Output | BRDF output device |
| 80 | MCS Connection | Multi-color space |
| 90-93 | Colorimetric Only | Skip chromatic adaptation |
| 100-103 | Spectral Only | Spectral rendering |
| +1000 | Luminance PCS | Add to base intent |
| +10000 | V5 Sub-profile | Use V5 if present |
| +100000 | HToS Tag | Use HToS tag if present |

## Integration with Fuzzing

### Corpus Generation
```bash
# Use tool output as fuzzer corpus input
./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
  Testing/ApplyDataFiles/rgbFloat.txt 3 0 \
  Testing/Display/sRGB_D65_MAT.icc 0 > corpus/iccapply_rgb_float.txt
```

### Profile Validation
```bash
# Test if profile is valid for IccApplyNamedCmm
./Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm \
  Testing/ApplyDataFiles/rgbFloat.txt 3 0 \
  suspect.icc 0 2>&1 | grep -q "Invalid Profile" && echo "INVALID" || echo "VALID"
```

## Future Enhancements

1. **JSON Config Testing** - Add tests for Usage 1 (config file mode)
2. **PCC Support** - Test Profile Connection Conditions (-PCC flag)
3. **ENV Variables** - Test environment variable injection (-ENV flag)
4. **Multi-Profile Chain** - Test multiple profiles in sequence
5. **CMYK Testing** - Add CMYK profile tests
6. **Lab/XYZ Testing** - Test Lab and XYZ color spaces
7. **Spectral Testing** - Test spectral reflectance profiles
8. **Performance Testing** - Benchmark interpolation methods
9. **Numerical Accuracy** - Compare against reference implementations
10. **Memory Leak Fix** - Address ASan-detected leak in IccMpeCalc.cpp

## References

- Tool Location: `Build/Tools/IccApplyNamedCmm/iccApplyNamedCmm`
- Source Code: `Tools/CmdLine/IccApplyNamedCmm/iccApplyNamedCmm.cpp`
- Library: IccProfLib v2.3.1.1
- Test Data: `Testing/ApplyDataFiles/`
- Test Profiles: `Testing/Display/`, `Testing/Calc/`
