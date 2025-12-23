# Heap Buffer Overflow in CIccTagColorantTable::Describe()

**Discovered:** ClusterFuzzLite Run #20414703135 (2025-12-21)  
**Fuzzer:** icc_profile_fuzzer  
**Sanitizer:** AddressSanitizer  
**Severity:** HIGH (CWE-125: Out-of-bounds Read)

## Error Report

```
==50==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x7cb6f01f79e0
READ of size 154 at 0x7cb6f01f79e0 thread T0
SCARINESS: 26 (multi-byte-read-heap-buffer-overflow)

#1 CIccTagColorantTable::Describe() /src/ipatch/IccProfLib/IccTagBasic.cpp:8903:28
#2 LLVMFuzzerTestOneInput /src/ipatch/fuzzers/icc_profile_fuzzer.cpp:65:14
```

## Root Cause

**File:** `IccProfLib/IccTagBasic.cpp`  
**Lines:** 8903, 8921

The `icColorantTableEntry.name` field is a fixed 32-byte buffer:
```c
typedef struct {
    icInt8Number    name[32];      /* Colorant name */
    icUInt16Number  data[3];        /* PCS values   */
} icColorantTableEntry;
```

When reading from ICC profiles, this buffer is populated without null termination:
```cpp
// Line 8826 - Direct read from file, no null termination
if (pIO->Read8(&m_pData[i].name[0], nNum8) != nNum8)
    return false;
```

Later in `Describe()`, `strlen()` is called on this buffer:
```cpp
// Line 8903 - VULNERABLE
nLen = (icUInt32Number)strlen(m_pData[i].name);

// Line 8921 - VULNERABLE  
buf[nMaxLen + 1 - strlen(m_pData[i].name)] ='\0';
```

If all 32 bytes are filled with non-null data, `strlen()` reads beyond the allocated buffer searching for a null terminator.

## Exploitation Scenario

A malicious ICC profile with colorant table entry containing 32 non-null bytes:
```
Colorant Entry: "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456" (32 bytes, no null)
```

When `Describe()` calls `strlen()`, it reads past the 32-byte boundary into adjacent heap memory, causing:
1. Heap buffer overflow read (information disclosure)
2. Potential crash if next memory region is unmapped
3. Undefined behavior in subsequent calculations

## Fix

Use `strnlen()` to limit strlen scan to buffer size:

```cpp
// Before:
nLen = (icUInt32Number)strlen(m_pData[i].name);

// After:
nLen = (icUInt32Number)strnlen(m_pData[i].name, sizeof(m_pData[i].name));
```

Additionally, use printf width specifier to prevent buffer overruns:
```cpp
// Before:
snprintf(buf, bufSize, "%2u \"%s\"", i, m_pData[i].name);

// After:
snprintf(buf, bufSize, "%2u \"%.*s\"", i, (int)sizeof(m_pData[i].name), m_pData[i].name);
```

## Crash Artifact

**Mutation:** InsertRepeatedBytes-CopyPart-CrossOver  
**Base Unit:** 5494c5a2bd42cf123d3ea82d8923b16fb3a474f7  
**Crash File:** crash-de2780e37020b6168a2c7bfe2f3ed238aa89850d

## Impact

- **Confidentiality:** Medium (heap memory disclosure)
- **Availability:** High (crash on malformed profiles)
- **Integrity:** None

## Testing

After fix, verify no overflow:
```bash
export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML
Build/Tools/IccDumpProfile/iccDumpProfile <crash-file>
```

