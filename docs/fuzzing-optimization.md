# Fuzzing Optimization Guide - W5-2465X

## System Specifications
- **CPU**: W5-2465X (32-core Xeon)
- **Detected Cores**: 24 (via `nproc`)
- **Storage**: RAID-1 2x Samsung 990 PRO 2TB NVMe M.2 PCIe Gen4
- **Configuration**: `.llmcjf-config.yaml`

## Build Performance Tuning

### Parallel Build Configuration
All build scripts are optimized for 32-core performance:

**CMake Builds:**
```bash
cmake --build . -j32
make -j32
```

**ClusterFuzzLite:**
- Location: `.clusterfuzzlite/build.sh`
- Uses: `-j$(nproc)` (detects 24 cores)
- Optimized for parallel fuzzer compilation

**Local Fuzzer Builds:**
- Script: `build-fuzzers-local.sh`
- Configuration: `-j32` for IccProfLib2-static and IccXML2-static
- Sanitizers: address, undefined, memory

### Compiler Optimization Flags
```bash
CFLAGS="-O2 -march=native -fno-omit-frame-pointer"
CXXFLAGS="-O2 -march=native -fno-omit-frame-pointer"
```

**Native Architecture Tuning:**
- `-march=native`: Optimizes for W5-2465X instruction set
- Enables AVX-512, BMI2, and other CPU-specific optimizations
- Applied to all fuzzer builds for maximum performance

## Storage Optimization

### NVMe Configuration
**RAID-1 Setup:**
- 2x Samsung 990 PRO 2TB drives
- PCIe Gen4 interface (up to 7,450 MB/s read, 6,900 MB/s write)
- Optimized for:
  - Fast corpus loading
  - High-speed crash artifact writing
  - Parallel fuzzer I/O operations

### Corpus Management
**Locations:**
- Main corpus: `./corpus/`
- POC archive: `./poc-archive/` (11 artifacts)
- Seed corpora: `Testing/*.icc`, `Testing/*.xml`

**I/O Optimization:**
- Corpus stored on NVMe for minimum latency
- ClusterFuzzLite artifacts: 90-day retention
- Automatic crash deduplication

## Fuzzing Performance Metrics

### ClusterFuzzLite Configuration
**Sanitizer Matrix:**
```yaml
sanitizers:
  - address    # Heap/stack corruption detection
  - undefined  # UB detection  
  - memory     # Uninitialized memory access
```

**Fuzz Duration:**
- Default: 3600 seconds (1 hour)
- Configurable via workflow_dispatch
- Scheduled runs: Daily at 00:00 UTC

### Local Fuzzing
**Performance Targets:**
- exec/sec: >5000 (per fuzzer)
- Coverage: Maximize edge/feature coverage
- Crashes: Automatic artifact preservation

**Example Command:**
```bash
./fuzzers-local/address/icc_profile_fuzzer \
  -max_len=1048576 \
  -len_control=0 \
  -timeout=60 \
  -rss_limit_mb=6144 \
  -jobs=32 \
  -workers=24 \
  corpus/
```

## LLMCJF Integration

### Strict Engineering Mode
**Active Profiles:**
- `llmcjf/STRICT_ENGINEERING_PROLOGUE.md`
- `llmcjf/profiles/strict_engineering.yaml`
- `llmcjf/profiles/llmcjf-hardmode-ruleset.json`

**Behavioral Constraints:**
- Minimal verbosity
- Technical-only responses
- No content generation drift
- Focus: fuzzing, exploit research, build systems

### Configuration Files
- **Root Config**: `.llmcjf-config.yaml`
- **Copilot Integration**: `.github/copilot-instructions.md`
- **Reports**: `llmcjf/reports/*.md`

## POC Management

### Current Inventory
**Total Artifacts**: 11 (as of 2025-12-21)
- Crashes: 6 (5 valid + 1 empty)
- Leaks: 3  
- OOMs: 2 (1 valid + 1 empty)

**Key PoCs:**
- `crash-31ff7f659128d0da5ffadb7a52a7c545bcfd312a` - Heap UAF (calculator)
- `crash-05806b73da433dd63ab681e582dbf83640a4aac8` - Spectral null deref (XML)
- `poc-heap-overflow-colorant.icc` - Colorant overflow

### Artifact Workflow
1. ClusterFuzzLite detects crash/leak/OOM
2. Artifact preserved to `fuzzing-artifacts/$SANITIZER/`
3. Uploaded to GitHub Actions (90-day retention)
4. Manually archived to `poc-archive/`
5. Inventory updated: `POC_INVENTORY_*.md`

## Build Scripts Reference

### Primary Scripts
| Script | Purpose | Parallelization |
|--------|---------|----------------|
| `build-fuzzers-local.sh` | Local fuzzer builds | `-j32` |
| `build-standalone-fromxml-fuzzer.sh` | Standalone XML fuzzer | `-j32` |
| `.clusterfuzzlite/build.sh` | CI fuzzer builds | `-j$(nproc)` |
| `run-local-fuzzer.sh` | Execute local fuzzers | Variable |

### Test & Reproduce Scripts
| Script | Purpose |
|--------|---------|
| `reproduce-crash.sh` | Replay crash artifacts |
| `reproduce-heap-uaf-calculator.sh` | UAF reproduction |
| `reproduce-npd-spectral.sh` | Null deref reproduction |
| `test-*.sh` | Regression test suite |

## CI/CD Integration

### GitHub Actions Workflows
**ClusterFuzzLite:**
- Workflow: `.github/workflows/clusterfuzzlite.yml`
- Triggers: PR, schedule, workflow_dispatch
- Matrix: 3 sanitizers × fuzzing jobs
- Optimization: LLMCJF-aware, W5-2465X tuned

**PR Validation:**
- `ci-pr-unix.yml` - Multi-OS builds
- `ci-pr-unix-sb.yml` - Scan-build static analysis
- `ci-pr-lint.yml` - Code quality checks

### Build Cache Strategy
**Docker Cache:**
- Cleared on: no-cache=true, PR events
- Preserved for: Scheduled runs
- Layer optimization: Multi-stage builds

## Troubleshooting

### Build Performance Issues
**Symptom**: Slow builds despite 32 cores  
**Solutions**:
- Verify: `nproc` shows 24+
- Check: `/proc/cpuinfo` for all cores
- Confirm: `-j32` in build commands
- Monitor: `htop` during builds

### Fuzzing Performance Issues  
**Symptom**: Low exec/sec (<1000)  
**Solutions**:
- Reduce corpus size
- Increase `-rss_limit_mb`
- Check NVMe I/O (`iostat -x 1`)
- Verify sanitizer overhead

### Crash Reproduction Issues
**Symptom**: PoC doesn't crash locally  
**Solutions**:
- Use exact sanitizer from discovery
- Match ASAN/UBSAN/MSAN flags
- Check libFuzzer version
- Verify input file integrity (SHA256)

## References

- **LLMCJF Documentation**: `llmcjf/README.md`
- **Build Guide**: `docs/build.md`
- **POC Inventory**: `poc-archive/POC_INVENTORY_20251221_153921.md`
- **Copilot Instructions**: `.github/copilot-instructions.md`
- **Project Config**: `.llmcjf-config.yaml`
