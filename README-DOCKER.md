# Docker Build and Test Guide for iccLibFuzzer

**Project**: iccLibFuzzer - ICC Color Profile Fuzzing Infrastructure  
**Repository**: https://github.com/xsscx/iccLibFuzzer  
**License**: BSD-3-Clause  
**Updated**: 2025-12-26

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Available Dockerfiles](#available-dockerfiles)
3. [Quick Start](#quick-start)
4. [Building Images](#building-images)
5. [Running Fuzzers](#running-fuzzers)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Usage](#advanced-usage)

---

## Prerequisites

### Required
- Docker 20.10+ or Docker Desktop
- 8GB+ RAM (16GB recommended for multi-sanitizer builds)
- 20GB+ disk space
- Linux, macOS, or Windows with WSL2

### Optional
- Docker Buildx (for multi-platform builds)
- Docker Compose (for orchestration)

### Verify Installation
```bash
docker --version
docker info
```

Expected output:
```
Docker version 24.0.x, build...
Server Version: 24.0.x
```

---

## Available Dockerfiles

### 1. Dockerfile (Production Build Container)
**Purpose**: Full iccDEV build environment with ASan instrumentation  
**Base**: Ubuntu 24.04  
**Size**: ~2.5GB  
**Use Case**: Development, testing, CI/CD validation

**Features**:
- Clang-18 with full sanitizer support
- All ICC tools built and on PATH
- Multi-stage build (builder + runtime)
- Non-root user for security
- Complete test suite included

### 2. Dockerfile.fuzzing (Basic Fuzzer)
**Purpose**: Lightweight single-sanitizer fuzzing  
**Base**: Ubuntu 24.04  
**Size**: ~800MB  
**Use Case**: Quick local testing, CI smoke tests

**Features**:
- Address Sanitizer (ASan) only
- All 13 fuzzers built
- Minimal corpus included
- Fast build time (~5 minutes)

### 3. Dockerfile.libfuzzer (Multi-Sanitizer Suite)
**Purpose**: Comprehensive fuzzing with all sanitizers  
**Base**: Ubuntu 24.04  
**Size**: ~3.5GB  
**Use Case**: Extended fuzzing campaigns, regression testing

**Features**:
- Address Sanitizer (ASan)
- Undefined Behavior Sanitizer (UBSan)
- Memory Sanitizer (MSan)
- Parallel fuzzer execution
- Runner script with configuration

### 4. Dockerfile.iccdev-fuzzer (srdcx/iccdev Base)
**Purpose**: Fuzzing on pre-built iccDEV base image  
**Base**: srdcx/iccdev:latest  
**Size**: ~2GB  
**Use Case**: CI/CD integration, reproducible builds

**Features**:
- ASan and UBSan fuzzers
- Leverages pre-built base image
- Faster iteration (base cached)
- Production-ready configuration

---

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/xsscx/iccLibFuzzer.git
cd iccLibFuzzer
```

### 2. Build Basic Fuzzer
```bash
docker build -f Dockerfile.fuzzing -t icclib-fuzzer:latest .
```

### 3. Run Quick Test
```bash
docker run --rm -it icclib-fuzzer:latest bash
```

Inside container:
```bash
./icc_profile_fuzzer -runs=100
```

Expected: No crashes, 100 executions complete.

---

## Building Images

### Production Build Container
```bash
# Build with default target (debug-asan)
docker build -f Dockerfile -t iccdev:latest .

# Build specific stage
docker build -f Dockerfile --target runtime -t iccdev:runtime .
docker build -f Dockerfile --target debug-asan -t iccdev:debug .

# Multi-platform build (requires buildx)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --target runtime \
  -t iccdev:multiarch \
  -f Dockerfile .
```

**Build time**: 15-25 minutes (first build)  
**Size**: 2.5GB (runtime), 3.2GB (debug)

### Basic Fuzzer
```bash
# Standard build
docker build -f Dockerfile.fuzzing -t icclib-fuzzer:test .

# With build args (optional)
docker build -f Dockerfile.fuzzing \
  --build-arg JOBS=$(nproc) \
  -t icclib-fuzzer:optimized .
```

**Build time**: 5-8 minutes  
**Size**: ~800MB

### Multi-Sanitizer Suite
```bash
# Build all sanitizers
docker build -f Dockerfile.libfuzzer -t icclib-fuzzer:multi .

# Build and tag by date
docker build -f Dockerfile.libfuzzer \
  -t icclib-fuzzer:$(date +%Y%m%d) \
  -t icclib-fuzzer:latest .
```

**Build time**: 20-30 minutes  
**Size**: 3.5GB

### iccdev-Based Fuzzer
```bash
# Pull base image first
docker pull srdcx/iccdev:latest

# Build fuzzer layer
docker build -f Dockerfile.iccdev-fuzzer -t icclib-fuzzer:iccdev .
```

**Build time**: 8-12 minutes (with cached base)  
**Size**: ~2GB

---

## Running Fuzzers

### Interactive Testing
```bash
# Start container with corpus mount
docker run --rm -it \
  -v $(pwd)/corpus:/corpus \
  icclib-fuzzer:test bash

# Inside container - run specific fuzzer
./icc_profile_fuzzer /corpus -max_total_time=60
```

### Automated Fuzzing (Dockerfile.libfuzzer)
```bash
# Run with default settings (ASan, 60s)
docker run --rm \
  -e SANITIZER=address \
  -e FUZZER=icc_profile_fuzzer \
  -e DURATION=60 \
  -e JOBS=4 \
  icclib-fuzzer:multi

# Extended campaign with UBSan
docker run --rm \
  -v $(pwd)/crashes:/fuzzers/crashes \
  -e SANITIZER=undefined \
  -e FUZZER=icc_calculator_fuzzer \
  -e DURATION=3600 \
  -e JOBS=8 \
  icclib-fuzzer:multi
```

### All Fuzzers Parallel
```bash
# Run all 13 fuzzers for 5 minutes each
for fuzzer in icc_profile_fuzzer icc_fromxml_fuzzer icc_toxml_fuzzer \
              icc_calculator_fuzzer icc_spectral_fuzzer icc_multitag_fuzzer \
              icc_io_fuzzer icc_apply_fuzzer icc_applyprofiles_fuzzer \
              icc_applynamedcmm_fuzzer icc_roundtrip_fuzzer \
              icc_link_fuzzer icc_dump_fuzzer; do
  docker run --rm -d \
    --name fuzzer-${fuzzer} \
    -v $(pwd)/crashes:/fuzzers/crashes \
    -e FUZZER=${fuzzer} \
    -e DURATION=300 \
    icclib-fuzzer:multi
done

# Monitor progress
docker ps | grep fuzzer-

# Collect results
docker logs fuzzer-icc_profile_fuzzer
```

---

## Testing

### Smoke Test (All Fuzzers)
```bash
#!/bin/bash
# test-docker-fuzzers.sh

FUZZERS=(
  icc_profile_fuzzer
  icc_fromxml_fuzzer
  icc_toxml_fuzzer
  icc_calculator_fuzzer
  icc_spectral_fuzzer
  icc_multitag_fuzzer
  icc_io_fuzzer
  icc_apply_fuzzer
  icc_applyprofiles_fuzzer
  icc_applynamedcmm_fuzzer
  icc_roundtrip_fuzzer
  icc_link_fuzzer
  icc_dump_fuzzer
)

echo "=== Testing 13 Fuzzers in Docker ==="
docker build -f Dockerfile.fuzzing -t icclib-fuzzer:test . || exit 1

for fuzzer in "${FUZZERS[@]}"; do
  echo "Testing $fuzzer..."
  docker run --rm icclib-fuzzer:test \
    bash -c "./$fuzzer -runs=10 -print_final_stats=1" 2>&1 | \
    grep -E "Done|ERROR" || echo "FAIL: $fuzzer"
done
```

### Crash Reproduction
```bash
# Copy crash file into container
docker run --rm -it \
  -v $(pwd)/crash-a60dedb59fbdfbb226d516ebaf14b04169f11e14:/crash \
  icclib-fuzzer:test bash

# Inside container
./icc_profile_fuzzer /crash -runs=1
```

### Regression Suite
```bash
# Run against known good corpus
docker run --rm \
  -v $(pwd)/corpus:/corpus \
  -v $(pwd)/poc-archive:/pocs:ro \
  icclib-fuzzer:test bash -c '
    for poc in /pocs/crash-*; do
      echo "Testing: $(basename $poc)"
      ./icc_profile_fuzzer "$poc" -runs=1 || exit 1
    done
  '
```

---

## Troubleshooting

### Build Failures

#### Error: "CMAKE_MAKE_PROGRAM is not set"
**Solution**: Missing `make` in dependencies
```bash
# Add to RUN apt-get install in Dockerfile
make \
```

#### Error: "libxml/parser.h not found"
**Cause**: icc_fromxml_fuzzer requires libxml2 headers  
**Solution**: Install libxml2-dev (already in Dockerfile.libfuzzer)

#### Error: "5.5GB context too large"
**Cause**: Entire repo sent to Docker daemon  
**Solution**: Create `.dockerignore`:
```
Build/
fuzzers-local/
*.o
*.a
.git/
```

### Runtime Issues

#### Error: "Permission denied" on corpus
```bash
# Fix permissions
chmod -R 755 corpus/
docker run --rm -v $(pwd)/corpus:/corpus:rw ...
```

#### Error: "Out of memory"
```bash
# Increase Docker memory limit (Docker Desktop → Settings → Resources)
# Or reduce parallel jobs:
docker run -e JOBS=2 ...
```

#### Error: "Address already in use"
```bash
# Clean up running containers
docker ps -a | grep fuzzer | awk '{print $1}' | xargs docker rm -f
```

### Verification

#### Check Built Fuzzers
```bash
docker run --rm icclib-fuzzer:test ls -lh icc_*_fuzzer
```

Expected: 13 executables, 5-15MB each

#### Verify Sanitizer Instrumentation
```bash
docker run --rm icclib-fuzzer:test \
  bash -c './icc_profile_fuzzer -help=1 | grep -i sanitizer'
```

Expected: "AddressSanitizer" or sanitizer options listed

---

## Advanced Usage

### Custom Build with Local Changes
```bash
# Build with uncommitted changes
docker build -f Dockerfile.fuzzing \
  --build-arg JOBS=16 \
  -t icclib-fuzzer:dev \
  --no-cache .
```

### Multi-Stage Debugging
```bash
# Build up to specific stage
docker build -f Dockerfile \
  --target builder \
  -t iccdev:builder .

# Inspect builder stage
docker run --rm -it iccdev:builder bash
```

### Resource Limits
```bash
# Run with memory/CPU limits
docker run --rm \
  --memory=4g \
  --cpus=4 \
  -e JOBS=4 \
  icclib-fuzzer:multi
```

### Persistent Corpus
```bash
# Create named volume
docker volume create fuzzer-corpus

# Run with persistent corpus
docker run --rm \
  -v fuzzer-corpus:/corpus \
  icclib-fuzzer:test bash -c \
  './icc_profile_fuzzer /corpus -max_total_time=3600'

# Backup corpus
docker run --rm \
  -v fuzzer-corpus:/corpus:ro \
  -v $(pwd)/backup:/backup \
  ubuntu tar czf /backup/corpus-$(date +%Y%m%d).tar.gz -C /corpus .
```

### CI/CD Integration
```bash
# GitHub Actions example
docker build -f Dockerfile.libfuzzer -t fuzzer:ci .
docker run --rm \
  -e SANITIZER=address \
  -e DURATION=300 \
  -v $GITHUB_WORKSPACE/crashes:/fuzzers/crashes \
  fuzzer:ci

# Check for crashes
if [ -n "$(ls -A crashes/)" ]; then
  echo "Crashes found!"
  exit 1
fi
```

---

## Performance Tuning

### Parallel Builds
```bash
# Use all available cores
docker build -f Dockerfile.libfuzzer \
  --build-arg JOBS=$(nproc) \
  -t icclib-fuzzer:parallel .
```

### Build Cache Optimization
```bash
# Use BuildKit for layer caching
DOCKER_BUILDKIT=1 docker build -f Dockerfile.fuzzing .

# Multi-stage with cache mounts (requires buildx)
docker buildx build \
  --cache-from type=local,src=/tmp/docker-cache \
  --cache-to type=local,dest=/tmp/docker-cache \
  -f Dockerfile.libfuzzer .
```

### Fuzzing Performance
```bash
# Monitor exec/sec
docker stats fuzzer-container

# Tune libFuzzer options
docker run --rm \
  icclib-fuzzer:test \
  ./icc_profile_fuzzer \
  -max_len=1048576 \
  -rss_limit_mb=2048 \
  -timeout=30 \
  -jobs=$(nproc)
```

---

## Security Best Practices

### Run as Non-Root (Production Container)
```bash
# Already implemented in Dockerfile
docker run --rm -u 1000:1000 \
  --read-only \
  --security-opt no-new-privileges \
  iccdev:latest
```

### Limit Capabilities
```bash
docker run --rm \
  --cap-drop=ALL \
  --cap-add=CHOWN \
  --cap-add=SETUID \
  --cap-add=SETGID \
  icclib-fuzzer:test
```

### Network Isolation
```bash
# No network access needed
docker run --rm --network=none icclib-fuzzer:test
```

---

## Image Sizes and Build Times

| Dockerfile | Base | Size | Build Time | Sanitizers |
|-----------|------|------|------------|------------|
| Dockerfile | Ubuntu 24.04 | 2.5GB | 20-25 min | ASan |
| Dockerfile.fuzzing | Ubuntu 24.04 | 800MB | 5-8 min | ASan |
| Dockerfile.libfuzzer | Ubuntu 24.04 | 3.5GB | 25-30 min | ASan/UBSan/MSan |
| Dockerfile.iccdev-fuzzer | srdcx/iccdev | 2GB | 10-15 min | ASan/UBSan |

*Build times on 8-core 16GB system*

---

## Fuzzer Coverage

All Dockerfiles build these 13 fuzzers:

1. **icc_profile_fuzzer** - Core ICC profile parsing
2. **icc_fromxml_fuzzer** - XML → ICC conversion
3. **icc_toxml_fuzzer** - ICC → XML conversion
4. **icc_calculator_fuzzer** - Calculator element processing
5. **icc_spectral_fuzzer** - Spectral data handling
6. **icc_multitag_fuzzer** - Multiple tag operations
7. **icc_io_fuzzer** - I/O operations
8. **icc_apply_fuzzer** - Profile application
9. **icc_applyprofiles_fuzzer** - TIFF profile application
10. **icc_applynamedcmm_fuzzer** - Named CMM operations
11. **icc_roundtrip_fuzzer** - Round-trip conversions
12. **icc_link_fuzzer** - Profile linking
13. **icc_dump_fuzzer** - Profile inspection

---

## Common Use Cases

### Local Development
```bash
docker build -f Dockerfile.fuzzing -t dev:latest .
docker run --rm -it -v $(pwd):/src dev:latest
```

### Continuous Integration
```bash
docker build -f Dockerfile.libfuzzer -t ci:test .
docker run --rm -e DURATION=600 ci:test
```

### Crash Investigation
```bash
docker run --rm -it \
  -v $(pwd)/crashes:/crashes:ro \
  icclib-fuzzer:test bash
```

### Performance Benchmarking
```bash
docker run --rm \
  --cpus=8 \
  -e JOBS=8 \
  -e DURATION=300 \
  icclib-fuzzer:multi | tee benchmark.log
```

---

## References

- **Project**: https://github.com/xsscx/iccLibFuzzer
- **Base Project**: https://github.com/InternationalColorConsortium/DemoIccMAX
- **libFuzzer**: https://llvm.org/docs/LibFuzzer.html
- **Sanitizers**: https://github.com/google/sanitizers
- **Docker Docs**: https://docs.docker.com

---

## Support

- **Issues**: https://github.com/xsscx/iccLibFuzzer/issues
- **Security**: Report via GitHub Security Advisory
- **Contact**: @xsscx

---

**Last Updated**: 2025-12-26  
**Document Version**: 1.0  
**Maintainer**: GitHub Copilot CLI (LLMCJF strict-engineering mode)
