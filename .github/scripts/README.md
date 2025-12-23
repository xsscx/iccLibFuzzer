# Action Sanitizers

Last Updated: 17-DEC-2025 1800Z by David Hoyt

Use of AI: Significant. Formating, minimizing content.

This directory contains tools for testing and validating sanitization defenses against user controllable inputs.

## Quick Start

```bash
# Run comprehensive sanitization tests
bash .github/scripts/test_sanitization.sh

# Run interactive attack simulation demo
bash .github/scripts/demo_hostile_pr.sh

# Test via GitHub Actions (manual dispatch)
# Go to: Actions → test-hostile-pr → Run workflow
```

## Files

### Sanitization Core
- **`sanitize.sh`** - Core sanitization functions (loaded from trusted base commit)
  - `sanitize_line()` - Single-line sanitization with HTML escaping
  - `sanitize_print()` - Multi-line sanitization for summaries
  - `sanitize_ref()` - Branch/tag name sanitization
  - `sanitize_filename()` - File path sanitization
  
### Testing Tools
- **`test_sanitization.sh`** - Comprehensive automated test suite
  - 50+ test cases covering XSS, injection, Unicode, control chars
  - Exit code 0 = all tests pass, 1 = failures detected
  
- **`demo_hostile_pr.sh`** - Interactive demonstration
  - Simulates real-world attack scenarios
  - Shows before/after sanitization
  - Demonstrates complete hostile PR workflow
  
### Workflow Tests
- **`../.github/workflows/test-hostile-pr.yml`** - GitHub Actions test workflow
  - Manual dispatch with selectable attack types
  - Tests both Unix and PR Action workflows
  - Validates sanitization in real workflow context

## Usage Examples

### Testing Locally

```bash
# 1. Run all sanitization tests
cd .github/scripts
bash test_sanitization.sh
# Should output: ✅ All tests PASSED

# 2. See interactive demo
bash demo_hostile_pr.sh
# Shows attack simulations with color output
```

### Testing in CI

```bash
# Add to your workflow:
- name: Test Sanitization
  run: bash .github/scripts/test_sanitization.sh
```

### Using Sanitizers in Workflows

```yaml
- name: Checkout base (trusted sanitizers)
  uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.base.sha }}
    path: base
    persist-credentials: false

- name: Use Sanitizers
  shell: bash --noprofile --norc {0}
  env:
    BASH_ENV: /dev/null
  run: |
    # Load trusted sanitizer from base commit
    source "$GITHUB_WORKSPACE/base/.github/scripts/sanitize.sh"
    
    # Sanitize user-controlled input
    safe_actor=$(sanitize_line "${{ github.actor }}")
    safe_branch=$(sanitize_ref "${{ github.head_ref }}")
    
    # Safe to use in outputs
    echo "PR by: $safe_actor" >> $GITHUB_STEP_SUMMARY
    echo "Branch: $safe_branch" >> $GITHUB_STEP_SUMMARY
```

## Attack Vectors Tested

| Attack Type | Example | Defense |
|-------------|---------|---------|
| **XSS Script Tag** | `<script>alert(1)</script>` | HTML entity escaping |
| **XSS Event Handler** | `<img onerror=alert(1)>` | HTML entity escaping |
| **Command Injection** | `test; rm -rf /` | No eval, proper quoting |
| **Path Traversal** | `../../../etc/passwd` | Path sanitization |
| **SQL Injection** | `' OR '1'='1` | HTML entity escaping |
| **Template Injection** | `{{7*7}}` | No template evaluation |
| **Control Characters** | `\x00\r\n\033[31m` | Strip control chars |
| **Unicode Homograph** | `Аdmin` (Cyrillic A) | Preserved but escaped |

## Testing Workflow

1. **Pre-commit:** Run `test_sanitization.sh` before committing
2. **PR Creation:** GitHub Actions runs security tests automatically
3. **Manual Testing:** Use `test-hostile-pr` workflow for specific scenarios
4. **Validation:** Review workflow summaries for proper escaping

## Security Checklist

When modifying workflows, ensure:

- [ ] All user input passes through sanitizers
- [ ] Sanitizers loaded from base commit (not PR branch)
- [ ] No direct interpolation: `${{ github.* }}` in run blocks
- [ ] Shell hardening: `bash --noprofile --norc {0}`
- [ ] Environment isolation: `BASH_ENV: /dev/null`
- [ ] Credentials disabled: `persist-credentials: false`
- [ ] Token cleared: `unset GITHUB_TOKEN || true`
- [ ] Matrix inputs validated against allowlists
- [ ] No `eval` or command substitution on user input

## Common Patterns

### ✅ SAFE - Environment Variable + Sanitization
```yaml
env:
  BRANCH_NAME: ${{ github.head_ref }}
run: |
  source base/.github/scripts/sanitize.sh
  safe=$(sanitize_line "$BRANCH_NAME")
  echo "Branch: $safe"
```

### ❌ UNSAFE - Direct Interpolation
```yaml
run: |
  echo "Branch: ${{ github.head_ref }}"  # XSS vulnerable!
```

### ✅ SAFE - Validated Matrix Input
```bash
case "${{ matrix.os }}" in
  ubuntu-latest|macos-latest) ;;
  *) exit 1 ;;  # Reject invalid input
esac
```

### ❌ UNSAFE - Unvalidated Input
```bash
OS="${{ matrix.os }}"  # Could be malicious
cd "$OS"  # Potential path traversal
```

## Troubleshooting

**Tests failing with "sanitize.sh not found":**
```bash
# Ensure you're in the repository root
cd /path/to/patchicc
bash .github/scripts/test_sanitization.sh
```

**Demo shows escape codes:**
```bash
# Some terminals don't support colors
# Output is still correct, just harder to read
```

**Workflow tests skipped:**
```bash
# Check if source files changed
# Workflows skip if no C/C++ files modified
```

## Documentation

- **Comprehensive Guide:** `.github/docs/SECURITY_TESTING.md`
- **Sanitizer Source:** `.github/scripts/sanitize.sh`
- **Test Workflow:** `.github/workflows/test-hostile-pr.yml`

## Support

For security issues:
- **DO NOT** open public issues
- Use: GitHub Security Advisory
- Contact: ICC Maintainers (see CODEOWNERS)

## Version

- **Created:** 2025-12-16
- **Last Updated:** 2025-12-16
- **Maintainer:** ICC Development Team
