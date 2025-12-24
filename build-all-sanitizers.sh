#!/bin/bash
set -euo pipefail

# Build All Sanitizers - W5-2465X Optimized
# Convenience script for building all fuzzer variants
# Reference: .llmcjf-config.yaml, llmcjf/profiles/strict_engineering.yaml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Building All Sanitizer Configurations${NC}"
echo -e "${GREEN}======================================${NC}"
echo "Host: W5-2465X (32-core)"
echo "Build Jobs: -j32"
echo "LLMCJF Mode: strict-engineering"
echo "Note: Memory sanitizer requires libc++ - only available in CI/CD containers"
echo ""

SANITIZERS=("address" "undefined")
FAILED=()

for sanitizer in "${SANITIZERS[@]}"; do
  echo -e "${YELLOW}[*]${NC} Building $sanitizer sanitizer..."
  
  if ./build-fuzzers-local.sh "$sanitizer"; then
    echo -e "${GREEN}[✓]${NC} $sanitizer sanitizer built successfully"
  else
    echo -e "${RED}[!]${NC} $sanitizer sanitizer build failed"
    FAILED+=("$sanitizer")
  fi
  echo ""
done

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Build Summary${NC}"
echo -e "${GREEN}======================================${NC}"

if [ ${#FAILED[@]} -eq 0 ]; then
  echo -e "${GREEN}[✓]${NC} All sanitizers built successfully"
  echo ""
  echo "Output directories:"
  for sanitizer in "${SANITIZERS[@]}"; do
    echo "  - fuzzers-local/$sanitizer/"
  done
  echo ""
  echo "Next steps:"
  echo "  ./fuzzing-control.sh list         # List built fuzzers"
  echo "  ./fuzzing-control.sh run          # Run fuzzing"
  echo "  ./fuzzing-control.sh reproduce    # Reproduce crashes"
  exit 0
else
  echo -e "${RED}[!]${NC} Failed sanitizers: ${FAILED[*]}"
  echo ""
  echo "Troubleshooting:"
  echo "  - Check build logs above for errors"
  echo "  - Verify dependencies: clang, cmake, libxml2"
  echo "  - Check disk space: df -h"
  exit 1
fi
