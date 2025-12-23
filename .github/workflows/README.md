# GitHub Actions Workflows - Developer Guide

## PR Fuzzing Test Workflow Pattern

### Overview
The `test-pr329.yml` workflow demonstrates the standard pattern for adding fuzzing tests to pull requests targeting security fixes.

### Pattern: PR-Triggered Fuzzing with AddressSanitizer

**File:** `.github/workflows/test-pr329.yml`

**Use Case:** Validate security patches against known crash inputs and run continuous fuzzing.

**Key Components:**

#### 1. Trigger Configuration
```yaml
on:
  pull_request:
    branches:
      - issue-328
  workflow_dispatch:
    inputs:
      duration:
        description: 'Fuzzing duration in seconds'
        required: false
        default: '300'
```

#### 2. Shell Prologue (Required Standard)
All steps MUST use this shell configuration:

```yaml
shell: bash --noprofile --norc {0}
env:
  BASH_ENV: /dev/null
run: |
  set -euo pipefail
  git config --global --add safe.directory "$GITHUB_WORKSPACE"
  git config --global credential.helper ""
  unset GITHUB_TOKEN || true
```

**Reference:** `llmcjf/actions/hoyt-bash-shell-prologue-actions.md`

#### 3. Matrix Strategy
```yaml
strategy:
  fail-fast: false
  matrix:
    sanitizer: [address]
```

**Extend with:** `sanitizer: [address, undefined, memory]`

#### 4. Build Fuzzers
```yaml
- name: Build Fuzzers
  shell: bash --noprofile --norc {0}
  env:
    BASH_ENV: /dev/null
  run: |
    set -euo pipefail
    ./build-fuzzers-local.sh ${{ matrix.sanitizer }}
```

#### 5. Test Known Crash (Regression Test)
```yaml
- name: Test Known Crash
  shell: bash --noprofile --norc {0}
  env:
    BASH_ENV: /dev/null
  run: |
    set -euo pipefail
    CRASH_FILE="Testing/crashes/crash-3c3c6c65ab8b4ba09d67bcb0edfdc2345e8285dd"
    if [ -f "$CRASH_FILE" ]; then
      echo "Testing known crash: $CRASH_FILE"
      ./fuzzers-local/${{ matrix.sanitizer }}/icc_profile_fuzzer "$CRASH_FILE" 2>&1 | head -20 || exit 1
      echo "✅ Known crash handled without error"
    else
      echo "⚠️  Known crash file not found"
    fi
```

#### 6. Run Fuzzing Test
```yaml
- name: Run Fuzzing Test
  shell: bash --noprofile --norc {0}
  env:
    BASH_ENV: /dev/null
  run: |
    set -euo pipefail
    DURATION="${{ github.event.inputs.duration || '300' }}"
    ./run-local-fuzzer.sh ${{ matrix.sanitizer }} icc_profile_fuzzer "$DURATION"
```

---

## Adding Fuzzing to Your PR

### Step 1: Create Workflow File
Copy `.github/workflows/test-pr329.yml` to `.github/workflows/test-pr<NUMBER>.yml`

### Step 2: Update Trigger Branch
```yaml
on:
  pull_request:
    branches:
      - issue-<YOUR_ISSUE_NUMBER>
```

### Step 3: Add Crash Files
Place known crash inputs in `Testing/crashes/crash-<HASH>`

### Step 4: Update Crash Path
```yaml
CRASH_FILE="Testing/crashes/crash-<YOUR_HASH>"
```

### Step 5: Select Sanitizers
```yaml
matrix:
  sanitizer: [address, undefined]
```

### Step 6: Commit and Push
```bash
git add .github/workflows/test-pr<NUMBER>.yml
git add Testing/crashes/crash-<HASH>
git commit -m "Add fuzzing workflow for PR #<NUMBER>"
git push
```

---

## Shell Prologue Standard (MANDATORY)

**All workflow steps MUST use:**

```yaml
shell: bash --noprofile --norc {0}
env:
  BASH_ENV: /dev/null
run: |
  set -euo pipefail
  git config --global --add safe.directory "$GITHUB_WORKSPACE"
  git config --global credential.helper ""
  unset GITHUB_TOKEN || true
```

**Why:**
- `--noprofile --norc`: Prevents profile interference
- `BASH_ENV: /dev/null`: Disables environment file
- `set -euo pipefail`: Fail-fast error handling
- `safe.directory`: Git security configuration
- `unset GITHUB_TOKEN`: Security isolation

**Reference:** `llmcjf/actions/hoyt-bash-shell-prologue-actions.md`

---

## Permissions

```yaml
permissions:
  contents: read
```

**Principle:** Minimal permissions required.

---

## Artifact Upload

```yaml
- name: Upload Crashes
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: crashes-${{ matrix.sanitizer }}
    path: fuzzers-local/${{ matrix.sanitizer }}/crashes/
    if-no-files-found: ignore
```

---

## Example: Adding to PR #350

**File:** `.github/workflows/test-pr350.yml`

```yaml
name: Test PR 350 Fix

on:
  pull_request:
    branches:
      - issue-349
  workflow_dispatch:
    inputs:
      duration:
        description: 'Fuzzing duration in seconds'
        required: false
        default: '300'

permissions:
  contents: read

jobs:
  test-fix:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        sanitizer: [address, undefined]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
        with:
          fetch-depth: 1
      
      - name: Configure Git Environment
        shell: bash --noprofile --norc {0}
        env:
          BASH_ENV: /dev/null
        run: |
          set -euo pipefail
          git config --global --add safe.directory "$GITHUB_WORKSPACE"
          git config --global credential.helper ""
          unset GITHUB_TOKEN || true
      
      - name: Install Dependencies
        shell: bash --noprofile --norc {0}
        env:
          BASH_ENV: /dev/null
        run: |
          set -euo pipefail
          sudo apt-get update -qq
          sudo apt-get install -y clang cmake build-essential nlohmann-json3-dev libtiff-dev libpng-dev libjpeg-turbo8-dev libxml2-dev
      
      - name: Build Fuzzers
        shell: bash --noprofile --norc {0}
        env:
          BASH_ENV: /dev/null
        run: |
          set -euo pipefail
          ./build-fuzzers-local.sh ${{ matrix.sanitizer }}
      
      - name: Test Known Crash
        shell: bash --noprofile --norc {0}
        env:
          BASH_ENV: /dev/null
        run: |
          set -euo pipefail
          CRASH_FILE="Testing/crashes/crash-<YOUR_HASH>"
          if [ -f "$CRASH_FILE" ]; then
            echo "Testing known crash: $CRASH_FILE"
            ./fuzzers-local/${{ matrix.sanitizer }}/icc_profile_fuzzer "$CRASH_FILE" 2>&1 | head -20 || exit 1
            echo "✅ Known crash handled without error"
          else
            echo "⚠️  Known crash file not found"
          fi
      
      - name: Run Fuzzing Test
        shell: bash --noprofile --norc {0}
        env:
          BASH_ENV: /dev/null
        run: |
          set -euo pipefail
          DURATION="${{ github.event.inputs.duration || '300' }}"
          ./run-local-fuzzer.sh ${{ matrix.sanitizer }} icc_profile_fuzzer "$DURATION"
      
      - name: Upload Crashes
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: crashes-${{ matrix.sanitizer }}
          path: fuzzers-local/${{ matrix.sanitizer }}/crashes/
          if-no-files-found: ignore
```

---

## Checklist

- [ ] Copy workflow template
- [ ] Update PR/issue number in filename
- [ ] Update trigger branch
- [ ] Add crash file to `Testing/crashes/`
- [ ] Update `CRASH_FILE` path
- [ ] Apply shell prologue to ALL steps
- [ ] Select appropriate sanitizers
- [ ] Commit and push
- [ ] Verify workflow runs on PR

---

**Last Updated:** 2025-12-20  
**Template Source:** `.github/workflows/test-pr329.yml`  
**References:**
- Shell Prologue Standard: `llmcjf/actions/hoyt-bash-shell-prologue-actions.md`
- Security Documentation: `docs/SECURITY_PATCH_SUMMARY.md`
