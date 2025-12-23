#!/bin/bash
# Input Sanitization for GitHub Actions Workflow
# Validates and sanitizes workflow_dispatch inputs
# Source: .github/scripts/sanitizer.sh

set -euo pipefail

# Sanitize fuzz-seconds input (must be numeric, 1-86400 range)
sanitize_fuzz_seconds() {
  local input="${1:-3600}"
  
  # Remove any non-numeric characters
  local cleaned=$(echo "$input" | tr -cd '0-9')
  
  # Default to 3600 if empty or invalid
  if [ -z "$cleaned" ]; then
    echo "3600"
    return 0
  fi
  
  # Validate range (1 second to 24 hours)
  local value=$cleaned
  if [ "$value" -lt 1 ]; then
    echo "1"
  elif [ "$value" -gt 86400 ]; then
    echo "86400"
  else
    echo "$value"
  fi
}

# Sanitize boolean inputs
sanitize_boolean() {
  local input="${1:-false}"
  
  case "${input,,}" in
    true|1|yes|y)
      echo "true"
      ;;
    *)
      echo "false"
      ;;
  esac
}

# Sanitize string inputs (alphanumeric + dash/underscore only)
sanitize_string() {
  local input="${1:-}"
  local max_length="${2:-100}"
  
  # Remove everything except alphanumeric, dash, underscore, dot
  local cleaned=$(echo "$input" | tr -cd 'a-zA-Z0-9._-')
  
  # Truncate to max length
  echo "${cleaned:0:$max_length}"
}

# Main sanitization function
sanitize_inputs() {
  # Get inputs with defaults
  local fuzz_seconds="${FUZZ_SECONDS:-3600}"
  local no_cache="${NO_CACHE:-false}"
  
  # Sanitize each input
  SANITIZED_FUZZ_SECONDS=$(sanitize_fuzz_seconds "$fuzz_seconds")
  SANITIZED_NO_CACHE=$(sanitize_boolean "$no_cache")
  
  # Export sanitized values
  export SANITIZED_FUZZ_SECONDS
  export SANITIZED_NO_CACHE
  
  # Log sanitization (for debugging)
  echo "Input Sanitization:"
  echo "  Original fuzz-seconds: '$fuzz_seconds' -> Sanitized: '$SANITIZED_FUZZ_SECONDS'"
  echo "  Original no-cache: '$no_cache' -> Sanitized: '$SANITIZED_NO_CACHE'"
  
  # Set GitHub output if in Actions environment
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "fuzz-seconds=$SANITIZED_FUZZ_SECONDS" >> "$GITHUB_OUTPUT"
    echo "no-cache=$SANITIZED_NO_CACHE" >> "$GITHUB_OUTPUT"
  fi
}

# Allow sourcing or direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  # Direct execution
  sanitize_inputs
else
  # Being sourced - functions available for use
  :
fi
