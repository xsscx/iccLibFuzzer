# Fuzzing Best Practices for RefIccMAX / IccProfLib

**Last Updated:** 2025-12-21  
**Version:** 1.0  
**Audience:** Fuzzing Campaign Operators, Security Researchers, CI/CD Maintainers

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Command Line Recommendations](#command-line-recommendations)
3. [Code Modifications for Effective Fuzzing](#code-modifications-for-effective-fuzzing)
4. [Known Issues and Workarounds](#known-issues-and-workarounds)
5. [Sanitizer Configuration](#sanitizer-configuration)
6. [Corpus Management](#corpus-management)
7. [Performance Tuning](#performance-tuning)
8. [Vulnerability Patterns](#vulnerability-patterns)

---

## Quick Start

### Recommended Fuzzer Invocation

```bash
# LibFuzzer with AddressSanitizer (recommended for most campaigns)
./icc_profile_fuzzer \
  corpus/icc_profile_standalone/ \
  -max_len=10485760 \
  -rss_limit_mb=2560 \
  -timeout=25 \
  -max_total_time=3600 \
  -print_final_stats=1 \
  -artifact_prefix=crashes/
```

### ClusterFuzzLite Configuration

```yaml
# .clusterfuzzlite/project.yaml
language: c++
sanitizers:
  - address
  - undefined
  - memory
fuzzing_engines:
  - libfuzzer
```

---

## Command Line Recommendations

### Essential LibFuzzer Flags

#### Memory Limits

```bash
# RSS (Resident Set Size) limit - prevent fuzzer OOM
-rss_limit_mb=2560              # 2.5GB for most fuzzers
-rss_limit_mb=4096              # 4GB for memory-intensive fuzzers

# Maximum input size - ICC profiles rarely exceed 10MB
-max_len=10485760               # 10MB max input size
```

**Rationale:**
- ICC profiles with OOM vulnerabilities may attempt multi-GB allocations
- Our code patches limit allocations to 1GB max
- Set RSS limit > max allocation to allow legitimate large profiles
- 2.5GB RSS allows 1GB allocation + sanitizer overhead + fuzzer state

#### Timeout Configuration

```bash
# Per-input timeout - prevent infinite loops
-timeout=25                     # 25 seconds per input

# Total fuzzing time
-max_total_time=3600            # 1 hour (CI runs)
-max_total_time=86400           # 24 hours (continuous fuzzing)
```

**Rationale:**
- Complex ICC profiles with calculator elements can be slow to process
- 25 seconds allows legitimate processing while catching hangs
- Adjust based on your corpus complexity

#### Output Control

```bash
# Crash artifact management
-artifact_prefix=crashes/       # Save crashes to directory

# Statistics
-print_final_stats=1            # Print coverage stats at end
-print_corpus_stats=1           # Print corpus statistics

# Suppress noise
-close_fd_mask=3                # Close stdout/stderr for less noise
```

#### Corpus Evolution

```bash
# Number of runs
-runs=0                         # Infinite (continuous fuzzing)
-runs=100000                    # Fixed run count

# Merge and minimize corpus
-merge=1                        # Enable corpus merging
-minimize_crash=1               # Minimize crash inputs
```

### Fuzzer-Specific Recommendations

#### icc_profile_fuzzer (General ICC Parsing)

```bash
./icc_profile_fuzzer \
  corpus/icc_profile_standalone/ \
  -max_len=10485760 \
  -rss_limit_mb=2560 \
  -timeout=25 \
  -dict=icc_profile.dict \        # Optional: dictionary for mutations
  -jobs=24 \                       # Parallel fuzzing on 24-core machine
  -workers=24
```

#### icc_fromxml_fuzzer (XML Parsing)

```bash
./icc_fromxml_fuzzer \
  corpus/icc_fromxml_standalone/ \
  -max_len=1048576 \              # XML files are smaller (1MB)
  -rss_limit_mb=1024 \            # Lower memory usage
  -timeout=15 \                    # XML parsing is faster
  -detect_leaks=1                  # Enable leak detection
```

#### icc_calculator_fuzzer (Calculator Elements)

```bash
./icc_calculator_fuzzer \
  corpus/icc_calculator_standalone/ \
  -max_len=524288 \               # Calculator profiles are small (512KB)
  -rss_limit_mb=2048 \
  -timeout=30 \                    # Complex calculations need more time
  -use_value_profile=1             # Better coverage for arithmetic
```

#### icc_spectral_fuzzer (Large Spectral Data)

```bash
./icc_spectral_fuzzer \
  corpus/icc_spectral_standalone/ \
  -max_len=20971520 \             # Spectral profiles can be large (20MB)
  -rss_limit_mb=4096 \            # Higher memory limit
  -timeout=60 \                    # Spectral processing is slow
  -keep_seed=1                     # Keep all seed inputs
```

---

## Code Modifications for Effective Fuzzing

### 1. Suppress Expected Error Messages

**Problem:** Library error messages clutter fuzzer output and slow down fuzzing.

**Example:** XML parser errors from libxml2 when testing malformed inputs.

**Fix:**
```cpp
// fuzzers/icc_fromxml_fuzzer.cpp
#include <libxml/parser.h>

// Suppress libxml2 error/warning output during fuzzing
static void suppressXmlErrors(void *ctx, const char *msg, ...) {
  // Silently ignore - fuzzer is testing malformed inputs
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  // Suppress XML parser errors
  xmlSetGenericErrorFunc(nullptr, suppressXmlErrors);
  
  // ... rest of fuzzer code
}
```

**Applied to:** `icc_fromxml_fuzzer` (commit `883d0dc`)

### 2. Add Allocation Limits

**Problem:** Untrusted input can cause excessive memory allocations leading to OOM.

**Example:** `CIccTagNamedColor2::SetSize()` OOM vulnerability (CVE-2025-TBD).

**Pattern:**
```cpp
bool SetSize(icUInt32Number nSize, icInt32Number nParam) {
  // Calculate allocation size
  icUInt32Number nElementSize = /* element size calculation */;
  
  // ✅ ADD: Validate before allocation
  const icUInt32Number MAX_ELEMENTS = 10000000;  // Adjust per use case
  const icUInt64Number MAX_ALLOC_SIZE = 1024ULL * 1024 * 1024; // 1GB
  
  if (nSize > MAX_ELEMENTS) {
    return false;
  }
  
  // Use 64-bit arithmetic to prevent overflow
  icUInt64Number nTotalSize = (icUInt64Number)nSize * (icUInt64Number)nElementSize;
  if (nTotalSize > MAX_ALLOC_SIZE) {
    return false;
  }
  
  // Now safe to allocate
  void* pData = calloc(nSize, nElementSize);
  if (!pData) return false;
  
  // ...
}
```

**Applied to:** `CIccTagNamedColor2::SetSize()` (commits `0292cbd`, `819919c`)

**Recommended Limits:**

| Allocation Type | Max Elements | Max Size | Rationale |
|----------------|--------------|----------|-----------|
| Named Color Tables | 10M | 1GB | Professional workflows |
| LUT Tables | 100M | 2GB | High-resolution color transforms |
| Text Buffers | N/A | 10MB | Strings/descriptions |
| Spectral Data | 50M | 2GB | Multi-channel spectral profiles |
| Curve Points | 100M | 1GB | High-precision curves |

### 3. Add Input Validation

**Problem:** Missing bounds checks on input values can cause crashes or UB.

**Pattern:**
```cpp
// ❌ BEFORE: No validation
bool Read(icUInt32Number size, CIccIO* pIO) {
  icUInt32Number nCount;
  pIO->Read32(&nCount);
  SetSize(nCount);  // Unchecked!
  // ...
}

// ✅ AFTER: Validate input
bool Read(icUInt32Number size, CIccIO* pIO) {
  icUInt32Number nCount;
  pIO->Read32(&nCount);
  
  // Sanity check against available data
  icUInt32Number nExpectedSize = nCount * nElementSize;
  if (nExpectedSize > size) {
    return false;  // Truncated/malformed data
  }
  
  if (!SetSize(nCount)) {
    return false;  // Allocation failed
  }
  // ...
}
```

### 4. Replace Enum Sentinels

**Problem:** Returning enum sentinel values (`icMaxEnum*`) causes UBSan errors.

**Pattern:**
```cpp
// ❌ BEFORE: UB on enum load
virtual icTagTypeSignature GetType() const {
  return icMaxEnumType;  // 0xFFFFFFFF - outside enum range!
}

// ✅ AFTER: Return valid enum value
virtual icTagTypeSignature GetType() const {
  return icSigUnknownType;  // 0x3f3f3f3f '????' - valid enum value
}
```

**Applied to:** `CIccTag::GetType()` (commit `7192e39`)

**Rule:** Never return `icMaxEnum*` values. Use `icSigUnknown*` for unknown/unimplemented.

### 5. Integer Overflow Protection

**Problem:** Multiplication of untrusted values can overflow 32-bit integers.

**Pattern:**
```cpp
// ❌ BEFORE: 32-bit overflow
icUInt32Number nSize = nCount * nElementSize;  // May overflow!
if (nSize > MAX_SIZE) return false;

// ✅ AFTER: 64-bit overflow protection
icUInt64Number nSize = (icUInt64Number)nCount * (icUInt64Number)nElementSize;
if (nSize > MAX_SIZE) return false;
```

**Applied to:** All allocation size calculations in recent patches.

---

## Known Issues and Workarounds

### Issue #1: XML Parser Errors

**Symptom:**
```
/tmp/fuzz_icc_xml_XXXXXX:1234: parser error : Opening and ending tag mismatch
```

**Cause:** libxml2 prints errors to stderr when encountering malformed XML (expected in fuzzing).

**Impact:** Performance degradation, cluttered logs.

**Workaround:** Suppress errors with `xmlSetGenericErrorFunc()` (see Code Modifications #1).

**Status:** ✅ Fixed in `icc_fromxml_fuzzer` (commit `883d0dc`)

### Issue #2: Named Color OOM

**Symptom:**
```
ERROR: libFuzzer: out-of-memory (malloc(3154116652))
```

**Cause:** `CIccTagNamedColor2::SetSize()` attempts multi-GB allocation from untrusted input.

**Impact:** Fuzzer crash, DoS vulnerability.

**Workaround:** Apply allocation limits (see Code Modifications #2).

**Status:** ✅ Fixed (commits `0292cbd`, `819919c`)

**CVE:** Pending assignment (see `NAMEDCOLOR_OOM_CVE_2025.md`)

### Issue #3: Empty Corpus Warning

**Symptom:**
```
WARNING: Could not download artifact: cifuzz-corpus-icc_*_fuzzer
INFO - Done downloading corpus. Contains 0 elements.
```

**Cause:** First run or no previous corpus artifacts in GitHub Actions.

**Impact:** None (fuzzer falls back to Git corpus).

**Workaround:** None needed. Subsequent runs will have artifacts.

**Status:** ✅ Expected behavior

### Issue #4: Enum UB Errors

**Symptom:**
```
runtime error: load of value 4294967295, which is not a valid value for type 'icTagTypeSignature'
```

**Cause:** Returning `icMaxEnumType` (0xFFFFFFFF) from `GetType()`.

**Impact:** UBSan failures, potential UB in switch statements.

**Workaround:** Return `icSigUnknownType` instead (see Code Modifications #4).

**Status:** ✅ Fixed (commit `7192e39`)

---

## Sanitizer Configuration

### AddressSanitizer (ASan)

**Best for:** Memory corruption bugs (heap-UAF, buffer overflow, use-after-free)

```bash
# Build flags
CFLAGS="-fsanitize=address -fno-omit-frame-pointer -g"
CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer -g"

# Runtime options
export ASAN_OPTIONS="allocator_may_return_null=0:detect_leaks=1:halt_on_error=1"

# Run fuzzer
./icc_profile_fuzzer corpus/ -rss_limit_mb=2560
```

**Recommended Settings:**
- `allocator_may_return_null=0` - Crash on allocation failure
- `detect_leaks=1` - Enable leak detection
- `halt_on_error=1` - Stop immediately on first error

### UndefinedBehaviorSanitizer (UBSan)

**Best for:** Undefined behavior (integer overflow, enum range, null deref)

```bash
# Build flags
CFLAGS="-fsanitize=undefined -fno-omit-frame-pointer -g"
CXXFLAGS="-fsanitize=undefined -fno-omit-frame-pointer -g"

# Runtime options
export UBSAN_OPTIONS="halt_on_error=1:print_stacktrace=1"

# Run fuzzer
./icc_profile_fuzzer corpus/ -rss_limit_mb=2560
```

**Caught Issues:**
- Enum conversion UB (`icMaxEnumType` → `icSigUnknownType`)
- Integer overflow in size calculations
- Null pointer dereferences

### MemorySanitizer (MSan)

**Best for:** Use of uninitialized memory

```bash
# Build flags (requires instrumented libc++)
CFLAGS="-fsanitize=memory -fno-omit-frame-pointer -g"
CXXFLAGS="-fsanitize=memory -fno-omit-frame-pointer -g"

# Runtime options
export MSAN_OPTIONS="halt_on_error=1"

# Run fuzzer
./icc_profile_fuzzer corpus/ -rss_limit_mb=2560
```

**Note:** MSan requires all dependencies be built with `-fsanitize=memory`.

### Combined Sanitizers

```bash
# ASan + UBSan (recommended for comprehensive coverage)
CFLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g"
CXXFLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer -g"
```

**Warning:** Don't combine ASan with MSan (incompatible).

---

## Corpus Management

### Corpus Directory Structure

```
corpus/
├── icc_profile_standalone/      # General ICC profiles (4 files, 112KB)
├── icc_fromxml_standalone/      # XML files (9 files, 540KB)
├── icc_calculator_standalone/   # Calculator profiles (5 files, 48KB)
├── icc_spectral_standalone/     # Spectral profiles (5 files, 2.8MB)
├── icc_multitag_standalone/     # Multi-tag profiles (12 files, 2.4MB)
├── icc_toxml_standalone/        # Named color profiles (3 files, 32KB)
└── icc_io_standalone/           # I/O test profiles (6 files, 56KB)
```

### Corpus Quality Guidelines

**High-Quality Corpus:**
- ✅ Valid ICC profiles covering all tag types
- ✅ Edge cases: max values, empty fields, minimal profiles
- ✅ Real-world examples from professional workflows
- ✅ Mix of profile types: Display, Output, DeviceLink, Abstract

**Poor-Quality Corpus:**
- ❌ Random bytes
- ❌ All similar profiles
- ❌ Truncated/incomplete files
- ❌ Only tiny (< 1KB) inputs

### Corpus Minimization

```bash
# Merge and minimize corpus
./icc_profile_fuzzer \
  -merge=1 \
  corpus_minimized/ \
  corpus/icc_profile_standalone/ \
  fuzzers-local/address/icc_profile_fuzzer_seed_corpus/

# Result: Minimal corpus with same coverage
```

### Corpus Seeding Sources

1. **Testing/ directory** - Reference ICC profiles
2. **[Commodity Injection Signatures](https://github.com/xsscx/Commodity-Injection-Signatures)** - Malformed XML
3. **ICC Sample Profiles** - Industry-standard profiles
4. **Previous fuzzing runs** - Coverage-interesting inputs

---

## Performance Tuning

### Parallel Fuzzing

```bash
# Run 24 fuzzer instances on 24-core machine
./icc_profile_fuzzer \
  corpus/ \
  -jobs=24 \
  -workers=24 \
  -max_total_time=86400
```

**Expected Throughput:**
- Single core: ~1000-2000 exec/s
- 24 cores: ~24,000-48,000 exec/s

### Dictionary-Guided Fuzzing

Create `icc_profile.dict` with ICC magic values:

```
# ICC Profile Dictionary
"acsp"          # Profile signature
"RGB "          # Color space RGB
"CMYK"          # Color space CMYK
"ncl2"          # Named color v2
"desc"          # Description tag
"rXYZ"          # Red colorant
"gXYZ"          # Green colorant
"bXYZ"          # Blue colorant
"wtpt"          # White point
"cprt"          # Copyright
```

Use with:
```bash
./icc_profile_fuzzer corpus/ -dict=icc_profile.dict
```

### Coverage Tracking

```bash
# Generate coverage report
./icc_profile_fuzzer corpus/ -dump_coverage=1 -runs=100000

# Analyze coverage
llvm-cov report ./icc_profile_fuzzer
```

---

## Vulnerability Patterns

### Pattern #1: Unchecked Allocations

**Search for:**
```bash
grep -rn "calloc.*Read\|malloc.*Read" IccProfLib/
```

**Look for:**
1. Size read from ICC file
2. Direct use in malloc/calloc
3. No validation before allocation

**Example Fix:** See `CIccTagNamedColor2::SetSize()` in `NAMEDCOLOR_OOM_CVE_2025.md`

### Pattern #2: Integer Overflow

**Search for:**
```bash
grep -rn "icUInt32Number.*\*.*icUInt32Number" IccProfLib/
```

**Look for:**
1. 32-bit multiplication
2. Result used for allocation or bounds check
3. No overflow check

**Fix:** Cast to 64-bit before multiplication.

### Pattern #3: Enum Sentinels as Return Values

**Search for:**
```bash
grep -rn "return icMaxEnum" IccProfLib/
```

**Look for:**
1. Functions returning enum types
2. `icMaxEnum*` used as return value
3. Not used in internal checks

**Fix:** Return `icSigUnknown*` instead.

### Pattern #4: Unbounded Loops

**Search for:**
```bash
grep -rn "while.*Read\|for.*Read" IccProfLib/
```

**Look for:**
1. Loop controlled by input data
2. No iteration limit
3. No timeout mechanism

**Fix:** Add maximum iteration count.

---

## Recommended Fuzzing Workflow

### 1. Initial Corpus Setup

```bash
# Clone repository
git clone https://github.com/xsscx/ipatch.git
cd ipatch

# Verify corpus exists
ls corpus/*/
```

### 2. Build Fuzzers

```bash
# Build with AddressSanitizer
./build-fuzzers-local.sh address

# Verify build
ls fuzzers-local/address/
```

### 3. Quick Test (Sanity Check)

```bash
# Run 100 iterations to verify fuzzer works
./fuzzers-local/address/icc_profile_fuzzer \
  corpus/icc_profile_standalone/ \
  -runs=100
```

### 4. Continuous Fuzzing

```bash
# Run indefinitely (Ctrl+C to stop)
./fuzzers-local/address/icc_profile_fuzzer \
  corpus/icc_profile_standalone/ \
  -max_len=10485760 \
  -rss_limit_mb=2560 \
  -timeout=25 \
  -artifact_prefix=crashes/ \
  -print_final_stats=1
```

### 5. Crash Triage

```bash
# Reproduce crash
./fuzzers-local/address/icc_profile_fuzzer crashes/crash-XXXXX

# Minimize crash
./fuzzers-local/address/icc_profile_fuzzer \
  -minimize_crash=1 \
  -runs=10000 \
  crashes/crash-XXXXX
```

### 6. Report & Patch

1. Save crash to `poc-archive/`
2. Analyze root cause
3. Create patch following patterns in this document
4. Test fix with fuzzer
5. Document in CVE-style format (see `NAMEDCOLOR_OOM_CVE_2025.md`)
6. Commit and push

---

## ClusterFuzzLite Specific

### GitHub Actions Configuration

```yaml
# .github/workflows/cfl.yml
name: ClusterFuzzLite Continuous Fuzzing
on:
  workflow_dispatch:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  fuzzing:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        sanitizer: [address, undefined, memory]
    steps:
      - uses: actions/checkout@v3
      - uses: google/clusterfuzzlite/actions/build_fuzzers@v1
        with:
          language: c++
          sanitizer: ${{ matrix.sanitizer }}
      - uses: google/clusterfuzzlite/actions/run_fuzzers@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          fuzz-seconds: 600
          mode: code-change
          sanitizer: ${{ matrix.sanitizer }}
```

### Expected Output

**Normal (No Bugs):**
```
INFO: seed corpus: files: 9 min: 59180b max: 61616b total: 539108b
#9   INITED cov: 2073 ft: 2506 corp: 9/539Kb
...
Done 100000 runs in 600 second(s)
```

**Bug Found:**
```
==12345==ERROR: AddressSanitizer: heap-use-after-free on address 0x...
SUMMARY: AddressSanitizer: heap-use-after-free
```

**Artifacts saved to:** `cifuzz-build-{sanitizer}-{commit}/`

---

## Summary Checklist

### Before Starting Fuzzing Campaign

- [ ] Apply all code modifications from this document
- [ ] Set appropriate RSS limits (`-rss_limit_mb=2560` minimum)
- [ ] Configure sanitizers (ASan + UBSan recommended)
- [ ] Verify corpus exists and is populated
- [ ] Set timeout values (`-timeout=25` for most fuzzers)
- [ ] Create crash artifact directory

### During Fuzzing

- [ ] Monitor fuzzer throughput (exec/s)
- [ ] Watch for coverage growth
- [ ] Check for crashes/artifacts
- [ ] Minimize interesting crashes
- [ ] Add new coverage-interesting inputs to corpus

### After Finding Bugs

- [ ] Reproduce crash with fuzzer
- [ ] Minimize crash input
- [ ] Identify root cause
- [ ] Apply fix following patterns in this document
- [ ] Test fix doesn't break valid inputs
- [ ] Document vulnerability (see CVE templates)
- [ ] Add regression test

---

## Additional Resources

### Documentation
- [NAMEDCOLOR_OOM_CVE_2025.md](./NAMEDCOLOR_OOM_CVE_2025.md) - OOM vulnerability example
- [CORPUS_SUMMARY.md](./CORPUS_SUMMARY.md) - Corpus inventory
- [STANDALONE_FROMXML_FUZZER.md](./STANDALONE_FROMXML_FUZZER.md) - Standalone fuzzer guide

### External Resources
- [LibFuzzer Documentation](https://llvm.org/docs/LibFuzzer.html)
- [ClusterFuzzLite Guide](https://google.github.io/clusterfuzzlite/)
- [Sanitizer Documentation](https://github.com/google/sanitizers/wiki)

### Fuzzer Source Code
- `fuzzers/icc_profile_fuzzer.cpp` - General ICC profile fuzzing
- `fuzzers/icc_fromxml_fuzzer.cpp` - XML parsing with error suppression
- `fuzzers/icc_calculator_fuzzer.cpp` - Calculator element fuzzing
- `fuzzers/icc_spectral_fuzzer.cpp` - Spectral data fuzzing

---

**Maintained By:** xsscx Security Team  
**Last Updated:** 2025-12-21  
**Version:** 1.0  
**Questions?** Open an issue on GitHub


---

## UPDATE 2025-12-21: Second OOM Vulnerability Fixed

### CIccTagMultiProcessElement OOM (6.25GB)

**Discovered:** ClusterFuzzLite run #20413159812  
**Fuzzer:** `icc_roundtrip_fuzzer`  
**Location:** `IccProfLib/IccTagMPE.cpp:1017`  
**Allocation:** `malloc(6710886400)` = 6.25GB  
**Fix:** Commit `d1e1ef8`

**Pattern:** Same as CIccTagNamedColor2 OOM
- Read `m_nProcElements` from untrusted ICC file
- Direct use in `calloc(m_nProcElements, sizeof(icPositionNumber))`
- No validation before allocation

**Fix Applied:**
```cpp
const icUInt32Number MAX_PROC_ELEMENTS = 10000000;
const icUInt64Number MAX_ALLOC_SIZE = 1024ULL * 1024 * 1024; // 1GB

if (m_nProcElements > MAX_PROC_ELEMENTS) return false;

icUInt64Number nTotalSize = (icUInt64Number)m_nProcElements * sizeof(icPositionNumber);
if (nTotalSize > MAX_ALLOC_SIZE) return false;
```

**Lesson:** This demonstrates the importance of **systematic auditing**. Multiple functions had the same vulnerability pattern. All allocations from untrusted input must be validated.

**Action Item:** Complete audit of all `calloc/malloc` calls (see Vulnerability Patterns section above).

