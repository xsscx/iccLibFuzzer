#!/bin/bash
# load-sanitizer.sh - Load trusted sanitizer with fail-secure
# Usage: source .github/scripts/load-sanitizer.sh

TRUSTED_SANITIZER="${TRUSTED_SANITIZER:-$GITHUB_WORKSPACE/base/.github/scripts/sanitize-sed.sh}"
if [[ -f "$TRUSTED_SANITIZER" ]]; then
  # shellcheck disable=SC1090
  source "$TRUSTED_SANITIZER"
else
  echo "ERROR: Trusted sanitizer not found at $TRUSTED_SANITIZER" >&2
  echo "Security control failure - aborting job" >&2
  exit 1
fi
