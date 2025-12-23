#!/bin/bash
set -euo pipefail

# Populate all fuzzer seed corpora
# Reference: .llmcjf-config.yaml

SCRIPT_DIR="$(pwd)"
ICC_FILES="$SCRIPT_DIR/Testing"
POC_ARCHIVE="$SCRIPT_DIR/poc-archive"

echo "Populating fuzzer seed corpora..."
echo "ICC source: $ICC_FILES"
echo "POC source: $POC_ARCHIVE"
echo ""

for sanitizer in address undefined memory; do
  FUZZER_DIR="$SCRIPT_DIR/fuzzers-local/$sanitizer"
  
  if [ ! -d "$FUZZER_DIR" ]; then
    echo "Skipping $sanitizer (not built)"
    continue
  fi
  
  echo "Processing $sanitizer sanitizer..."
  
  # ICC profile fuzzers - use .icc files
  for fuzzer in icc_profile_fuzzer icc_io_fuzzer icc_calculator_fuzzer icc_spectral_fuzzer icc_multitag_fuzzer icc_apply_fuzzer icc_applyprofiles_fuzzer icc_roundtrip_fuzzer icc_link_fuzzer icc_dump_fuzzer; do
    CORPUS_DIR="$FUZZER_DIR/${fuzzer}_seed_corpus"
    if [ -d "$CORPUS_DIR" ]; then
      echo "  Populating $fuzzer..."
      find "$ICC_FILES" -name "*.icc" -exec cp {} "$CORPUS_DIR/" \; 2>/dev/null || true
      # Add POC crashes
      find "$POC_ARCHIVE" -name "*.icc" -exec cp {} "$CORPUS_DIR/" \; 2>/dev/null || true
      find "$POC_ARCHIVE" -type f -name "crash-*" ! -name "*.xml" -exec cp {} "$CORPUS_DIR/" \; 2>/dev/null || true
      COUNT=$(find "$CORPUS_DIR" -type f | wc -l)
      echo "    → $COUNT files"
    fi
  done
  
  # XML fuzzers - use .xml files
  CORPUS_DIR="$FUZZER_DIR/icc_fromxml_fuzzer_seed_corpus"
  if [ -d "$CORPUS_DIR" ]; then
    echo "  Populating icc_fromxml_fuzzer..."
    find "$ICC_FILES" -name "*.xml" -exec cp {} "$CORPUS_DIR/" \; 2>/dev/null || true
    find "$POC_ARCHIVE" -name "*.xml" -exec cp {} "$CORPUS_DIR/" \; 2>/dev/null || true
    find "$POC_ARCHIVE" -type f -name "crash-*" -name "*.xml" -exec cp {} "$CORPUS_DIR/" \; 2>/dev/null || true
    COUNT=$(find "$CORPUS_DIR" -type f | wc -l)
    echo "    → $COUNT files"
  fi
  
  CORPUS_DIR="$FUZZER_DIR/icc_toxml_fuzzer_seed_corpus"
  if [ -d "$CORPUS_DIR" ]; then
    echo "  Populating icc_toxml_fuzzer..."
    find "$ICC_FILES" -name "*.icc" -exec cp {} "$CORPUS_DIR/" \; 2>/dev/null || true
    find "$POC_ARCHIVE" -name "*.icc" -exec cp {} "$CORPUS_DIR/" \; 2>/dev/null || true
    COUNT=$(find "$CORPUS_DIR" -type f | wc -l)
    echo "    → $COUNT files"
  fi
  
  echo ""
done

echo "Corpus population complete!"
echo ""
echo "Summary:"
find fuzzers-local/*/icc_*_seed_corpus -type f | wc -l | xargs echo "Total corpus files:"
