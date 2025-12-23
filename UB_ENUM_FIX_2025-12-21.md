# UB Enum Fix - icMaxEnumType → icSigUnknownType

**Date:** 2025-12-21  
**Issue:** ClusterFuzzLite UBSan failures  
**GitHub Actions:** https://github.com/xsscx/ipatch/actions/runs/20412642064/job/58651719118

## Root Cause

**File:** `IccProfLib/IccTagBasic.h:127`  
**Function:** `CIccTag::GetType()`

Base implementation returned `icMaxEnumType` (0xFFFFFFFF) which is outside valid enum range, triggering UBSan runtime errors when value is loaded/used.

### Pattern (CVE-2023-44062)
Enum sentinel value `icMaxEnum*` used as return type causes undefined behavior:
- Sentinel is `0xFFFFFFFF` (max uint32)
- Valid enum values are 4-byte signatures (e.g., `0x74657874` for 'text')
- Loading out-of-range enum value = UB

## Fix

```cpp
// Before (UB):
virtual icTagTypeSignature GetType() const { return icMaxEnumType; }      // 0xFFFFFFFF
virtual icStructSignature GetTagStructType() const { return icSigUndefinedStruct; }
virtual icArraySignature GetTagArrayType() const { return icSigUndefinedArray; }

// After (valid):
virtual icTagTypeSignature GetType() const { return icSigUnknownType; }  // 0x3f3f3f3f '????'
virtual icStructSignature GetTagStructType() const { return icSigUnknownStruct; }
virtual icArraySignature GetTagArrayType() const { return icSigUnknownArray; }
```

### Changes:
1. `icMaxEnumType` → `icSigUnknownType` (0x3f3f3f3f, ASCII '????')
2. `icSigUndefinedStruct` → `icSigUnknownStruct` (consistency)
3. `icSigUndefinedArray` → `icSigUnknownArray` (consistency)

## Testing

**Build:** UBSan clean  
**Runtime:** 100 runs, no UBSan errors

```bash
./build-fuzzers-local.sh undefined
./fuzzers-local/undefined/icc_profile_fuzzer Testing/Calc/*.icc -runs=50
./fuzzers-local/undefined/icc_dump_fuzzer Testing/Display/*.icc -runs=50
# No "runtime error" output
```

## Pattern Rule

**Use for returns:** `icSigUnknown*` (valid enum values)  
**Use for checks:** `icMaxEnum*` (sentinel/max, never return)

### All icMaxEnum* Sentinels:
- `icMaxEnumType` (0xFFFFFFFF) - tag types
- `icMaxEnumStruct` (0xFFFFFFFF) - struct signatures  
- `icMaxEnumArray` (0xFFFFFFFF) - array signatures
- `icMaxEnumFlare` (0xFFFFFFFF) - flare geometries
- `icMaxEnumTag` (0xFFFFFFFF) - tag signatures
- `icMaxEnumTechnology` (0xFFFFFFFF) - technologies
- etc. (all use 0xFFFFFFFF)

**Rule:** Never return `icMaxEnum*` values - they're for internal bounds checking only.

## Related

**CVE-2023-44062:** Enum conversion UB (flare geometry)  
**Similar fixes needed:** Audit all `return icMaxEnum*` patterns

## Commit

**SHA:** 7192e39  
**Message:** fix: Replace icMaxEnumType with icSigUnknownType to avoid UB

---
**Status:** ✅ FIXED AND PUSHED  
**CI:** Will verify on next ClusterFuzzLite run
