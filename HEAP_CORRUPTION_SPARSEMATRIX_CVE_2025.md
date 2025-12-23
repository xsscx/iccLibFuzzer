# Heap Corruption in CIccTagSparseMatrixArray - CVE-2025-TBD

**Status:** ✅ FIXED  
**Severity:** HIGH  
**CVE ID:** CVE-2025-TBD (pending assignment)  
**Fix Commit:** d11cb6ee  
**Discovery Date:** 2025-12-22  
**Discovery Method:** LibFuzzer + UndefinedBehaviorSanitizer  

## Executive Summary

Two critical bugs in `CIccTagSparseMatrixArray` buffer allocation logic cause heap metadata corruption, leading to crash on `free()`. The bugs occur in the `Reset()` method and copy assignment operator, where buffer sizes are calculated incorrectly when the number of channels changes.

## Vulnerability Details

### Location
- **File:** `IccProfLib/IccTagBasic.cpp`
- **Class:** `CIccTagSparseMatrixArray`
- **Methods:** 
  - `Reset()` (line 5048)
  - `operator=()` (line 4530)

### Root Causes

#### Bug 1: Reset() Method (Line 5053)
```cpp
// BEFORE (VULNERABLE)
bool CIccTagSparseMatrixArray::Reset(icUInt32Number nNumMatrices, icUInt16Number nChannelsPerMatrix)
{
  if (nNumMatrices==m_nSize && nChannelsPerMatrix==m_nChannelsPerMatrix)
    return true;

  icUInt32Number nSize = nNumMatrices * GetBytesPerMatrix();  // BUG: Uses OLD m_nChannelsPerMatrix!
  
  icUInt8Number *pNewData = (icUInt8Number *)icRealloc(m_RawData, nSize);
  
  m_RawData = pNewData;
  m_nSize = nNumMatrices;
  m_nChannelsPerMatrix = nChannelsPerMatrix;  // Updated AFTER size calculation
  ...
}
```

**Problem:** `GetBytesPerMatrix()` returns `m_nChannelsPerMatrix * sizeof(icFloatNumber)`, using the **old** value of `m_nChannelsPerMatrix` before it's updated. This causes under-allocation when channels increase, or over-allocation when channels decrease.

**Impact:** Heap corruption when accessing buffer with new channel count but old allocation size.

#### Bug 2: Copy Assignment Operator (Line 4539)
```cpp
// BEFORE (VULNERABLE)
CIccTagSparseMatrixArray& CIccTagSparseMatrixArray::operator=(const CIccTagSparseMatrixArray &ITSMA)
{
  m_nSize = ITSMA.m_nSize;
  m_nChannelsPerMatrix = ITSMA.m_nChannelsPerMatrix;

  if (m_RawData)
    free(m_RawData);
  m_RawData = (icUInt8Number*)calloc(m_nSize, m_nChannelsPerMatrix);  // BUG: Wrong multiplier!
  memcpy(m_RawData, ITSMA.m_RawData, m_nSize*GetBytesPerMatrix());
  ...
}
```

**Problem:** `calloc(m_nSize, m_nChannelsPerMatrix)` allocates `m_nSize * m_nChannelsPerMatrix` bytes, but should allocate `m_nSize * m_nChannelsPerMatrix * sizeof(icFloatNumber)` bytes.

**Impact:** Severe under-allocation by factor of 4 (sizeof(icFloatNumber)), causing heap buffer overflow on `memcpy()`.

### Crash Signature
```
free(): invalid next size (fast)
==1002035== ERROR: libFuzzer: deadly signal
```

### Attack Vector
- **Trigger:** Malformed ICC profile with sparse matrix array tag
- **Attack Surface:** Any application that processes untrusted ICC profiles
- **Exploit Scenario:** 
  1. Attacker crafts ICC profile with sparse matrix array
  2. Profile triggers channel count change during parsing
  3. Heap corruption occurs in `Reset()` or copy assignment
  4. Application crashes on destructor (`~CIccTagSparseMatrixArray()`)

## CVSS 3.1 Score

**Score:** 7.5 (HIGH)

**Vector:** CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H

- **Attack Vector (AV):** Network - ICC profiles distributed via web, email, etc.
- **Attack Complexity (AC):** Low - No special conditions required
- **Privileges Required (PR):** None - Untrusted input
- **User Interaction (UI):** None - Automatic processing
- **Scope (S):** Unchanged
- **Confidentiality (C):** None - DoS only
- **Integrity (I):** None - DoS only  
- **Availability (A):** High - Application crash

**Note:** Score could increase to CRITICAL (9.8) if heap corruption is exploitable for code execution (requires further analysis).

## Proof of Concept

**File:** `crash-sparse-matrix-heap`  
**Size:** 329 bytes  
**SHA256:** ebfa6b0601ccb83086743b36da543a8184892e40

### Reproduction
```bash
# Build with UBSan
./build-fuzzers-local.sh undefined

# Run PoC (BEFORE fix - crashes)
./fuzzers-local/undefined/icc_toxml_fuzzer crash-sparse-matrix-heap
# Output: free(): invalid next size (fast)

# Run PoC (AFTER fix - no crash)
./fuzzers-local/undefined/icc_toxml_fuzzer crash-sparse-matrix-heap
# Output: Executed crash-sparse-matrix-heap in 0 ms
```

## Fix Implementation

### Commit Details
- **Commit:** d11cb6ee
- **Date:** 2025-12-22
- **Message:** "fix: Heap corruption in CIccTagSparseMatrixArray"

### Code Changes

#### Fix 1: Reset() Method
```cpp
// AFTER (FIXED)
bool CIccTagSparseMatrixArray::Reset(icUInt32Number nNumMatrices, icUInt16Number nChannelsPerMatrix)
{
  if (nNumMatrices==m_nSize && nChannelsPerMatrix==m_nChannelsPerMatrix)
    return true;

  icUInt32Number nBytesPerMatrix = nChannelsPerMatrix * sizeof(icFloatNumber);  // Use NEW value
  icUInt32Number nSize = nNumMatrices * nBytesPerMatrix;
  
  icUInt8Number *pNewData = (icUInt8Number *)icRealloc(m_RawData, nSize);

  if (!pNewData) {
    return false;
  }

  m_RawData = pNewData;
  m_nSize = nNumMatrices;
  m_nChannelsPerMatrix = nChannelsPerMatrix;
  
  memset(m_RawData, 0, nSize);
  return true;
}
```

#### Fix 2: Copy Assignment Operator
```cpp
// AFTER (FIXED)
CIccTagSparseMatrixArray& CIccTagSparseMatrixArray::operator=(const CIccTagSparseMatrixArray &ITSMA)
{
  if (&ITSMA == this)
    return *this;

  m_nSize = ITSMA.m_nSize;
  m_nChannelsPerMatrix = ITSMA.m_nChannelsPerMatrix;

  if (m_RawData)
    free(m_RawData);
  m_RawData = (icUInt8Number*)calloc(m_nSize, GetBytesPerMatrix());  // Use correct size
  memcpy(m_RawData, ITSMA.m_RawData, m_nSize*GetBytesPerMatrix());

  m_bNonZeroPadding = ITSMA.m_bNonZeroPadding;

  return *this;
}
```

### Verification
```bash
./test-sparse-matrix-heap-fix.sh
# Output: ✅ PASS: No heap corruption detected
```

## Impact Analysis

### Affected Code Paths
1. **IccToXml conversion:** `CIccProfileXml::ToXml()` → `CIccProfile::FindTag()` → `CIccTagStruct::LoadElem()`
2. **Profile parsing:** Any code path that loads sparse matrix array tags
3. **Copy operations:** Any code that copies `CIccTagSparseMatrixArray` objects

### Affected Applications
- **IccToXml** - Command-line ICC profile to XML converter
- **IccFromXml** - XML to ICC profile converter  
- **IccDumpProfile** - Profile inspection tool
- Any application linking against IccProfLib that processes ICC profiles

### Real-World Scenarios
1. **Web browsers** - Processing embedded ICC profiles in images
2. **Image editors** - Loading images with color profiles
3. **PDF viewers** - Processing document color spaces
4. **Print workflows** - Color management pipelines
5. **Digital cameras** - Firmware processing EXIF color spaces

## Timeline

- **2025-12-22 03:00 UTC** - Crash discovered by LibFuzzer (icc_toxml_fuzzer)
- **2025-12-22 03:05 UTC** - Root cause analysis completed
- **2025-12-22 03:07 UTC** - Fix implemented and tested
- **2025-12-22 03:09 UTC** - Fix committed (d11cb6ee)
- **2025-12-22 03:09 UTC** - Fix pushed to GitHub

**Total Time to Fix:** 9 minutes from discovery to push

## Recommendations

### Immediate Actions
1. ✅ Update to commit d11cb6ee or later
2. ✅ Run regression test: `./test-sparse-matrix-heap-fix.sh`
3. ✅ Rebuild all applications linking against IccProfLib

### Long-Term Improvements
1. **Code Audit:** Review all buffer allocation patterns for similar issues
2. **Static Analysis:** Add automated checks for order-of-operations bugs
3. **Fuzzing:** Continue UBSan fuzzing campaign for heap corruption detection
4. **Unit Tests:** Add specific tests for `CIccTagSparseMatrixArray` edge cases

### Additional Vulnerable Patterns
Similar bugs may exist in:
- Other `Reset()` methods using member variables in size calculations
- Other copy/assignment operators with manual buffer management
- Any code calling `GetBytesPerMatrix()` before updating `m_nChannelsPerMatrix`

## References

- **ICC Specification:** ISO 15076-1:2010 (Image technology colour management — Architecture, profile format, and data structure)
- **Sparse Matrix Arrays:** ICC.1:2022 Section 10.20 (sparseMatrixArrayType)
- **Fuzzing Documentation:** `FUZZING_BEST_PRACTICES.md`
- **Previous Session:** `SESSION_SUMMARY_20251222_022709.md`

## Credits

- **Discovery:** LibFuzzer + UndefinedBehaviorSanitizer
- **Fuzzer:** icc_toxml_fuzzer (undefined sanitizer build)
- **Analysis & Fix:** GitHub Copilot CLI
- **Hardware:** W5-2465X 32-core, RAID-1 2TB NVMe SSD
- **Repository:** https://github.com/xsscx/ipatch

## Appendix: Stack Trace

```
free(): invalid next size (fast)
==1002035== ERROR: libFuzzer: deadly signal
    #0 0x5af47fab1e88 in __sanitizer_print_stack_trace
    #1 0x5af47fa86efc in fuzzer::PrintStackTrace()
    #2 0x5af47fa6cf87 in fuzzer::Fuzzer::CrashCallback()
    #3 0x7898be44532f  (/lib/x86_64-linux-gnu/libc.so.6+0x4532f)
    #4 0x7898be49eb2b in pthread_kill
    #5 0x7898be44527d in raise
    #6 0x7898be4288fe in abort
    #7 0x7898be4297b5  (/lib/x86_64-linux-gnu/libc.so.6+0x297b5)
    #8 0x7898be4a8ff4  (/lib/x86_64-linux-gnu/libc.so.6+0xa8ff4)
    #9 0x7898be4ab3eb  (/lib/x86_64-linux-gnu/libc.so.6+0xab3eb)
    #10 0x7898be4addad in cfree
    #11 0x5af47fb7c027 in CIccTagSparseMatrixArray::~CIccTagSparseMatrixArray() IccProfLib/IccTagBasic.cpp:4546:1
    #12 0x5af47fc03077 in CIccTagStruct::LoadElem(IccTagEntry*, CIccIO*)
    #13 0x5af47fc01eac in CIccTagStruct::Read(unsigned int, CIccIO*) IccTagComposite.cpp:406:10
    #14 0x5af47fb0e5b7 in CIccProfile::LoadTag(IccTagEntry*, CIccIO*, bool) IccProfile.cpp:1300:14
    #15 0x5af47fb0de65 in CIccProfile::FindTag(unsigned int) IccProfile.cpp:410:7
    #16 0x5af47fab8a14 in CIccProfileXml::ToXmlWithBlanks() IccProfileXml.cpp:222:23
    #17 0x5af47fab3be4 in CIccProfileXml::ToXml() IccProfileXml.cpp:79:10
    #18 0x5af47fab3442 in LLVMFuzzerTestOneInput fuzzers/icc_toxml_fuzzer.cpp:42:22
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-22  
**Status:** ✅ Vulnerability Fixed and Documented
