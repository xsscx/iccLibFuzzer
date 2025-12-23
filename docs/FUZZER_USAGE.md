# Fuzzer Execution Guide

## Quick Start

### Option 1: Simple Wrapper (Recommended)
```bash
# Default: address sanitizer, icc_profile_fuzzer, 60 seconds
./run-local-fuzzer.sh

# Specify fuzzer
./run-local-fuzzer.sh address icc_calculator_fuzzer

# Specify duration (in seconds)
./run-local-fuzzer.sh address icc_profile_fuzzer 600
```

### Option 2: Master Control Interface
```bash
# Default: address sanitizer, icc_profile_fuzzer, 600 seconds
./fuzzing-control.sh run

# With specific fuzzer
./fuzzing-control.sh run address icc_dump_fuzzer

# With duration
./fuzzing-control.sh run address icc_spectral_fuzzer 3600
```

### Option 3: Direct Execution
```bash
# Must use absolute paths and cd to fuzzer directory
cd fuzzers-local/address
./icc_profile_fuzzer \
  $(realpath icc_profile_fuzzer_seed_corpus)/ \
  -artifact_prefix=$(realpath crashes)/ \
  -max_total_time=60 \
  -rss_limit_mb=6144 \
  -detect_leaks=0
```

## Available Fuzzers

### ICC Profile Fuzzers (86 file corpus)
- `icc_profile_fuzzer` - Profile parsing and validation
- `icc_io_fuzzer` - I/O operations
- `icc_calculator_fuzzer` - Calculator operations
- `icc_spectral_fuzzer` - Spectral data processing
- `icc_multitag_fuzzer` - Multi-tag handling
- `icc_apply_fuzzer` - Profile application
- `icc_applyprofiles_fuzzer` - Multi-profile transforms
- `icc_roundtrip_fuzzer` - Round-trip validation
- `icc_link_fuzzer` - Profile linking
- `icc_dump_fuzzer` - Profile dumping

### XML Fuzzers
- `icc_fromxml_fuzzer` - XML to ICC conversion (173 file corpus)
- `icc_toxml_fuzzer` - ICC to XML conversion (80 file corpus)

## Sanitizer Options

```bash
# Address Sanitizer (heap/stack corruption)
./run-local-fuzzer.sh address <fuzzer> <duration>

# Undefined Behavior Sanitizer
./run-local-fuzzer.sh undefined <fuzzer> <duration>

# Memory Sanitizer (uninitialized memory)
./run-local-fuzzer.sh memory <fuzzer> <duration>
```

## Practical Examples

### Short Test Run (60 seconds)
```bash
./run-local-fuzzer.sh address icc_profile_fuzzer 60
```

### Standard Session (10 minutes)
```bash
./run-local-fuzzer.sh address icc_calculator_fuzzer 600
```

### Extended Fuzzing (1 hour)
```bash
./fuzzing-control.sh run address icc_spectral_fuzzer 3600
```

### Test Multiple Sanitizers
```bash
for san in address undefined memory; do
  ./run-local-fuzzer.sh $san icc_fromxml_fuzzer 300
done
```

### Fuzz All Fuzzers (5 min each)
```bash
for fuzzer in icc_profile_fuzzer icc_calculator_fuzzer icc_spectral_fuzzer; do
  ./run-local-fuzzer.sh address $fuzzer 300
done
```

## Configuration

### Default Parameters
- **Sanitizer**: address
- **Fuzzer**: icc_profile_fuzzer
- **Duration**: 60s (run-local-fuzzer.sh) or 600s (fuzzing-control.sh)
- **RSS Limit**: 6GB (6144 MB)
- **Timeout**: 120 seconds per input
- **Max Length**: 10MB (10000000 bytes)
- **Leak Detection**: Disabled (-detect_leaks=0)

### Corpus Locations
```bash
# ICC fuzzers
fuzzers-local/{sanitizer}/icc_*_fuzzer_seed_corpus/

# Example
fuzzers-local/address/icc_profile_fuzzer_seed_corpus/  # 86 files
fuzzers-local/address/icc_fromxml_fuzzer_seed_corpus/  # 173 files
```

### Crash Output
```bash
# All crashes stored in
fuzzers-local/{sanitizer}/crashes/

# Example
fuzzers-local/address/crashes/crash-da39a3ee5e6b4b0d3255bfef95601890afd80709
fuzzers-local/address/crashes/leak-1bb5f18b5805011a6f37df5d465919ff14e1c020
```

## Verification Commands

### Check Build Status
```bash
./fuzzing-control.sh list
# Shows all built fuzzers
```

### Verify Host Configuration
```bash
./fuzzing-control.sh verify
# Shows cores, storage, optimization settings
```

### Check Corpus
```bash
find fuzzers-local/address -name "*_seed_corpus" -exec sh -c 'echo "$1: $(find "$1" -type f | wc -l) files"' _ {} \;
```

### View Recent Crashes
```bash
./fuzzing-control.sh pocs
# Shows POC inventory

# Or manually
find fuzzers-local/address/crashes -type f -name "crash-*" -o -name "leak-*" -o -name "oom-*"
```

## Build Commands

### Build All Sanitizers
```bash
./build-all-sanitizers.sh
```

### Build Specific Sanitizer
```bash
./build-fuzzers-local.sh address
./build-fuzzers-local.sh undefined
./build-fuzzers-local.sh memory
```

### Populate Corpus
```bash
./populate-corpus.sh
# Populates all fuzzer seed corpora from Testing/ and poc-archive/
```

## Reproduce Crashes

### Using fuzzing-control.sh
```bash
./fuzzing-control.sh reproduce crash-31ff7f659128d0da5ffadb7a52a7c545bcfd312a
./fuzzing-control.sh reproduce crash-05806b73da433dd63ab681e582dbf83640a4aac8 address
```

### Dedicated Reproduce Scripts
```bash
./reproduce-heap-uaf-calculator.sh
./reproduce-npd-spectral.sh
./reproduce-crash.sh
```

## Troubleshooting

### "Fuzzer not found"
```bash
# Build the fuzzer
./build-fuzzers-local.sh address
```

### "Corpus not found"
```bash
# Populate corpus
./populate-corpus.sh
```

### "Empty corpus" warning
```bash
# Check corpus has files
ls fuzzers-local/address/icc_profile_fuzzer_seed_corpus/

# Re-populate if empty
./populate-corpus.sh
```

### Low exec/sec performance
```bash
# Increase RSS limit in script (currently 6GB)
# Reduce corpus size
# Check system resources with htop
```

## Performance Tuning

### W5-2465X Optimized Settings
- **Build parallelization**: -j32
- **Compiler optimization**: -march=native -O2
- **Storage**: NVMe PCIe Gen4 RAID-1
- **Detected cores**: 24 (via nproc)

### Monitor Performance
```bash
# During fuzzing, watch in another terminal
watch -n 1 'find fuzzers-local/address/crashes -type f | wc -l'

# System resources
htop
iostat -x 1
```

## Reference

- **Configuration**: `.llmcjf-config.yaml`
- **Build Guide**: `docs/build.md`
- **Optimization Guide**: `docs/fuzzing-optimization.md`
- **POC Inventory**: `poc-archive/POC_INVENTORY_20251221_153921.md`
- **Master Script**: `fuzzing-control.sh help`
