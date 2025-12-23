#!/bin/bash
# Integrate commodity ICC profiles into fuzzer corpus
set -e

COMMODITY_SRC="Commodity-Injection-Signatures/graphics/icc"
CORPUS_DST="corpus/commodity"

echo "=== Commodity Corpus Integration ==="
echo "Source: $COMMODITY_SRC"
echo "Destination: $CORPUS_DST"

# Create destination if needed
mkdir -p "$CORPUS_DST"

# Copy all ICC profiles
ICC_COUNT=$(find "$COMMODITY_SRC" -name "*.icc" | wc -l)
echo "Found $ICC_COUNT ICC profiles in commodity folder"

cp -v "$COMMODITY_SRC"/*.icc "$CORPUS_DST/" 2>&1 | wc -l
echo "Copied to $CORPUS_DST/"

# List CVE profiles
echo ""
echo "=== Notable CVE Profiles ==="
ls "$CORPUS_DST"/cve-*.icc 2>/dev/null | xargs -n1 basename | head -10

echo ""
echo "=== Total Corpus Status ==="
echo "Commodity profiles: $(ls $CORPUS_DST/*.icc 2>/dev/null | wc -l)"
echo "Total corpus files: $(find corpus -type f 2>/dev/null | wc -l)"

echo ""
echo "✅ Commodity corpus integration complete!"
