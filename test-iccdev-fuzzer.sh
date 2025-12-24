#!/bin/bash -eu

# Build and run fuzzers using Dockerfile.iccdev-fuzzer
# Usage: ./test-iccdev-fuzzer.sh [address|undefined] [fuzzer_name] [duration]

SANITIZER="${1:-address}"
FUZZER="${2:-icc_profile_fuzzer}"
DURATION="${3:-60}"

IMAGE_NAME="iccLibFuzzer-iccdev-fuzzer:latest"

echo "Building Docker image: $IMAGE_NAME"
docker build -f Dockerfile.iccdev-fuzzer -t "$IMAGE_NAME" .

echo ""
echo "Running fuzzer in container..."
docker run --rm \
  -e SANITIZER="$SANITIZER" \
  -e FUZZER="$FUZZER" \
  -e DURATION="$DURATION" \
  -e JOBS="$(nproc)" \
  "$IMAGE_NAME"
