# Fuzzing Artifacts Directory

This directory contains downloaded artifacts from ClusterFuzzLite CI runs.

## Structure

```
artifacts/
├── downloads/           # Downloaded CI build artifacts
│   └── cifuzz-build-*   # Fuzzer binaries and corpus from CI
└── README.md           # This file
```

## Usage

### Download Artifacts from CI

```bash
# Download all artifacts from a specific run
gh run download <run-id> --repo xsscx/iccLibFuzzer -D artifacts/downloads/

# Download specific artifact
gh run download <run-id> --repo xsscx/iccLibFuzzer --name <artifact-name> -D artifacts/downloads/
```

### Extract Downloaded Artifacts

```bash
cd artifacts/downloads/
tar -xf cifuzz-build-*.tar
```

## Crash Artifacts

Crash artifacts are named: `fuzzing-crashes-{sanitizer}-{commit-sha}`

These contain:
- `crash-*` - Crash reproducer files
- `oom-*` - Out-of-memory reproducer files  
- `leak-*` - Memory leak reproducer files
- `checksums.txt` - SHA256 checksums of all files

## Notes

- This directory is excluded from git via .gitignore
- Artifacts expire after 90 days (configurable in workflow)
- Build artifacts contain fuzzer binaries + seed corpus
- Crash artifacts contain reproducers for discovered bugs
