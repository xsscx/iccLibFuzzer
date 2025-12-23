# One-Liner Commands - Heap Buffer Overflow Reproduction & Validation

## Quick Links
- **Fix Commit:** [1b0c109](https://github.com/xsscx/ipatch/commit/1b0c109)
- **Test Commit:** [9a8672d](https://github.com/xsscx/ipatch/commit/9a8672d)
- **CVE:** Pending Assignment
- **CWE:** CWE-125 (Out-of-bounds Read)

---

## ✅ Test Fixed Code (Recommended First)

### Clone, Build, and Test in One Command
```bash
git clone https://github.com/xsscx/ipatch.git && cd ipatch && cd Build && cmake Cmake -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined" -DCMAKE_C_FLAGS="-fsanitize=address,undefined" && make -j$(nproc) && cd .. && ./test-heap-overflow-colorant.sh
```

### Quick Test with Pre-built PoC
```bash
export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML && Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc
```

### Verify ASan Detects No Issues
```bash
export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML && Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc 2>&1 | grep -E "ASAN|heap-buffer-overflow" && echo "FAIL" || echo "PASS: Clean execution"
```

---

## 🔴 Reproduce Original Crash (Before Fix)

### Automated Before/After Test
```bash
./test-before-fix.sh
```

### Manual Reproduction (Revert to Vulnerable Code)
```bash
# 1. Backup fixed code
cp IccProfLib/IccTagBasic.cpp IccProfLib/IccTagBasic.cpp.fixed

# 2. Revert to vulnerable version
git show 1b0c109 -- IccProfLib/IccTagBasic.cpp | patch -R -p1

# 3. Rebuild with vulnerable code
cd Build && make -j$(nproc) IccProfLib2 && cd ..

# 4. Test (SHOULD crash)
export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML && Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc

# 5. Restore fixed code
mv IccProfLib/IccTagBasic.cpp.fixed IccProfLib/IccTagBasic.cpp

# 6. Rebuild and verify fix
cd Build && make -j$(nproc) IccProfLib2 && cd .. && export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML && Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc
```

### Compare Vulnerable vs Fixed (Single Command)
```bash
git show 1b0c109
```

---

## 🔬 Advanced Testing

### Generate Custom PoC
```bash
python3 create_colorant_overflow_poc.py && mv poc-heap-overflow-colorant.icc poc-custom.icc && export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML && Build/Tools/IccDumpProfile/iccDumpProfile poc-custom.icc
```

### Test with Verbose ASan Output
```bash
ASAN_OPTIONS=verbosity=1:log_path=/tmp/asan.log export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML && Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc && cat /tmp/asan.log.* 2>/dev/null || echo "No ASan errors"
```

### Verify Fix in Source Code
```bash
grep -n "strnlen" IccProfLib/IccTagBasic.cpp | grep -E "8903|8921"
```

### Show Exact Changes
```bash
git diff 1b0c109^..1b0c109 -- IccProfLib/IccTagBasic.cpp
```

---

## 🐳 Docker Isolated Testing

### Complete Test in Fresh Container
```bash
docker run -it --rm ubuntu:22.04 bash -c "apt-get update && apt-get install -y git cmake build-essential python3 libxml2-dev libtiff-dev libjpeg-dev libpng-dev && git clone https://github.com/xsscx/ipatch.git && cd ipatch && cd Build && cmake Cmake -DCMAKE_CXX_FLAGS='-fsanitize=address,undefined' -DCMAKE_C_FLAGS='-fsanitize=address,undefined' && make -j\$(nproc) && cd .. && ./test-heap-overflow-colorant.sh"
```

### Test Vulnerable Code in Docker
```bash
docker run -it --rm ubuntu:22.04 bash -c "apt-get update && apt-get install -y git cmake build-essential python3 libxml2-dev libtiff-dev libjpeg-dev libpng-dev && git clone https://github.com/xsscx/ipatch.git && cd ipatch && git show 1b0c109 -- IccProfLib/IccTagBasic.cpp | patch -R -p1 && cd Build && cmake Cmake -DCMAKE_CXX_FLAGS='-fsanitize=address,undefined' && make -j\$(nproc) && cd .. && export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML && Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc"
```

---

## 📊 Expected Results

### Before Fix (Vulnerable Code)
```
==XXXXX==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x...
READ of size 154 at 0x... thread T0
SCARINESS: 26 (multi-byte-read-heap-buffer-overflow)

    #1 CIccTagColorantTable::Describe() IccTagBasic.cpp:8903:28
    
SUMMARY: AddressSanitizer: heap-buffer-overflow
```

### After Fix (Patched Code)
```
Profile:            'poc-archive/poc-heap-overflow-colorant.icc'
Profile Class:      NamedColorClass
colorantTableTag  NULL       144      50       0

EXIT 0
```

---

## 📝 Validation Checklist

- [ ] Clone repository successfully
- [ ] Build completes without errors (with ASan)
- [ ] Fixed code: No crash, clean exit
- [ ] Fixed code: No ASan heap-buffer-overflow errors
- [ ] Vulnerable code: DOES crash with ASan error
- [ ] Vulnerable code: Shows "heap-buffer-overflow" at line 8903
- [ ] Patch restoration: Returns to clean execution
- [ ] Source code shows `strnlen()` at lines 8903, 8921

---

## 🎯 Copy-Paste Test Sequences

### Test 1: Verify Fix Works (30 seconds)
```bash
git clone https://github.com/xsscx/ipatch.git && \
cd ipatch && \
cd Build && cmake Cmake -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined" && make -j$(nproc) && cd .. && \
./test-heap-overflow-colorant.sh
```

### Test 2: Reproduce Original Crash (60 seconds)
```bash
cd ipatch && ./test-before-fix.sh
```

### Test 3: Quick Manual Test
```bash
cd ipatch && \
export LD_LIBRARY_PATH=Build/IccProfLib:Build/IccXML && \
Build/Tools/IccDumpProfile/iccDumpProfile poc-archive/poc-heap-overflow-colorant.icc
```

---

## 📚 Reference

- **Vulnerability:** Unbounded `strlen()` on non-null-terminated 32-byte buffer
- **Location:** `IccProfLib/IccTagBasic.cpp:8903, 8921`
- **Fix:** Replace `strlen()` with `strnlen(buf, 32)`
- **Impact:** Prevents heap information disclosure and crash
- **Discovered:** ClusterFuzzLite Run #20414703135
- **Fuzzer:** icc_profile_fuzzer
- **Sanitizer:** AddressSanitizer

