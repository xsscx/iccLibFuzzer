#!/bin/bash
# workflow-prologue.sh - Common workflow initialization
# Usage: source .github/scripts/workflow-prologue.sh

set -euo pipefail
git config --add safe.directory "$PWD"
git config --global credential.helper ""
unset GITHUB_TOKEN 2>/dev/null || true
