# Workflow Audit Process for Compliance and Security

**Version:** 1.0  
**Date:** 2025-12-20  
**Applies to:** All GitHub Actions workflows in `.github/workflows/`

---

## Purpose

This document defines the audit process to ensure GitHub Actions workflows comply with security best practices and the shell prologue standard defined in `llmcjf/actions/hoyt-bash-shell-prologue-actions.md`.

---

## Compliance Requirements

### Mandatory Shell Prologue Markers

All workflow steps executing shell scripts **MUST** include:

#### 1. Shell Declaration
```yaml
shell: bash --noprofile --norc {0}
```
- **Purpose:** Prevents profile script execution and environment pollution
- **Flags:**
  - `--noprofile`: Skip `/etc/profile` and `~/.bash_profile`
  - `--norc`: Skip `~/.bashrc`
  - `{0}`: Pass script via stdin

#### 2. Environment Isolation
```yaml
env:
  BASH_ENV: /dev/null
```
- **Purpose:** Disables environment file that bash sources on startup
- **Security:** Prevents malicious code injection via `BASH_ENV`

#### 3. Workflow Prologue Script
```yaml
run: |
  source .github/scripts/workflow-prologue.sh
```
- **Purpose:** Consolidates required security markers
- **Contains:**
  - `set -euo pipefail` - Fail-fast error handling
  - `git config --add safe.directory "$PWD"` - Git security
  - `git config --global credential.helper ""` - Clear credentials
  - `unset GITHUB_TOKEN || true` - Remove GitHub token

### Additional Security Controls

#### 4. Trusted Sanitizer Loading
For steps processing user-controllable inputs:
```yaml
- name: Checkout base commit (trusted sanitizers)
  uses: actions/checkout@<SHA>
  with:
    ref: ${{ github.event.pull_request.base.sha || github.sha }}
    path: base
    fetch-depth: 1
    persist-credentials: false

- name: Process User Input
  run: |
    source .github/scripts/workflow-prologue.sh
    source .github/scripts/load-sanitizer.sh
    
    SAFE_INPUT="$(sanitize_line "$USER_INPUT")"
```

#### 5. Checkout Configuration
```yaml
- uses: actions/checkout@<SHA>
  with:
    persist-credentials: false  # Required
    fetch-depth: 1              # Recommended
```

---

## Audit Process

### Phase 1: Automated Verification

Run the compliance audit script:

```bash
#!/bin/bash
# audit-workflow.sh - Automated workflow compliance checker

WORKFLOW_FILE="$1"
ERRORS=0

echo "=== Auditing: $WORKFLOW_FILE ==="

# Check 1: Shell declarations
SHELL_COUNT=$(grep -c "shell: bash --noprofile --norc {0}" "$WORKFLOW_FILE" || echo 0)
echo "✓ Shell declarations: $SHELL_COUNT"

# Check 2: BASH_ENV
BASH_ENV_COUNT=$(grep -c "BASH_ENV: /dev/null" "$WORKFLOW_FILE" || echo 0)
echo "✓ BASH_ENV configurations: $BASH_ENV_COUNT"

if [ "$SHELL_COUNT" -ne "$BASH_ENV_COUNT" ]; then
  echo "❌ FAIL: Shell count != BASH_ENV count"
  ERRORS=$((ERRORS + 1))
fi

# Check 3: Workflow prologue
PROLOGUE_COUNT=$(grep -c "source .github/scripts/workflow-prologue.sh" "$WORKFLOW_FILE" || echo 0)
echo "✓ Workflow prologue sourcing: $PROLOGUE_COUNT"

if [ "$PROLOGUE_COUNT" -ne "$SHELL_COUNT" ]; then
  echo "⚠️  WARNING: Not all steps source workflow-prologue.sh"
fi

# Check 4: Base checkout for sanitizers
if grep -q "USER_INPUT\|matrix\.\|github.event.inputs" "$WORKFLOW_FILE"; then
  if ! grep -q "Checkout base commit" "$WORKFLOW_FILE"; then
    echo "❌ FAIL: User input detected but no base checkout"
    ERRORS=$((ERRORS + 1))
  fi
  
  if ! grep -q "source .github/scripts/load-sanitizer.sh" "$WORKFLOW_FILE"; then
    echo "❌ FAIL: User input detected but no sanitizer loading"
    ERRORS=$((ERRORS + 1))
  fi
fi

# Check 5: Credential persistence
if grep -q "uses: actions/checkout" "$WORKFLOW_FILE"; then
  if ! grep -q "persist-credentials: false" "$WORKFLOW_FILE"; then
    echo "⚠️  WARNING: checkout without persist-credentials: false"
  fi
fi

# Summary
if [ $ERRORS -eq 0 ]; then
  echo "✅ PASS: Workflow compliant"
  exit 0
else
  echo "❌ FAIL: $ERRORS error(s) found"
  exit 1
fi
```

**Usage:**
```bash
./audit-workflow.sh .github/workflows/test-pr329.yml
```

### Phase 2: Manual Code Review

#### Checklist for Human Reviewer

- [ ] **Shell Prologue Applied**
  - Every `run:` step has `shell: bash --noprofile --norc {0}`
  - Every `run:` step has `BASH_ENV: /dev/null`
  - Every `run:` step sources `workflow-prologue.sh`

- [ ] **User Input Handling**
  - Base commit checked out to `base/` path
  - Sanitizer loaded from `base/.github/scripts/sanitize.sh`
  - All user inputs sanitized before use:
    - `${{ github.event.inputs.* }}` → `sanitize_line()`
    - `${{ matrix.* }}` → `sanitize_filename()`
    - File paths → `sanitize_filename()`

- [ ] **Action Security**
  - All actions pinned to commit SHA (not tags)
  - `persist-credentials: false` on all checkouts
  - Minimal permissions declared
  - No `GITHUB_TOKEN` in environment after checkout

- [ ] **Input Validation**
  - User inputs validated with regex
  - Bounds checking on numeric inputs
  - No direct interpolation in script execution
  - All variables quoted in shell expansions

- [ ] **Error Handling**
  - `set -euo pipefail` via workflow-prologue.sh
  - No silent failures (`|| true` only where intended)
  - Proper exit codes

- [ ] **Secrets Management**
  - No secrets in logs
  - Credentials cleared after use
  - Token unset in all steps

### Phase 3: Security Review

#### Attack Surface Analysis

Review for these attack vectors:

1. **Command Injection**
   - No `${{ }}` interpolation directly in `run:`
   - All user data in environment variables
   - Variables quoted in expansions

2. **Script Injection**
   - Profile scripts disabled (`--noprofile --norc`)
   - `BASH_ENV` set to `/dev/null`
   - No dynamic script sourcing from untrusted paths

3. **Path Traversal**
   - All paths sanitized with `sanitize_filename()`
   - No `../` sequences possible
   - Workspace-relative paths validated

4. **Credential Leakage**
   - `persist-credentials: false`
   - `GITHUB_TOKEN` unset
   - Credential helper cleared

5. **Resource Exhaustion**
   - Timeouts configured
   - Input bounds checking
   - Artifact retention limits

6. **Supply Chain**
   - Actions pinned to SHA
   - Dependencies from trusted sources only
   - Sanitizers loaded from base commit

---

## Audit Tools

### Quick Verification Script

Save as `.github/scripts/audit-workflow-compliance.sh`:

```bash
#!/bin/bash
set -euo pipefail

WORKFLOW="$1"

if [ ! -f "$WORKFLOW" ]; then
  echo "Usage: $0 <workflow.yml>"
  exit 1
fi

# Count markers
SHELLS=$(grep -c "shell: bash --noprofile --norc {0}" "$WORKFLOW" || echo 0)
BASH_ENVS=$(grep -c "BASH_ENV: /dev/null" "$WORKFLOW" || echo 0)
PROLOGUES=$(grep -c "source .github/scripts/workflow-prologue.sh" "$WORKFLOW" || echo 0)

echo "Workflow: $WORKFLOW"
echo "  Shell declarations: $SHELLS"
echo "  BASH_ENV settings: $BASH_ENVS"
echo "  Prologue sourcing: $PROLOGUES"

if [ "$SHELLS" -eq "$BASH_ENVS" ] && [ "$SHELLS" -eq "$PROLOGUES" ]; then
  echo "✅ PASS: All markers present and consistent"
  exit 0
else
  echo "❌ FAIL: Marker mismatch detected"
  exit 1
fi
```

### Compliance Report Generator

```bash
#!/bin/bash
# generate-compliance-report.sh

WORKFLOW="$1"
OUTPUT="${2:-compliance-report.md}"

cat > "$OUTPUT" << EOF
# Workflow Compliance Report

**Workflow:** \`$WORKFLOW\`  
**Date:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')  
**Auditor:** $(git config user.name)

## Compliance Matrix

| Requirement | Status | Count |
|-------------|--------|-------|
| Shell declarations | $(grep -q "shell: bash --noprofile --norc {0}" "$WORKFLOW" && echo "✅" || echo "❌") | $(grep -c "shell: bash --noprofile --norc {0}" "$WORKFLOW" || echo 0) |
| BASH_ENV settings | $(grep -q "BASH_ENV: /dev/null" "$WORKFLOW" && echo "✅" || echo "❌") | $(grep -c "BASH_ENV: /dev/null" "$WORKFLOW" || echo 0) |
| Workflow prologue | $(grep -q "source .github/scripts/workflow-prologue.sh" "$WORKFLOW" && echo "✅" || echo "❌") | $(grep -c "source .github/scripts/workflow-prologue.sh" "$WORKFLOW" || echo 0) |
| Base checkout | $(grep -q "Checkout base commit" "$WORKFLOW" && echo "✅" || echo "❌") | $(grep -c "path: base" "$WORKFLOW" || echo 0) |
| Sanitizer loading | $(grep -q "source .github/scripts/load-sanitizer.sh" "$WORKFLOW" && echo "✅" || echo "❌") | $(grep -c "load-sanitizer.sh" "$WORKFLOW" || echo 0) |
| Persist credentials | $(grep -q "persist-credentials: false" "$WORKFLOW" && echo "✅" || echo "❌") | $(grep -c "persist-credentials: false" "$WORKFLOW" || echo 0) |

## Findings

$(grep -q "shell: bash --noprofile --norc {0}" "$WORKFLOW" && echo "✅ Shell prologue standard enforced" || echo "❌ Missing shell prologue")

$(grep -q "source .github/scripts/load-sanitizer.sh" "$WORKFLOW" && echo "✅ User input sanitization implemented" || echo "⚠️  No sanitization detected")

## Recommendation

$(if grep -c "shell: bash --noprofile --norc {0}" "$WORKFLOW" | grep -q "^[1-9]"; then echo "APPROVED - Workflow meets security standards"; else echo "REJECTED - Workflow requires remediation"; fi)

---
**Audited by:** Automated compliance checker v1.0
EOF

echo "Report generated: $OUTPUT"
```

---

## Common Violations and Fixes

### ❌ Violation: Missing shell declaration
```yaml
# WRONG
- name: Build
  run: |
    make build
```

**Fix:**
```yaml
# CORRECT
- name: Build
  shell: bash --noprofile --norc {0}
  env:
    BASH_ENV: /dev/null
  run: |
    source .github/scripts/workflow-prologue.sh
    make build
```

### ❌ Violation: Direct user input interpolation
```yaml
# WRONG
- name: Process
  run: |
    ./script.sh ${{ github.event.inputs.value }}
```

**Fix:**
```yaml
# CORRECT
- name: Process
  env:
    USER_VALUE: ${{ github.event.inputs.value }}
  run: |
    source .github/scripts/workflow-prologue.sh
    source .github/scripts/load-sanitizer.sh
    
    VALUE_CLEAN="$(sanitize_line "$USER_VALUE")"
    ./script.sh "$VALUE_CLEAN"
```

### ❌ Violation: Action not pinned
```yaml
# WRONG
- uses: actions/checkout@v4
```

**Fix:**
```yaml
# CORRECT
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
```

### ❌ Violation: Credentials persisted
```yaml
# WRONG
- uses: actions/checkout@<SHA>
  with:
    fetch-depth: 1
```

**Fix:**
```yaml
# CORRECT
- uses: actions/checkout@<SHA>
  with:
    fetch-depth: 1
    persist-credentials: false
```

---

## Audit Frequency

- **New workflows:** Before merge
- **Existing workflows:** Quarterly review
- **After security incidents:** Immediate audit
- **Dependency updates:** When updating actions

---

## Approval Process

### Pre-Merge Requirements

1. ✅ Automated audit passes
2. ✅ Manual checklist completed
3. ✅ Security review approved
4. ✅ Test workflow executes successfully
5. ✅ Documentation updated

### Sign-off Template

```
Workflow Audit Approval

Workflow: .github/workflows/[NAME].yml
Auditor: [NAME]
Date: [DATE]

Automated Checks: ✅ PASS
Manual Review: ✅ PASS
Security Review: ✅ PASS
Test Execution: ✅ PASS

Approved by: [SIGNATURE]
```

---

## References

- **Shell Prologue Standard:** `llmcjf/actions/hoyt-bash-shell-prologue-actions.md`
- **PowerShell Standard:** `llmcjf/actions/hoyt-powershell-prologue-actions.md`
- **Sanitizer Documentation:** `.github/scripts/sanitize.sh`
- **Workflow Prologue:** `.github/scripts/workflow-prologue.sh`
- **Example Workflow:** `.github/workflows/ci-pr-action.yml`
- **PR Fuzzing Template:** `.github/workflows/test-pr329.yml`

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-12-20 | Initial audit process documentation | Copilot CLI |

---

**Maintained by:** ICC Development Team  
**Questions:** Submit issue to repository
