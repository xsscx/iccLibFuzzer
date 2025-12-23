#!/bin/bash
set -euo pipefail

# Fuzzing Control Script - W5-2465X Optimized
# Master control interface for local fuzzing operations
# Reference: .llmcjf-config.yaml, docs/fuzzing-optimization.md
# Usage: ./fuzzing-control.sh <command> [args]
# Defaults: sanitizer=address, fuzzer=icc_profile_fuzzer, duration=600s

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Host Configuration
HOST_CORES=32
DETECTED_CORES=$(nproc)
BUILD_JOBS=32

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
  echo -e "${GREEN}================================${NC}"
  echo -e "${GREEN}$1${NC}"
  echo -e "${GREEN}================================${NC}"
}

print_status() {
  echo -e "${YELLOW}[*]${NC} $1"
}

print_error() {
  echo -e "${RED}[!]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[✓]${NC} $1"
}

# Verify host configuration
verify_host() {
  print_header "Host Configuration"
  echo "Expected Cores: $HOST_CORES"
  echo "Detected Cores: $DETECTED_CORES"
  echo "Build Jobs: -j$BUILD_JOBS"
  
  if [ "$DETECTED_CORES" -lt 24 ]; then
    print_error "Warning: Detected cores ($DETECTED_CORES) less than expected"
  fi
  
  # Check for NVMe storage
  if lsblk -d -o name,rota | grep -q '0$'; then
    print_success "NVMe storage detected"
  else
    print_status "Warning: NVMe storage not detected"
  fi
}

# Build all fuzzers for all sanitizers
build_all() {
  print_header "Building All Fuzzers"
  
  for sanitizer in address undefined memory; do
    print_status "Building $sanitizer sanitizer..."
    ./build-fuzzers-local.sh "$sanitizer" || {
      print_error "Failed to build $sanitizer sanitizer"
      return 1
    }
    print_success "$sanitizer sanitizer built"
  done
  
  print_success "All sanitizers built successfully"
}

# Run fuzzer with specified sanitizer
run_fuzzer() {
  local sanitizer="${1:-address}"
  local fuzzer="${2:-icc_profile_fuzzer}"
  local duration="${3:-600}"
  
  print_header "Running $fuzzer ($sanitizer)"
  
  FUZZER_BIN="./fuzzers-local/$sanitizer/$fuzzer"
  
  if [ ! -f "$FUZZER_BIN" ]; then
    print_error "Fuzzer not found: $FUZZER_BIN"
    print_status "Run: $0 build-all"
    return 1
  fi
  
  CORPUS_DIR="./fuzzers-local/$sanitizer/${fuzzer}_seed_corpus"
  
  if [ ! -d "$CORPUS_DIR" ]; then
    print_error "Corpus not found: $CORPUS_DIR"
    print_status "Run: ./populate-corpus.sh"
    return 1
  fi
  
  CRASH_DIR="./fuzzers-local/$sanitizer/crashes"
  mkdir -p "$CRASH_DIR"
  CRASH_DIR_ABS="$(realpath "$CRASH_DIR")"
  CORPUS_DIR_ABS="$(realpath "$CORPUS_DIR")"
  
  CORPUS_COUNT=$(find "$CORPUS_DIR" -type f | wc -l)
  
  print_status "Fuzzer: $FUZZER_BIN"
  print_status "Corpus: $CORPUS_DIR_ABS ($CORPUS_COUNT files)"
  print_status "Crashes: $CRASH_DIR_ABS"
  print_status "Duration: ${duration}s"
  print_status "RSS limit: 6GB"
  
  cd "$(dirname "$FUZZER_BIN")"
  ./"$(basename "$FUZZER_BIN")" \
    "$CORPUS_DIR_ABS/" \
    -artifact_prefix="$CRASH_DIR_ABS/" \
    -max_total_time="$duration" \
    -timeout=120 \
    -rss_limit_mb=6144 \
    -max_len=10000000 \
    -detect_leaks=0 || print_error "Fuzzer exited with errors"
}

# List available fuzzers
list_fuzzers() {
  print_header "Available Fuzzers"
  
  if [ -d "./fuzzers-local/address" ]; then
    ls -1 ./fuzzers-local/address/ | grep _fuzzer$ || echo "No fuzzers found"
  else
    print_error "No fuzzers built. Run: $0 build-all"
  fi
}

# Clean build artifacts
clean_all() {
  print_header "Cleaning Build Artifacts"
  
  print_status "Removing fuzzer binaries..."
  rm -rf ./fuzzers-local/
  
  print_status "Removing build directories..."
  find ./Build/Cmake -type d -name "build_local_*" -exec rm -rf {} + 2>/dev/null || true
  
  print_success "Clean complete"
}

# Reproduce crash from POC archive
reproduce_crash() {
  local poc_file="${1:-}"
  local sanitizer="${2:-address}"
  
  if [ -z "$poc_file" ]; then
    print_error "Usage: $0 reproduce <poc-file> [sanitizer]"
    print_status "Available PoCs:"
    ls -1 ./poc-archive/ | grep -E '^(crash|leak|oom)-' | head -10
    return 1
  fi
  
  print_header "Reproducing: $poc_file"
  
  # Detect fuzzer from filename
  if [[ "$poc_file" == *"xml"* ]]; then
    FUZZER="icc_fromxml_fuzzer"
  else
    FUZZER="icc_profile_fuzzer"
  fi
  
  FUZZER_BIN="./fuzzers-local/$sanitizer/$FUZZER"
  POC_PATH="./poc-archive/$poc_file"
  
  if [ ! -f "$FUZZER_BIN" ]; then
    print_error "Fuzzer not found: $FUZZER_BIN"
    return 1
  fi
  
  if [ ! -f "$POC_PATH" ]; then
    print_error "PoC not found: $POC_PATH"
    return 1
  fi
  
  print_status "Fuzzer: $FUZZER_BIN"
  print_status "PoC: $POC_PATH"
  print_status "Sanitizer: $sanitizer"
  
  "$FUZZER_BIN" "$POC_PATH" || print_error "Reproduction failed"
}

# Show POC inventory
show_pocs() {
  print_header "POC Inventory"
  
  if [ -f "./poc-archive/POC_INVENTORY_20251221_153921.md" ]; then
    cat ./poc-archive/POC_INVENTORY_20251221_153921.md | head -90
  else
    print_error "POC inventory not found"
  fi
}

# Usage information
usage() {
  cat << EOF
Fuzzing Control Script - W5-2465X Optimized
Reference: .llmcjf-config.yaml, docs/fuzzing-optimization.md

Usage: $0 <command> [options]

Commands:
  verify          Verify host configuration
  build-all       Build all fuzzers (address, undefined, memory)
  list            List available fuzzers
  run [san] [fuz] [dur]
                  Run fuzzer (defaults: address icc_profile_fuzzer 600)
  reproduce <poc> [san]
                  Reproduce crash (defaults: sanitizer=address)
  pocs            Show POC inventory
  clean           Clean all build artifacts
  help            Show this help message

Defaults:
  Sanitizer:  address (options: address, undefined, memory)
  Fuzzer:     icc_profile_fuzzer
  Duration:   600 seconds
  RSS Limit:  6GB

Examples:
  $0 verify
  $0 build-all
  $0 list
  $0 run                                    # Use all defaults
  $0 run address                            # Default fuzzer, 600s
  $0 run address icc_calculator_fuzzer      # Default duration
  $0 run address icc_profile_fuzzer 3600    # All explicit
  $0 reproduce crash-31ff7f659128d0da5ffadb7a52a7c545bcfd312a
  $0 reproduce crash-05806b73da433dd63ab681e582dbf83640a4aac8 address
  $0 pocs
  $0 clean

Configuration:
  Host Cores: $HOST_CORES (detected: $DETECTED_CORES)
  Build Jobs: -j$BUILD_JOBS
  LLMCJF Mode: strict-engineering
  Storage: RAID-1 NVMe PCIe Gen4

EOF
}

# Main command dispatcher
case "${1:-help}" in
  verify)
    verify_host
    ;;
  build-all)
    verify_host
    build_all
    ;;
  list)
    list_fuzzers
    ;;
  run)
    run_fuzzer "${2:-address}" "${3:-icc_profile_fuzzer}" "${4:-600}"
    ;;
  reproduce)
    reproduce_crash "${2:-}" "${3:-address}"
    ;;
  pocs)
    show_pocs
    ;;
  clean)
    clean_all
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    print_error "Unknown command: $1"
    usage
    exit 1
    ;;
esac
