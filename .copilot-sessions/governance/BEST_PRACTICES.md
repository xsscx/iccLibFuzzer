# Best Practices
## GitHub Copilot CLI Governance

**Version**: 1.0  
**Effective**: 2025-12-24  
**Purpose**: Engineering standards and code quality

---

## Core Engineering Principles

### 1. Minimal Changes Philosophy

**Rule**: Make the smallest possible change to achieve the goal.

**Good Example**:
```diff
# Fix single path reference
- cd $SRC/ipatch/fuzzers
+ cd $SRC/iccLibFuzzer/fuzzers
```

**Bad Example**:
```diff
# Unnecessary rewrite of working code
- cd $SRC/ipatch/fuzzers
- make clean
- rm -f old_fuzzer
+ pushd $SRC/iccLibFuzzer/fuzzers >/dev/null
+ find . -name "*.o" -delete
+ rm -rf $(ls | grep -v keep)
+ popd >/dev/null
```

**Why**: Minimal changes reduce regression risk, are easier to review, and maintain code history.

---

### 2. Surgical Modifications

**Pattern**: Target specific lines, preserve context.

**Implementation**:
```bash
# Use edit tool for precise changes
old_str: "exact match with context"
new_str: "minimal modification"

# NOT full file replacements
```

**Metrics**:
- ✅ Good: 1-5 lines changed per fix
- ⚠️  Caution: 6-20 lines changed
- ❌ Review: 20+ lines changed

---

## Code Modification Patterns

### Pattern 1: Bug Fix

**Process**:
1. Identify exact location of bug
2. Understand root cause
3. Make minimal fix
4. Verify fix doesn't break other code
5. Add test if applicable

**Example**:
```cpp
// Bug: Integer overflow
// Bad fix: Rewrite entire function
// Good fix: Add bounds check

// Before
int result = steps * steps;

// After
if (steps > 1000) return false;  // Add bounds check
int result = steps * steps;
```

**Commit Message**:
```
Fix: Integer overflow in spectral range calculation

Issue: steps * steps can overflow for large values
Root cause: No bounds checking on user input
Solution: Add max limit of 1000 steps
Impact: Prevents UBSan errors on malformed profiles
```

### Pattern 2: Path Update

**Process**:
1. Identify all occurrences (grep)
2. Verify context for each
3. Update systematically
4. Verify no references remain

**Example**:
```bash
# Find all references
grep -r "old_path" .

# Update each file
edit file1: old_path → new_path
edit file2: old_path → new_path

# Verify none remain
grep -r "old_path" .  # Should be empty
```

### Pattern 3: Configuration Change

**Process**:
1. Understand current behavior
2. Identify exact parameter to change
3. Document old and new values
4. Justify the change

**Example**:
```yaml
# .clusterfuzzlite/build.sh
# Change: Increase memory limit for complex profiles

# Before
rss_limit_mb = 6144  # 6GB

# After
rss_limit_mb = 8192  # 8GB

# Rationale: Complex spectral profiles OOM at 6GB
# Testing: Validated with 15MB test profiles
```

---

## Testing Requirements

### Before Commit

**Mandatory Checks**:
1. ✅ Code compiles without errors
2. ✅ Existing tests pass
3. ✅ No new compiler warnings
4. ✅ Changes don't break existing functionality

**Commands**:
```bash
# Build check
cd Build && cmake Cmake && make -j32

# Warning check
make 2>&1 | grep -i warning

# Regression check
cd Testing && ./RunTests.sh
```

### For Fuzzing Changes

**Mandatory**:
1. ✅ Fuzzer builds successfully
2. ✅ Fuzzer runs without immediate crash
3. ✅ Corpus loads correctly
4. ✅ Sanitizers functional

**Commands**:
```bash
# Build fuzzers
.clusterfuzzlite/build.sh

# Quick test
./out/icc_profile_fuzzer corpus/ -max_total_time=10

# Verify sanitizer
ASAN_OPTIONS=detect_leaks=1 ./out/icc_profile_fuzzer ...
```

---

## Documentation Standards

### Commit Messages

**Format**:
```
<Type>: <Short summary (50 chars max)>

<Detailed description>
- What was changed
- Why it was changed
- How it was tested
- Impact/implications

<Optional references>
Fixes: #issue_number
Related: GH Actions run #12345
```

**Types**:
- `Fix:` - Bug fix
- `Feature:` - New functionality
- `Refactor:` - Code restructuring (no behavior change)
- `Docs:` - Documentation only
- `Test:` - Test additions or fixes
- `Build:` - Build system changes
- `CI:` - CI/CD changes
- `Perf:` - Performance improvement

**Example**:
```
Fix: ipatch references in .clusterfuzzlite/build.sh

Critical fix for CFL build failure in run 20490062142.

Changes:
- $SRC/ipatch → $SRC/iccLibFuzzer (20 occurrences)
- All fuzzer build paths updated
- All corpus paths updated

Testing:
- Repository-wide grep confirms no ipatch refs remain
- Ready for next CFL run

Impact: Resolves CFL build failures, enables fuzzing runs
Related: GH Actions run #20490062142
```

### Code Comments

**When to Comment**:
- Complex algorithms requiring explanation
- Non-obvious workarounds
- Security-critical sections
- Performance optimizations

**When NOT to Comment**:
- Obvious code (e.g., `i++; // increment i`)
- Restating what code does
- Outdated or incorrect information

**Example - Good**:
```cpp
// Spectral range calculation can overflow for large step values
// Limit to 1000 steps to prevent UBSan errors while maintaining
// support for all valid ICC spectral ranges (380-780nm typical)
if (steps > 1000) return false;
```

**Example - Bad**:
```cpp
// Check if steps is greater than 1000
if (steps > 1000) return false;  // Returns false
```

### Session Documentation

**Required Elements**:
1. ✅ Snapshot before major changes
2. ✅ Decision rationale documented
3. ✅ Session summary at end
4. ✅ Next-session guide updated

**Template**: See `SESSION_TEMPLATE.md`

---

## Git Workflow

### Branching (Current: Direct to Master)

**Current Practice**:
- Direct commits to master for bug fixes
- Immediate push after verification
- Session tracking provides audit trail

**Future Enhancement** (optional):
```bash
# Feature branches for major work
git checkout -b fix/issue-description
# Make changes
git commit -m "Fix: Description"
# Push and create PR
git push origin fix/issue-description
```

### Commit Hygiene

**Requirements**:
```bash
# 1. Stage only related changes
git add file1.cpp file2.h  # Not 'git add .'

# 2. Review before commit
git diff --cached

# 3. Clear, detailed message
git commit  # Opens editor for full message

# 4. Verify commit
git show HEAD
```

**Anti-Patterns**:
```bash
❌ git add .  # Stages unrelated files
❌ git commit -m "fix"  # Vague message
❌ git commit -am "wip"  # Skip review
❌ git push --force  # Loses history
```

---

## Build System Practices

### CMake Best Practices

**Configuration**:
```cmake
# Explicit compiler settings
set(CMAKE_C_COMPILER ${CC})
set(CMAKE_CXX_COMPILER ${CXX})

# Optimization flags
set(CMAKE_CXX_FLAGS "${CXXFLAGS} -frtti")
set(CMAKE_BUILD_TYPE RelWithDebInfo)

# Static linking for fuzzers
set(BUILD_SHARED_LIBS OFF)
```

**Parallel Builds**:
```bash
# Use all available cores (W5-2465X optimized)
cmake --build . -j32

# Or with make
make -j$(nproc)
```

### Build Script Patterns

**Requirements**:
1. ✅ Idempotent (can run multiple times safely)
2. ✅ Error handling (set -e, check returns)
3. ✅ Clean previous builds
4. ✅ Verify outputs exist

**Example**:
```bash
#!/bin/bash -eu  # Exit on error, undefined vars

# Clean previous build
rm -rf build/ || true
mkdir -p build/

# Build with error checking
cd build
cmake .. || { echo "CMake failed"; exit 1; }
make -j32 || { echo "Build failed"; exit 1; }

# Verify outputs
test -f libIccProfLib2-static.a || { echo "Library missing"; exit 1; }
echo "Build successful"
```

---

## Performance Optimization

### Profiling Before Optimizing

**Process**:
1. Measure current performance
2. Identify bottleneck
3. Implement optimization
4. Measure improvement
5. Document results

**Tools**:
```bash
# CPU profiling
perf record -g ./fuzzer corpus/
perf report

# Memory profiling
valgrind --tool=massif ./fuzzer

# Fuzzing throughput
./fuzzer corpus/ -max_total_time=60 -print_final_stats=1
```

### Optimization Patterns

**Pattern 1: Parallel Builds**
```bash
# Before: Sequential
make target1 && make target2 && make target3

# After: Parallel
make -j32 target1 target2 target3
```

**Pattern 2: Corpus Caching**
```yaml
# GitHub Actions cache
- name: Cache Corpus
  uses: actions/cache@v4
  with:
    path: corpus/
    key: corpus-${{ hashFiles('fuzzers/*.cpp') }}
```

**Pattern 3: Resource Limits**
```bash
# Prevent OOM, allow complex inputs
max_len = 15728640  # 15MB
rss_limit_mb = 8192  # 8GB
timeout = 45  # 45s per input
```

---

## Code Review Guidelines

### Self-Review Checklist

Before requesting review or committing:
- [ ] Code compiles without warnings
- [ ] Changes are minimal and focused
- [ ] Existing tests pass
- [ ] New code has appropriate comments
- [ ] Commit message is clear and complete
- [ ] No debug code or commented-out code
- [ ] No hardcoded values (use constants)
- [ ] Error handling present
- [ ] Security review passed

### Peer Review Focus

**Reviewer Should Check**:
1. Security implications
2. Performance impact
3. Edge cases handled
4. Code clarity
5. Test coverage

**Review Comments**:
```
✅ Approved: Change is minimal and well-justified
⚠️  Suggestion: Consider edge case where size=0
❌ Request changes: Hardcoded path needs to be configurable
```

---

## Continuous Improvement

### Learning from Failures

**Process**:
1. Document failure in ANTI_PATTERNS.md
2. Identify root cause
3. Create mitigation strategy
4. Update governance if needed

**Example**:
```markdown
## CJF-09: Incomplete Path Migration

Symptom: Build failures after repository rename
Root Cause: Grep missed files in nested directories
Mitigation: Use `git grep -r` instead of `grep -r`
Prevention: Add pre-commit check for old paths
```

### Metrics Tracking

**Session Metrics**:
- Time to resolution
- Lines changed per fix
- Number of commits
- Test pass rate
- CI/CD success rate

**Quality Metrics**:
- Regression rate (target: 0%)
- Security violations (must be 0)
- Code review approval time
- Bug fix effectiveness

---

## References

### Internal Standards
- `.github/copilot-instructions.md` - Project conventions
- `llmcjf/profiles/` - Behavioral patterns
- Project README.md - Build and test instructions

### External Standards
- [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)
- [CMake Best Practices](https://cmake.org/cmake/help/latest/guide/tutorial/)
- [Git Best Practices](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project)

---

**Status**: ✅ Active  
**Last Review**: 2025-12-24  
**Next Review**: 2025-12-31  
**Compliance**: Mandatory for all Copilot CLI sessions
