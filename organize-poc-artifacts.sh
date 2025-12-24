#!/bin/bash
# Organize crash/leak/oom artifacts from fuzzing runs into poc-archive

set -e

POC_DIR="poc-archive"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
INVENTORY="$POC_DIR/POC_INVENTORY_$TIMESTAMP.md"

echo "=== PoC Artifact Organization ==="
echo "Timestamp: $TIMESTAMP"
echo ""

# Create directory if needed
mkdir -p "$POC_DIR"

# Find all crash/leak/oom files in root (not in poc-archive or corpus)
ARTIFACTS=$(find . -maxdepth 1 -type f \( -name "crash-*" -o -name "leak-*" -o -name "oom-*" \) | sort)

if [ -z "$ARTIFACTS" ]; then
    echo "No artifacts found in root directory"
    exit 0
fi

# Count artifacts
TOTAL=$(echo "$ARTIFACTS" | wc -l)
echo "Found $TOTAL artifacts to archive"
echo ""

# Start inventory
cat > "$INVENTORY" << 'HEADER'
# PoC Artifact Inventory

**Generated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Source**: Root directory fuzzing artifacts
**Purpose**: Document crash/leak/oom findings for reproducibility

## Summary

| Type | Count |
|------|-------|
HEADER

# Count by type
CRASHES=$(echo "$ARTIFACTS" | grep "crash-" | wc -l)
LEAKS=$(echo "$ARTIFACTS" | grep "leak-" | wc -l)
OOMS=$(echo "$ARTIFACTS" | grep "oom-" | wc -l)

echo "| Crashes | $CRASHES |" >> "$INVENTORY"
echo "| Leaks | $LEAKS |" >> "$INVENTORY"
echo "| OOMs | $OOMS |" >> "$INVENTORY"
echo "| **Total** | **$TOTAL** |" >> "$INVENTORY"
echo "" >> "$INVENTORY"

echo "## Artifact Details" >> "$INVENTORY"
echo "" >> "$INVENTORY"

# Process each artifact
for artifact in $ARTIFACTS; do
    BASENAME=$(basename "$artifact")
    TYPE=$(echo "$BASENAME" | cut -d'-' -f1)
    HASH=$(echo "$BASENAME" | cut -d'-' -f2)
    SIZE=$(stat -c%s "$artifact" 2>/dev/null || stat -f%z "$artifact" 2>/dev/null)
    MTIME=$(stat -c%y "$artifact" 2>/dev/null | cut -d'.' -f1 || stat -f"%Sm" -t "%Y-%m-%d %H:%M:%S" "$artifact" 2>/dev/null)
    SHA256=$(sha256sum "$artifact" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$artifact" 2>/dev/null | cut -d' ' -f1)
    
    echo "### $BASENAME" >> "$INVENTORY"
    echo "" >> "$INVENTORY"
    echo "- **Type**: $TYPE" >> "$INVENTORY"
    echo "- **Hash**: $HASH" >> "$INVENTORY"
    echo "- **Size**: $SIZE bytes" >> "$INVENTORY"
    echo "- **Created**: $MTIME" >> "$INVENTORY"
    echo "- **SHA256**: $SHA256" >> "$INVENTORY"
    
    # Try to identify which fuzzer/sanitizer
    if [ -f "$artifact" ] && [ -s "$artifact" ]; then
        echo "- **Sample**: \`$(head -c 100 "$artifact" | od -A n -t x1 | tr -d '\n' | cut -c1-50)\`" >> "$INVENTORY"
    fi
    echo "" >> "$INVENTORY"
    
    # Move to poc-archive
    if [ ! -f "$POC_DIR/$BASENAME" ]; then
        cp "$artifact" "$POC_DIR/"
        echo "  ✓ Archived: $BASENAME"
    else
        echo "  - Exists: $BASENAME (skipped)"
    fi
done

echo ""
echo "Inventory created: $INVENTORY"
echo ""
echo "Summary:"
echo "  Crashes: $CRASHES"
echo "  Leaks:   $LEAKS"
echo "  OOMs:    $OOMS"
echo "  Total:   $TOTAL"
echo ""
echo "All artifacts preserved in $POC_DIR/"
