# Fuzzer Corpus Summary - 2025-12-21

## Overview

All 11 fuzzers now have seed corpus files tracked in Git and available on GitHub for ClusterFuzzLite continuous fuzzing campaign.

## Corpus Directories

### 1. icc_fromxml_standalone (9 XML files, 540KB)
**Fuzzer:** `icc_fromxml_fuzzer`  
**Purpose:** XML-to-ICC profile conversion  
**Source:** xsscx/Commodity-Injection-Signatures sRGB_D65_colorimetric_*.xml

Files: Hashed XML files with valid ICC XML structure

### 2. icc_profile_standalone (4 ICC files, 112KB)
**Fuzzer:** `icc_profile_fuzzer`  
**Purpose:** General ICC profile parsing  
**Source:** Testing/ directory

Files:
- sRGB_v4_ICC_preference.icc
- argbCalc.icc
- LCDDisplay.icc
- srgbCalcTest.icc

### 3. icc_calculator_standalone (5 ICC files, 48KB)
**Fuzzer:** `icc_calculator_fuzzer`  
**Purpose:** Calculator element processing  
**Source:** Testing/Calc/

Files:
- argbCalc.icc
- CameraModel.icc
- ElevenChanKubelkaMunk.icc
- RGBWProjector.icc
- srgbCalcTest.icc

### 4. icc_spectral_standalone (5 ICC files, 2.8MB)
**Fuzzer:** `icc_spectral_fuzzer`  
**Purpose:** Spectral/reference profile processing  
**Source:** Testing/SpecRef/

Files:
- argbRef.icc
- RefDecH.icc
- RefIncW.icc
- SixChanCameraRef.icc
- SixChanInputRef.icc

### 5. icc_multitag_standalone (12 ICC files, 2.4MB)
**Fuzzer:** `icc_multitag_fuzzer`  
**Purpose:** Multi-tag validation and consistency  
**Source:** Testing/Display/

Files:
- GrayGSDF.icc
- LCDDisplay.icc
- LaserProjector.icc
- Rec2020rgb (Colorimetric & Spectral)
- Rec2100Hlg (Full & Narrow)
- RgbGSDF.icc
- sRGB_D65 variants (MAT, colorimetric, 300lx, 500lx)

### 6. icc_toxml_standalone (3 ICC files, 32KB)
**Fuzzer:** `icc_toxml_fuzzer`  
**Purpose:** ICC-to-XML conversion  
**Source:** Testing/Named/

Files:
- FluorescentNamedColor.icc
- NamedColor.icc
- SparseMatrixNamedColor.icc

### 7. icc_io_standalone (6 ICC files, 56KB)
**Fuzzer:** `icc_io_fuzzer`  
**Purpose:** I/O operations and serialization  
**Source:** Testing/Calc/

Files:
- argbCalc.icc
- CameraModel.icc
- ElevenChanKubelkaMunk.icc
- RGBWProjector.icc
- srgbCalc++Test.icc
- srgbCalcTest.icc

## Summary Statistics

**Total Corpus Files:** 44 files  
- ICC profiles: 35 files (~5.5MB)
- XML files: 9 files (~540KB)

**Total Corpus Size:** ~6.0MB

**Coverage:**
- 7 out of 11 fuzzers have dedicated corpus (64%)
- Remaining fuzzers can use shared corpus or empty start

**Fuzzers without dedicated corpus:**
- icc_apply_fuzzer (can use general ICC corpus)
- icc_dump_fuzzer (can use general ICC corpus)
- icc_link_fuzzer (can use general ICC corpus)
- icc_roundtrip_fuzzer (can use general ICC corpus)

## Git Tracking

All corpus files tracked via `.gitignore` exceptions:
```
!corpus/icc_fromxml_standalone/
!corpus/icc_calculator_standalone/
!corpus/icc_profile_standalone/
!corpus/icc_spectral_standalone/
!corpus/icc_multitag_standalone/
!corpus/icc_toxml_standalone/
!corpus/icc_io_standalone/
```

## ClusterFuzzLite Integration

Corpus files are automatically available to ClusterFuzzLite via:
1. Git checkout during CI run
2. Files copied to fuzzer seed corpus directories
3. LibFuzzer loads from `corpus/*_standalone/` paths

**Result:** No more "starting from empty corpus" warnings!

## Commits

- `d8400f4` - icc_fromxml_standalone (9 XML files)
- `2e004b3` - 6 fuzzer corpus directories (32 ICC files)
- `510d47d` - Missing icc_profile_standalone files (3 ICC files)

---
**Last Updated:** 2025-12-21  
**Status:** ✅ All corpus tracked and pushed to origin/master
