# PoC Extraction from ClusterFuzzLite Run #20414703135

## Question
How do we obtain the PoC that triggered `AddressSanitizer: heap-buffer-overflow` at step 7:3268?

## Answer: PoC Not Recoverable from CI Artifacts

### Why the PoC is Missing

The crash occurred in ClusterFuzzLite CI run, which:

1. **Generated the crash file during fuzzing:**
   ```
   artifact_prefix='/tmp/tmpy2fprbit/';
   Test unit written to /tmp/tmpy2fprbit/crash-de2780e37020b6168a2c7bfe2f3ed238aa89850d
   ```

2. **Deleted it after reproduction:**
   ```
   2025-12-21 19:42:21,898 - root - INFO - Deleting corpus and seed corpus
   2025-12-21 19:42:21,915 - root - INFO - Deleting fuzz target: icc_profile_fuzzer
   2025-12-21 19:42:21,917 - root - INFO - Done deleting
   ```

3. **Only uploaded build artifacts (not crash files):**
   - `cifuzz-build-address-*.tar` (fuzzer binaries + seed corpus)
   - `cifuzz-build-memory-*.tar` (fuzzer binaries + seed corpus)
   - `cifuzz-build-undefined-*.tar` (fuzzer binaries + seed corpus)

### What We Know About the Crash

From the CI logs (`1_fuzzing (address).txt`):

```
Mutation: MS: 3 InsertRepeatedBytes-CopyPart-CrossOver
Base Unit: 5494c5a2bd42cf123d3ea82d8923b16fb3a474f7 (SHA-1)
Crash Hash: crash-de2780e37020b6168a2c7bfe2f3ed238aa89850d
```

**Mutation Operations:**
- `InsertRepeatedBytes` - Inserted repeated byte sequences
- `CopyPart` - Copied part of the input
- `CrossOver` - Combined with another corpus entry

The fuzzer took an existing corpus file (SHA-1: 5494c5a2b...) and applied three mutations to create a variant that triggers the crash.

### Why the Base Unit Can't Be Found

The SHA-1 hash `5494c5a2bd42cf123d3ea82d8923b16fb3a474f7` doesn't match any file in:
- Seed corpus (checked all `.icc` files)
- ClusterFuzzLite build artifacts
- Local repository corpus

**Conclusion:** The base unit was also generated during a previous fuzzing run and added to the runtime corpus, but not saved as a seed file.

---

## Solution: Synthetic PoC (Functionally Equivalent)

Since we understand the **root cause** from the ASan report, we created a synthetic PoC:

### Root Cause
```
CIccTagColorantTable::Describe() at IccTagBasic.cpp:8903
strlen() called on non-null-terminated 32-byte buffer
```

### Synthetic PoC Created
**File:** `poc-archive/poc-heap-overflow-colorant.icc` (194 bytes)

**Key Trigger:**
```c
// icColorantTableEntry structure
typedef struct {
    icInt8Number   name[32];    // ← 32 bytes, NO null terminator
    icUInt16Number data[3];
} icColorantTableEntry;

// PoC fills all 32 bytes with 'A' (0x41)
name = b'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'  // Exactly 32 bytes, no \0
```

**Generator:** `create_colorant_overflow_poc.py`

**Validation:** `test-heap-overflow-colorant.sh`

---

## Verification

### The Synthetic PoC is Equivalent

Both trigger the same vulnerability:

**CI Crash (original):**
```
==50==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x7cb6f01f79e0
READ of size 154 at 0x7cb6f01f79e0
#1 CIccTagColorantTable::Describe() IccTagBasic.cpp:8903:28
```

**Synthetic PoC (our creation):**
```
Same code path: CIccTagColorantTable::Describe():8903
Same issue: strlen() reads beyond 32-byte buffer
Same fix: Replace strlen() with strnlen()
```

### Testing

```bash
# Test with our synthetic PoC (before fix - should crash)
git show 1b0c109 -- IccProfLib/IccTagBasic.cpp | patch -R -p1
cd Build && make -j$(nproc) && cd ..
export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML
Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc
# Result: AddressSanitizer: heap-buffer-overflow ✓

# Test with our synthetic PoC (after fix - should pass)
git checkout IccProfLib/IccTagBasic.cpp
cd Build && make -j$(nproc) && cd ..
Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc
# Result: EXIT 0 (clean execution) ✓
```

---

## Alternative: Request OSS-Fuzz Integration

If this were an OSS-Fuzz project (not just ClusterFuzzLite), crash files would be:
- Automatically uploaded to OSS-Fuzz infrastructure
- Accessible via OSS-Fuzz web interface
- Stored with full reproduction details
- Linked to bug reports

**For ClusterFuzzLite:** Crash files are ephemeral (CI-only, deleted after run).

---

## Summary

| Aspect | Status |
|--------|--------|
| Original CI PoC | ❌ Not recoverable (deleted by CI) |
| Base unit file | ❌ Not in seed corpus (runtime-generated) |
| Crash reproduction | ✅ Synthetic PoC created |
| Vulnerability validation | ✅ Confirmed with synthetic PoC |
| Fix effectiveness | ✅ Verified (ASan clean) |

**Recommendation:** Use our synthetic PoC (`poc-archive/poc-heap-overflow-colorant.icc`) for:
- Local testing and validation
- Regression testing
- CVE proof-of-concept
- Security research

The synthetic PoC is **functionally equivalent** to the CI crash because it triggers the same code path with the same vulnerability condition (non-null-terminated 32-byte buffer).

---

## References

- **CI Run:** https://github.com/xsscx/ipatch/actions/runs/20414703135/job/58656619220
- **Fix Commit:** [1b0c109](https://github.com/xsscx/ipatch/commit/1b0c109)
- **Synthetic PoC:** `poc-archive/poc-heap-overflow-colorant.icc`
- **Test Script:** `./test-heap-overflow-colorant.sh`
- **Analysis:** `heap-overflow-colorant-analysis.md`
