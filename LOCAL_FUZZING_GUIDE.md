# Local Fuzzing Quick Reference

## Build Fuzzers

### Build All Sanitizers (Address + Undefined)
```bash
./build-all-sanitizers.sh
```

**Output**: `fuzzers-local/address/` and `fuzzers-local/undefined/`

### Build Single Sanitizer
```bash
./build-fuzzers-local.sh address     # AddressSanitizer
./build-fuzzers-local.sh undefined   # UndefinedBehaviorSanitizer
```

**Note**: Memory sanitizer requires libc++ (CI/CD only)

---

## Run Fuzzers

### Quick Test (60 seconds)
```bash
# Address sanitizer
fuzzers-local/address/icc_profile_fuzzer \
  fuzzers-local/address/icc_profile_fuzzer_seed_corpus \
  -max_total_time=60

# XML fuzzer
fuzzers-local/address/icc_fromxml_fuzzer \
  fuzzers-local/address/icc_fromxml_fuzzer_seed_corpus \
  -max_total_time=60
```

### Extended Run (1 hour)
```bash
fuzzers-local/address/icc_profile_fuzzer \
  fuzzers-local/address/icc_profile_fuzzer_seed_corpus \
  -max_total_time=3600 \
  -timeout=45 \
  -rss_limit_mb=8192
```

### All Available Fuzzers
- `icc_profile_fuzzer` - ICC binary profile parsing
- `icc_fromxml_fuzzer` - XML to ICC conversion
- `icc_toxml_fuzzer` - ICC to XML conversion
- `icc_calculator_fuzzer` - Calculator element processing
- `icc_spectral_fuzzer` - Spectral data handling
- `icc_io_fuzzer` - I/O operations
- `icc_multitag_fuzzer` - Multi-tag profiles
- `icc_apply_fuzzer` - Profile application
- `icc_applyprofiles_fuzzer` - TIFF profile application
- `icc_roundtrip_fuzzer` - Round-trip conversion
- `icc_link_fuzzer` - Profile linking
- `icc_dump_fuzzer` - Profile dumping

---

## Useful Options

```bash
-max_total_time=N      # Run for N seconds
-timeout=N             # Timeout per input (default: 45s)
-rss_limit_mb=N        # Memory limit (default: 8192MB)
-jobs=N                # Parallel workers (default: auto)
-workers=N             # Number of processes
-max_len=N             # Max input size (15MB for binary, 5MB for XML)
-dict=file.dict        # Use fuzzing dictionary
-print_final_stats=1   # Show statistics at end
-exact_artifact_path=crash-file  # Save crash to specific file
```

---

## Check for Crashes

```bash
# List crashes
ls -lh fuzzers-local/address/crashes/

# Count crashes
find fuzzers-local/address/crashes -name "crash-*" | wc -l

# Test crash reproduction
fuzzers-local/address/icc_profile_fuzzer \
  fuzzers-local/address/crashes/crash-XXXXX
```

---

## Parallel Fuzzing

```bash
# Run 24 parallel jobs (W5-2465X optimized)
fuzzers-local/address/icc_profile_fuzzer \
  fuzzers-local/address/icc_profile_fuzzer_seed_corpus \
  -jobs=24 \
  -workers=24 \
  -max_total_time=3600
```

---

## Compare Sanitizers

```bash
# Same fuzzer, different sanitizers
fuzzers-local/address/icc_profile_fuzzer corpus/ -max_total_time=300
fuzzers-local/undefined/icc_profile_fuzzer corpus/ -max_total_time=300
```

---

## Full Workflow Example

```bash
# 1. Build
./build-all-sanitizers.sh

# 2. Quick test
fuzzers-local/address/icc_profile_fuzzer \
  fuzzers-local/address/icc_profile_fuzzer_seed_corpus \
  -max_total_time=60 \
  -print_final_stats=1

# 3. Extended fuzzing (1 hour, parallel)
fuzzers-local/address/icc_profile_fuzzer \
  fuzzers-local/address/icc_profile_fuzzer_seed_corpus \
  -max_total_time=3600 \
  -jobs=24 \
  -workers=24 \
  -timeout=45 \
  -rss_limit_mb=8192 \
  -print_final_stats=1

# 4. Check results
ls -lh fuzzers-local/address/crashes/
```

---

## Tips

- **Start small**: 60-second runs to verify everything works
- **Use parallel**: `-jobs=24 -workers=24` for W5-2465X
- **Monitor resources**: `htop` to watch CPU/memory
- **Corpus grows**: New interesting inputs saved automatically
- **Address sanitizer first**: Catches most memory bugs
- **Undefined for UB**: Catches integer overflows, bad casts, etc.

---

## Troubleshooting

**Build fails**: Check dependencies
```bash
sudo apt install clang cmake libxml2-dev libtiff-dev libjpeg-dev
```

**OOM during fuzzing**: Reduce `-rss_limit_mb` or `-jobs`

**No crashes found**: Normal - means code is robust

**Want more speed**: Increase `-jobs` up to 32 for W5-2465X

---

**Quick Reference Created**: 2025-12-24  
**Host**: W5-2465X (32-core)  
**Sanitizers**: Address + Undefined (Memory in CI only)
