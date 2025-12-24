# PoC Archive

This directory contains crash, leak, and OOM (out-of-memory) artifacts discovered during fuzzing campaigns.

## Purpose

- **Reproducibility**: Preserve artifacts for bug verification
- **Regression Testing**: Ensure fixes don't reintroduce bugs
- **Security Research**: Document findings for CVE analysis

## Directory Structure

```
poc-archive/
├── README.md                          # This file
├── POC_INVENTORY_*.md                 # Timestamped inventories
├── reproduce-all.sh                   # Automated reproduction script
├── crash-<hash>                       # Crash PoCs (segfaults, assertions)
├── leak-<hash>                        # Memory leak PoCs (LeakSanitizer)
├── oom-<hash>                         # Out-of-memory PoCs
├── timeout-<hash>                     # Timeout/hang PoCs
└── poc-*.icc                          # Named/annotated PoCs
```

## Current Inventory

| Category | Count | Status |
|----------|-------|--------|
| **Crashes** | 8 | Needs triage |
| **Leaks** | 7 | Documented |
| **OOMs** | 14 | Documented |
| **Total** | 29 | Active |

See latest `POC_INVENTORY_*.md` for detailed metadata.

## Usage

### Reproduce All Artifacts

```bash
# Quick validation (1s timeout per PoC)
./reproduce-all.sh validate

# Full reproduction (10s timeout)
./reproduce-all.sh full

# Leaks only (with LeakSanitizer)
./reproduce-all.sh leak-only
```

### Reproduce Single Artifact

```bash
# With sanitizers enabled
ASAN_OPTIONS=detect_leaks=1 \
  ../Build/icc_profile_fuzzer leak-<hash>

# With UBSan
UBSAN_OPTIONS=print_stacktrace=1 \
  ../Build/icc_fromxml_fuzzer crash-<hash>
```

### Check Fix Status

```bash
# Run artifact against latest build
for poc in crash-* leak-* oom-*; do
  echo "Testing: $poc"
  timeout 5 ../Build/icc_profile_fuzzer "$poc" 2>&1 | \
    grep -E "(ERROR|SUMMARY|LeakSanitizer)" || echo "  ✓ Fixed or non-repro"
done
```

## Artifact Naming Convention

Format: `<type>-<sha1-hash>`

- **type**: `crash`, `leak`, `oom`, `timeout`
- **hash**: SHA-1 of the input that triggered the issue (libFuzzer standard)

Example: `crash-05806b73da433dd63ab681e582dbf83640a4aac8`

## Metadata

Each artifact in the inventory includes:

- **Type**: crash/leak/oom/timeout
- **Size**: File size in bytes
- **SHA256**: Checksum for integrity
- **Created**: Discovery timestamp
- **Sample**: Hex dump of first 50 bytes
- **Fuzzer**: Which fuzzer discovered it (if known)
- **Sanitizer**: ASan/UBSan/MSan/LSan (if known)

## Integration with Fuzzing Workflows

### ClusterFuzzLite Integration

The `.github/workflows/clusterfuzzlite.yml` workflow automatically:
1. Builds fuzzers with address/undefined/memory sanitizers
2. Runs fuzzing campaigns (default: 1 hour)
3. Preserves crash artifacts to GitHub Actions artifacts
4. Uploads findings with 90-day retention

### Local Fuzzing

```bash
# Run local fuzzer with artifact detection
./run-local-fuzzer.sh <fuzzer_name>

# Organize findings into poc-archive
./organize-poc-artifacts.sh
```

## Maintenance

### Adding New PoCs

```bash
# After fuzzing campaign, run:
./organize-poc-artifacts.sh

# This will:
# 1. Find all crash/leak/oom files in root directory
# 2. Generate timestamped inventory
# 3. Copy artifacts to poc-archive/
# 4. Preserve original timestamps and hashes
```

### Removing Fixed PoCs

```bash
# Verify fix first
./reproduce-all.sh validate

# If confirmed fixed, move to fixed/ subdirectory
mkdir -p poc-archive/fixed/
mv poc-archive/crash-<hash> poc-archive/fixed/

# Update inventory
echo "Fixed: crash-<hash> - Issue #NNN" >> FIXES.md
```

## Security Considerations

⚠️ **Warning**: PoC artifacts may trigger exploitable conditions

- Run only in isolated/sandboxed environments
- Do not execute with elevated privileges
- Some PoCs may consume significant resources (OOMs)
- Leaks may accumulate memory over time

## References

- **libFuzzer**: https://llvm.org/docs/LibFuzzer.html
- **Sanitizers**: https://github.com/google/sanitizers
- **ClusterFuzzLite**: https://google.github.io/clusterfuzzlite/

## Contact

- **Maintainer**: @xsscx
- **Repository**: https://github.com/xsscx/iccLibFuzzer
- **Upstream**: https://github.com/InternationalColorConsortium/DemoIccMAX
