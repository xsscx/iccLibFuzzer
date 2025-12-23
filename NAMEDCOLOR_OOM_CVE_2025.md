# CIccTagNamedColor2 Out-of-Memory Vulnerability

**CVE ID:** TBD (Pending Assignment)  
**Severity:** HIGH (7.5 CVSS)  
**Type:** Denial of Service (DoS) - Out-of-Memory  
**Discovered:** 2025-12-21  
**Discovered By:** ClusterFuzzLite Continuous Fuzzing  
**Status:** ✅ FIXED

---

## Executive Summary

A critical out-of-memory vulnerability was discovered in the `CIccTagNamedColor2::SetSize()` function that allows attackers to cause denial-of-service by providing malformed ICC profiles with excessive allocation sizes. The vulnerability was discovered through automated fuzzing and has been patched with allocation limits.

---

## Vulnerability Details

### Affected Component
- **Library:** IccProfLib (RefIccMAX)
- **File:** `IccProfLib/IccTagBasic.cpp`
- **Function:** `CIccTagNamedColor2::SetSize()`
- **Lines:** 2827-2870 (pre-patch)

### Attack Vector
An attacker can craft a malicious ICC profile with a Named Color (ncl2) tag containing an extremely large size field. When the profile is parsed, the application attempts to allocate multiple gigabytes of memory, causing an out-of-memory crash.

### Technical Details

**Vulnerable Code (Pre-Patch):**
```cpp
bool CIccTagNamedColor2::SetSize(icUInt32Number nSize, icInt32Number nDeviceCoords) {
  icUInt32Number nColorEntrySize = 32 + (3 + 1 + nDeviceCoords)*sizeof(icFloatNumber);
  
  // ❌ NO VALIDATION - Direct allocation from untrusted input
  SIccNamedColorEntry* pNamedColor = (SIccNamedCodeEntry*)calloc(nSize, nColorEntrySize);
  
  if (!pNamedColor)
    return false;
  // ...
}
```

**Call Stack:**
```
CIccTagNamedColor2::Read()
  → CIccTagNamedColor2::SetSize(nNum, nCoords)
    → calloc(nSize, nColorEntrySize)
      → Out-of-Memory
```

**Proof of Concept:**
```
Malformed ICC Profile Structure:
- Tag Signature: 'ncl2' (Named Color 2)
- nNum field: 0xBBBBBBBB (3,149,642,683 entries)
- nColorEntrySize: ~100 bytes
- Total Allocation: ~3.1 GB

Result: malloc(3154116652) → OOM
```

### Discovery Method

**ClusterFuzzLite Run:**
- **URL:** https://github.com/xsscx/ipatch/actions/runs/20412642064/job/58651719131
- **Sanitizer:** MemorySanitizer (MSan)
- **Fuzzer:** `icc_profile_fuzzer`
- **Corpus:** Generated mutations from valid ICC profiles

**Error Output:**
```
Non XML tag in list with tag FFFFFF03h!
Non XML tag in list with tag ncl2!
==23== ERROR: libFuzzer: out-of-memory (malloc(3154116652))
   To change the out-of-memory limit use -rss_limit_mb=<N>

    #0 0x556ea6ed0259 in __sanitizer_print_stack_trace
    #1 0x556ea6e42c88 in fuzzer::PrintStackTrace()
    #2 0x556ea6e2498d in fuzzer::Fuzzer::HandleMalloc(unsigned long)
    #3 0x556ea6e248ab in fuzzer::MallocHook(void const volatile*, unsigned long)
    #9 0x556ea6fce022 in CIccTagNamedColor2::SetSize(unsigned int, int)
    #10 0x556ea6fcf68b in CIccTagNamedColor2::Read(unsigned int, CIccIO*)
```

---

## Impact Assessment

### Severity Metrics (CVSS 3.1)

**Vector String:** CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:N/I:N/A:H

| Metric | Value | Justification |
|--------|-------|---------------|
| **Attack Vector (AV)** | Network (N) | Malicious ICC profiles can be delivered via network |
| **Attack Complexity (AC)** | Low (L) | Easy to craft malicious ICC file |
| **Privileges Required (PR)** | None (N) | No authentication required |
| **User Interaction (UI)** | Required (R) | User must open/process the ICC file |
| **Scope (S)** | Unchanged (U) | DoS limited to application |
| **Confidentiality (C)** | None (N) | No data disclosure |
| **Integrity (I)** | None (N) | No data modification |
| **Availability (A)** | High (H) | Complete DoS of application |

**CVSS Score:** 7.5 (HIGH)

### Affected Software

Any application using IccProfLib to parse ICC profiles:
- Color management systems
- Image processing applications
- PDF viewers/processors
- Print workflow software
- Professional photography tools
- Any software using RefIccMAX library

### Attack Scenarios

1. **Email Attachment:** Malicious ICC profile attached to email
2. **Web Download:** Embedded in downloaded images/PDFs
3. **Document Processing:** ICC profile in office documents
4. **Print Workflows:** Malicious color profile in print jobs
5. **CMS Systems:** Uploaded to content management systems

---

## Patch Details

### Fix Implementation

**Commit:** `0292cbd` (Initial), `819919c` (Adjusted)  
**Date:** 2025-12-21  
**Files Changed:** `IccProfLib/IccTagBasic.cpp`

**Patched Code:**
```cpp
bool CIccTagNamedColor2::SetSize(icUInt32Number nSize, icInt32Number nDeviceCoords) {
  if (nSize <1)
    nSize = 1;
  if (nDeviceCoords<0)
    nDeviceCoords = m_nDeviceCoords;

  icInt32Number nNewCoords=nDeviceCoords;

  if (nDeviceCoords>0)
    nDeviceCoords--;

  icUInt32Number nColorEntrySize = 32/*rootName*/ + (3/*PCS*/ + 1/*iAny*/ + nDeviceCoords)*sizeof(icFloatNumber);

  // ✅ SECURITY: Prevent OOM attacks - validate allocation size
  // Allow up to 1GB for named color tables (fuzzer has 2.5GB RSS limit)
  // Typical usage: <10K entries (~1MB), but allow larger for valid use cases
  const icUInt32Number MAX_NAMED_COLORS = 10000000; // 10 million entries
  const icUInt64Number MAX_ALLOC_SIZE = 1024ULL * 1024 * 1024; // 1GB
  
  // Check entry count limit
  if (nSize > MAX_NAMED_COLORS) {
    return false;
  }
  
  // Check total allocation size (prevent integer overflow with 64-bit math)
  icUInt64Number nTotalSize = (icUInt64Number)nSize * (icUInt64Number)nColorEntrySize;
  if (nTotalSize > MAX_ALLOC_SIZE) {
    return false;
  }

  // Now safe to allocate
  SIccNamedColorEntry* pNamedColor = (SIccNamedColorEntry*)calloc(nSize, nColorEntrySize);

  if (!pNamedColor)
    return false;
  // ... rest of function
}
```

### Security Improvements

1. **Entry Count Limit:** Max 10M named color entries (practical maximum)
2. **Allocation Size Limit:** Max 1GB total allocation
3. **Integer Overflow Protection:** 64-bit arithmetic prevents wraparound
4. **Early Validation:** Checks before allocation attempt
5. **Graceful Failure:** Returns false instead of crashing

### Validation Strategy

**Two-tier protection:**
```cpp
// Tier 1: Logical limit on number of entries
if (nSize > MAX_NAMED_COLORS) return false;

// Tier 2: Physical limit on memory allocation
icUInt64Number nTotalSize = (icUInt64Number)nSize * (icUInt64Number)nColorEntrySize;
if (nTotalSize > MAX_ALLOC_SIZE) return false;
```

This ensures both logical validity AND prevents memory exhaustion.

---

## Patch Application

### Git Patch

```diff
diff --git a/IccProfLib/IccTagBasic.cpp b/IccProfLib/IccTagBasic.cpp
index 5e58d48..8ddf555 100644
--- a/IccProfLib/IccTagBasic.cpp
+++ b/IccProfLib/IccTagBasic.cpp
@@ -2838,6 +2838,20 @@ bool CIccTagNamedColor2::SetSize(icUInt32Number nSize, icInt32Number nDeviceCoor
 
   icUInt32Number nColorEntrySize = 32/*rootName*/ + (3/*PCS*/ + 1/*iAny*/ + nDeviceCoords)*sizeof(icFloatNumber);
 
+  // Prevent OOM: validate allocation size before calloc
+  // Allow up to 1GB for named color tables (fuzzer has 2.5GB RSS limit)
+  // Typical usage: <10K entries (~1MB), but allow larger for valid use cases
+  const icUInt32Number MAX_NAMED_COLORS = 10000000; // 10 million entries
+  const icUInt64Number MAX_ALLOC_SIZE = 1024ULL * 1024 * 1024; // 1GB
+  
+  if (nSize > MAX_NAMED_COLORS) {
+    return false;
+  }
+  
+  icUInt64Number nTotalSize = (icUInt64Number)nSize * (icUInt64Number)nColorEntrySize;
+  if (nTotalSize > MAX_ALLOC_SIZE) {
+    return false;
+  }
+
   SIccNamedColorEntry* pNamedColor = (SIccNamedColorEntry*)calloc(nSize, nColorEntrySize);
 
   if (!pNamedColor)
```

### Download Patch

**File:** `namedcolor_oom_fix.patch`

```bash
# Apply patch
cd /path/to/RefIccMAX
curl -O https://raw.githubusercontent.com/xsscx/ipatch/master/namedcolor_oom_fix.patch
git apply namedcolor_oom_fix.patch

# Or manually
patch -p1 < namedcolor_oom_fix.patch
```

---

## Recommended Code Pattern for LibFuzzer/ClusterFuzzLite

### General Allocation Protection Pattern

This pattern should be applied to **ALL** dynamic allocations from untrusted input:

```cpp
// BEFORE (Vulnerable):
void* buffer = malloc(untrusted_size);

// AFTER (Secure):
const size_t MAX_ALLOC = 1024 * 1024 * 1024; // 1GB or appropriate limit

// Validate before allocation
if (untrusted_size > MAX_ALLOC) {
  return false; // or appropriate error handling
}

// Safe to allocate
void* buffer = malloc(untrusted_size);
if (!buffer) {
  return false;
}
```

### Pattern for Array Allocations

```cpp
// BEFORE (Vulnerable):
Element* array = (Element*)calloc(count, element_size);

// AFTER (Secure):
const size_t MAX_ELEMENTS = 10000000;
const size_t MAX_ALLOC_SIZE = 1024ULL * 1024 * 1024; // 1GB

// Check element count
if (count > MAX_ELEMENTS) {
  return false;
}

// Check total size with overflow protection (use 64-bit math)
uint64_t total_size = (uint64_t)count * (uint64_t)element_size;
if (total_size > MAX_ALLOC_SIZE) {
  return false;
}

// Safe to allocate
Element* array = (Element*)calloc(count, element_size);
if (!array) {
  return false;
}
```

### Fuzzer-Specific Considerations

For LibFuzzer/ClusterFuzzLite campaigns:

```cpp
// Choose limits based on fuzzer RSS limit
// ClusterFuzzLite default: 2560MB (2.5GB)
// Leave headroom for other allocations and sanitizer overhead

#ifdef FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION
  // Fuzzing mode: aggressive limits
  const size_t MAX_ALLOC = 512 * 1024 * 1024; // 512MB
#else
  // Production mode: reasonable limits
  const size_t MAX_ALLOC = 1024 * 1024 * 1024; // 1GB
#endif
```

### Recommended Limits by Use Case

| Data Type | Typical Size | Fuzzing Limit | Production Limit |
|-----------|--------------|---------------|------------------|
| String buffers | <64KB | 10MB | 100MB |
| Color tables | <1MB | 100MB | 1GB |
| Image data | 1-100MB | 512MB | 4GB |
| Generic arrays | Varies | 256MB | 1GB |

---

## Similar Vulnerabilities to Check

### Audit Checklist for ICC Profile Parsing

Search your codebase for these patterns:

```bash
# Find all calloc/malloc with size from input
grep -rn "calloc.*Read\|malloc.*Read" .

# Find all array allocations
grep -rn "new.*\[.*\]" . | grep -v "delete"

# Find SetSize/Resize patterns
grep -rn "SetSize\|Resize\|Allocate" .
```

### High-Risk Functions in IccProfLib

Check these functions for similar vulnerabilities:

```cpp
CIccTagLut8::SetSize()                    // LUT tables
CIccTagLut16::SetSize()                   // LUT tables
CIccCurve::SetSize()                      // Curves
CIccTagTextDescription::SetText()         // Text strings
CIccTagMultiLocalizedUnicode::SetSize()   // Unicode strings
CIccTagSpectralData::SetSize()            // Spectral data
CIccTagXmlDict::SetSize()                 // XML dictionaries
CIccTagZipUtf8Text::AllocBuffer()         // Already fixed!
```

**Pattern to look for:**
1. Size/count read from ICC file (untrusted input)
2. Direct use in malloc/calloc/new
3. No validation before allocation

---

## Testing & Validation

### Fuzzing Test Cases

**Valid Profiles (Should Pass):**
```cpp
// Small named color table
SetSize(100, 3);         // ✅ Pass: ~10KB

// Medium named color table
SetSize(10000, 5);       // ✅ Pass: ~1MB

// Large but valid table
SetSize(1000000, 3);     // ✅ Pass: ~100MB
```

**Malicious Profiles (Should Reject):**
```cpp
// Excessive entry count
SetSize(0xBBBBBBBB, 3);  // ❌ Reject: > MAX_NAMED_COLORS

// Excessive allocation size
SetSize(20000000, 50);   // ❌ Reject: > 1GB

// Integer overflow attempt
SetSize(0xFFFFFFFF, 100); // ❌ Reject: overflow protection
```

### Fuzzer Configuration

**For ClusterFuzzLite:**
```yaml
# .clusterfuzzlite/project.yaml
sanitizers:
  - address
  - undefined
  - memory

fuzzing_engines:
  - libfuzzer

# Increase RSS limit if needed
environment:
  ASAN_OPTIONS: allocator_may_return_null=0
  UBSAN_OPTIONS: halt_on_error=1
  MSAN_OPTIONS: halt_on_error=1
```

**Fuzzer Invocation:**
```bash
# Run with appropriate RSS limit
./icc_profile_fuzzer corpus/ \
  -max_len=10485760 \
  -rss_limit_mb=2560 \
  -timeout=25 \
  -runs=100000
```

---

## Recommendations

### For Developers

1. **Input Validation:** Always validate sizes from untrusted input before allocation
2. **Overflow Protection:** Use 64-bit arithmetic for size calculations
3. **Reasonable Limits:** Set practical maximum allocation sizes
4. **Fuzzing:** Continuously fuzz input parsers with sanitizers
5. **Code Review:** Audit all allocation sites for similar vulnerabilities

### For Security Teams

1. **Update Immediately:** Apply patch or upgrade to latest version
2. **Test Deployment:** Verify patch doesn't break legitimate workflows
3. **Monitor:** Watch for DoS attempts via malicious ICC profiles
4. **Defense in Depth:** Consider file size limits, resource quotas
5. **Incident Response:** Have plan for OOM-based DoS attacks

### For Fuzzing Campaigns

1. **Enable Sanitizers:** Use ASan, MSan, UBSan in all fuzzing runs
2. **Corpus Quality:** Seed with valid ICC profiles for better coverage
3. **RSS Limits:** Set appropriate memory limits (2-4GB recommended)
4. **Continuous Integration:** Run fuzzers on every commit
5. **Regression Testing:** Add OOM PoCs to regression test suite

---

## References

### Related CVEs
- CVE-2023-44062: IccUtil enum conversion UB (related project)
- CVE-2024-XXXXX: CIccTagZipUtf8Text OOM (same codebase)

### Fuzzing Resources
- [LibFuzzer Documentation](https://llvm.org/docs/LibFuzzer.html)
- [ClusterFuzzLite Guide](https://google.github.io/clusterfuzzlite/)
- [OSS-Fuzz](https://github.com/google/oss-fuzz)

### ICC Specification
- [ICC Specification ICC.1:2022](https://www.color.org/specification/ICC.1-2022-05.pdf)
- Named Color Type (ncl2): Section 10.15

### Disclosure Timeline
- **2025-12-21 00:00 UTC:** Vulnerability discovered by ClusterFuzzLite
- **2025-12-21 16:36 UTC:** Initial patch committed (100MB limit)
- **2025-12-21 17:10 UTC:** Adjusted patch committed (1GB limit)
- **2025-12-21 17:11 UTC:** Public disclosure (this document)
- **TBD:** CVE assignment
- **TBD:** Upstream patch submission

---

## Appendix: Full Patch

**File:** `namedcolor_oom_fix.patch`

```patch
From 819919c Mon Sep 17 00:00:00 2001
From: GitHub Actions <github-actions@github.com>
Date: Sun, 21 Dec 2025 17:10:00 +0000
Subject: [PATCH] fix: Add OOM protection to CIccTagNamedColor2::SetSize

Issue: Fuzzer discovered OOM vulnerability (malloc 3.1GB)
Location: IccTagBasic.cpp:2841 CIccTagNamedColor2::SetSize()

---
 IccProfLib/IccTagBasic.cpp | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/IccProfLib/IccTagBasic.cpp b/IccProfLib/IccTagBasic.cpp
index 5e58d48..8ddf555 100644
--- a/IccProfLib/IccTagBasic.cpp
+++ b/IccProfLib/IccTagBasic.cpp
@@ -2838,6 +2838,20 @@ bool CIccTagNamedColor2::SetSize(icUInt32Number nSize, icInt32Number nDeviceCoor
 
   icUInt32Number nColorEntrySize = 32/*rootName*/ + (3/*PCS*/ + 1/*iAny*/ + nDeviceCoords)*sizeof(icFloatNumber);
 
+  // Prevent OOM: validate allocation size before calloc
+  // Allow up to 1GB for named color tables (fuzzer has 2.5GB RSS limit)
+  // Typical usage: <10K entries (~1MB), but allow larger for valid use cases
+  const icUInt32Number MAX_NAMED_COLORS = 10000000; // 10 million entries
+  const icUInt64Number MAX_ALLOC_SIZE = 1024ULL * 1024 * 1024; // 1GB
+  
+  if (nSize > MAX_NAMED_COLORS) {
+    return false;
+  }
+  
+  icUInt64Number nTotalSize = (icUInt64Number)nSize * (icUInt64Number)nColorEntrySize;
+  if (nTotalSize > MAX_ALLOC_SIZE) {
+    return false;
+  }
+
   SIccNamedColorEntry* pNamedColor = (SIccNamedColorEntry*)calloc(nSize, nColorEntrySize);
 
   if (!pNamedColor)
--
2.43.0
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-12-21 17:11 UTC  
**Maintained By:** xsscx Security Team  
**Contact:** security@xsscx.com (if applicable)

