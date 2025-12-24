# Anti-Patterns
## GitHub Copilot CLI Governance - Failure Modes to Avoid

**Version**: 1.0  
**Effective**: 2025-12-24  
**Purpose**: Document known failure patterns and mitigations

---

## Overview

This document catalogs known failure patterns from LLMCJF (LLM Content Jockey Failure) research and project-specific experiences. Each pattern includes detection methods and mitigation strategies.

---

## Content Jockey Failures (CJF)

### CJF-01: Hallucinated Implementation

**Description**: AI generates plausible-looking code that doesn't actually solve the problem or introduces new bugs.

**Example**:
```cpp
// User asks: "Fix the memory leak in cleanup()"
// Bad AI response:
void cleanup() {
  // Added smart pointers to fix leak
  std::unique_ptr<Data> ptr(data);  // data is stack variable!
  ptr->process();
}
```

**Detection**:
- Code doesn't compile
- Introduces new errors
- Doesn't address actual issue
- Uses incompatible patterns

**Mitigation**:
1. Always verify code compiles
2. Test before committing
3. Ask user for clarification if problem unclear
4. Stick to minimal, proven changes

---

### CJF-02: Over-Engineering

**Description**: AI replaces simple working code with complex, unnecessary abstractions.

**Example**:
```cpp
// Before (working):
if (size > MAX_SIZE) return false;

// Bad AI "improvement":
template<typename T, typename = std::enable_if_t<std::is_integral_v<T>>>
class SizeValidator {
  static constexpr T threshold = MAX_SIZE;
  public:
    [[nodiscard]] static bool validate(T value) noexcept {
      return value <= threshold;
    }
};
if (!SizeValidator<size_t>::validate(size)) return false;
```

**Detection**:
- Complexity increases without benefit
- Introduces templates/patterns unnecessarily
- Makes code harder to understand
- No performance or functionality gain

**Mitigation**:
1. Follow minimal changes principle
2. Only refactor if explicitly requested
3. Preserve simplicity
4. Avoid showing off language features

---

### CJF-03: Context Loss

**Description**: AI forgets earlier discussion context and contradicts itself or repeats suggestions.

**Example**:
```
User: "We already tried increasing memory limit to 8GB"
AI: "Have you considered increasing the memory limit?"
```

**Detection**:
- Repeats dismissed suggestions
- Contradicts earlier statements
- Ignores user corrections
- Asks for information already provided

**Mitigation**:
1. Reference session snapshots for context
2. Explicitly acknowledge user corrections
3. Don't repeat failed approaches
4. Ask user to verify if uncertain about history

---

### CJF-04: Narrative Padding

**Description**: AI generates unnecessary explanatory text, restating obvious information.

**Example**:
```markdown
❌ Bad:
"I'll now proceed to fix the issue by making a change to the file.
This change will address the problem you mentioned. After making
the change, we'll verify it works. Here's the change..."

✅ Good:
"Fix applied: Updated path reference in build.sh"
```

**Detection**:
- Multiple paragraphs before action
- Restating user's question
- Explaining obvious steps
- Hedging language ("I think", "maybe")

**Mitigation**:
1. Report intent, then act (1 sentence max)
2. Suppress reasoning exposition
3. One purpose per message
4. Action-oriented communication

**From LLMCJF**: `strict-engineering mode active`

---

### CJF-05: Incomplete Change Propagation

**Description**: AI fixes issue in one location but misses identical issues elsewhere.

**Example**:
```bash
# Fix ipatch→iccLibFuzzer in 18 files
# Miss .clusterfuzzlite/build.sh (20 occurrences)
# Result: Build still fails
```

**Detection**:
- Partial fix claims to be complete
- Related files not checked
- Pattern not applied consistently
- Grep would find remaining issues

**Mitigation**:
1. Use grep to find ALL occurrences
2. Systematic replacement across codebase
3. Verify with negative grep (should be empty)
4. Don't assume fix is complete without verification

**Current Session Example**: This exact pattern occurred and was fixed.

---

### CJF-06: Build System Regression

**Description**: AI modifies build configuration in ways that break compilation or introduce warnings.

**Example**:
```cmake
# Before (working):
set(CMAKE_CXX_FLAGS "${CXXFLAGS} -frtti")

# Bad AI change:
set(CMAKE_CXX_FLAGS "-O3 -frtti")  # Loses user CXXFLAGS!
```

**Detection**:
- New compiler warnings
- Build failures on CI
- Missing compiler flags
- Broken sanitizer builds

**Mitigation**:
1. Never remove existing flags without justification
2. Append to flags, don't replace
3. Test build locally before commit
4. Review all build system changes carefully

---

### CJF-07: No-op Echo Response

**Description**: AI re-emits user input verbatim without processing.

**From LLMCJF**:
> "The LLM re-emits user input with no transformation, substitution, or validation despite being prompted for review or conditional modification."

**Detection**:
- Output identical to input
- No analysis performed
- User question not answered
- Circular reference

**Mitigation**:
1. Always process/analyze input
2. Provide actionable response
3. If uncertain, ask clarifying question
4. Never parrot back without value-add

---

### CJF-08: Known-Good Structure Regression

**Description**: AI breaks validated syntax (YAML, Makefiles, shell) while attempting improvements.

**From LLMCJF**:
> "The LLM injects malformed substitutions into validated YAML, Makefile, or shell syntax, breaking indentation, heredoc boundaries, or reserved syntax."

**Example**:
```yaml
# Before (valid):
matrix:
  sanitizer: [address, undefined, memory]

# Bad AI change (invalid indentation):
matrix:
sanitizer: [address, undefined, memory]
```

**Detection**:
- YAML/JSON validation fails
- Shell script syntax errors
- Makefile parse errors
- CI/CD workflow failures

**Mitigation**:
1. Schema validation for structured files
2. Syntax check before commit
3. Minimal changes to proven configs
4. Test in isolation before integration

---

## Project-Specific Anti-Patterns

### AP-01: Fuzzer Option Misconfiguration

**Description**: Setting fuzzer options that cause OOMs, timeouts, or reduce effectiveness.

**Bad Examples**:
```bash
max_len = 1048576000  # 1GB - causes OOM
timeout = 1  # Too short, misses complex bugs
rss_limit_mb = 512  # Too small for valid profiles
jobs = 1  # Wastes CPU cores
```

**Detection**:
- Frequent OOM crashes
- No crashes found (timeout too short)
- Low exec/sec (inefficient settings)
- CPU underutilization

**Mitigation**:
1. Use project-tested values as baseline
2. Gradual increases with monitoring
3. Balance timeout vs depth vs throughput
4. Validate against known POCs

**Current Values** (validated):
```bash
max_len = 15728640  # 15MB
timeout = 45  # 45s
rss_limit_mb = 8192  # 8GB
jobs = 32  # W5-2465X optimized
```

---

### AP-02: Corpus Corruption

**Description**: Breaking corpus files during migration, compression, or processing.

**Example**:
```bash
# Bad: Lossy compression
gzip -9 corpus/*.icc  # Changes file extensions!

# Bad: Incorrect copy
cp corpus/* seed/  # Doesn't preserve structure
```

**Detection**:
- Fuzzer can't load corpus
- File format errors
- Reduced coverage
- Corpus validation failures

**Mitigation**:
1. Preserve file extensions
2. Use rsync for structure preservation
3. Validate corpus after operations
4. Maintain checksums

---

### AP-03: Sanitizer Flag Conflicts

**Description**: Mixing incompatible sanitizer flags causing build failures.

**Example**:
```bash
# Bad: ASan + MSan conflict
CFLAGS="-fsanitize=address -fsanitize=memory"
```

**Detection**:
- Linker errors
- Sanitizer initialization failures
- Runtime crashes on startup

**Mitigation**:
1. One sanitizer per build
2. Use ClusterFuzzLite matrix strategy
3. Separate builds for each sanitizer
4. Never mix ASan/MSan/TSan

**Current Approach**:
```yaml
# .github/workflows/clusterfuzzlite.yml
strategy:
  matrix:
    sanitizer: [address, undefined, memory]
    # Separate jobs, no conflicts
```

---

### AP-04: Path Hardcoding

**Description**: Using absolute or environment-specific paths instead of relative or configurable.

**Bad Examples**:
```bash
/home/xss/copilot/iccLibFuzzer/fuzzers  # User-specific
/src/ipatch/fuzzers  # Old repository name
C:\Users\Developer\project  # Windows-specific
```

**Detection**:
- Build fails on different systems
- CI/CD failures
- Docker container issues

**Mitigation**:
1. Use relative paths from project root
2. Use environment variables ($SRC, $OUT)
3. Make paths configurable
4. Test on different environments

**Correct Pattern**:
```bash
$SRC/iccLibFuzzer/fuzzers  # Environment variable
./fuzzers  # Relative to CWD
$(dirname $0)/../fuzzers  # Relative to script
```

---

### AP-05: Session State Loss

**Description**: Forgetting earlier session context, redoing work or contradicting decisions.

**Example**:
```
Session 1: "Fixed ipatch references in 18 files"
Session 2: AI suggests fixing ipatch references again
```

**Detection**:
- Repeated work
- Contradictory recommendations
- Ignoring session snapshots
- Re-solving solved problems

**Mitigation**:
1. Read NEXT_SESSION_START.md first
2. Review latest snapshot before starting
3. Check git log for recent changes
4. Reference session summaries

**Infrastructure**: `.copilot-sessions/` directory

---

## Detection and Prevention

### Automated Detection (Planned)

```bash
# Pre-commit hooks
.git/hooks/pre-commit:
  - Check for hardcoded paths
  - Validate YAML/JSON syntax
  - Grep for known anti-patterns
  - Verify build passes

# CI/CD checks
- Build on multiple platforms
- Run full test suite
- Sanitizer validation
- Coverage tracking
```

### Manual Detection

**Code Review Checklist**:
- [ ] No hallucinated implementations
- [ ] No unnecessary complexity
- [ ] Changes address actual problem
- [ ] All occurrences fixed (grep verified)
- [ ] Build system not regressed
- [ ] No syntax errors in configs
- [ ] Paths are relative/configurable
- [ ] Session context maintained

---

## Escalation

### When Anti-Pattern Detected

**Severity: High** (Security, data loss, corruption)
1. 🛑 STOP immediately
2. 🛑 DO NOT commit
3. 🛑 Alert user
4. 🛑 Document in session snapshot
5. 🛑 Follow incident response

**Severity: Medium** (Build breaks, regressions)
1. ⚠️  Pause and analyze
2. ⚠️  Revert if already committed
3. ⚠️  Document in anti-patterns
4. ⚠️  Fix properly
5. ⚠️  Update governance

**Severity: Low** (Style issues, minor inefficiency)
1. ℹ️  Note in session log
2. ℹ️  Fix if time permits
3. ℹ️  Add to future improvement list

---

## Learning Loop

### After Each Failure

1. **Document**:
   - What happened
   - Why it happened
   - How it was detected
   - How it was fixed

2. **Prevent**:
   - Update governance docs
   - Add detection mechanisms
   - Improve session templates
   - Train on new patterns

3. **Monitor**:
   - Watch for recurrence
   - Track pattern frequency
   - Measure mitigation effectiveness

---

## References

### LLMCJF Original Research
- `llmcjf/profiles/llm_cjf_heuristics.yaml` - Original CJF patterns
- `llmcjf/profiles/llmcjf-hardmode-ruleset.json` - Enforcement rules
- `llmcjf/STRICT_ENGINEERING_PROLOGUE.md` - Behavioral mode

### Project History
- Session snapshots in `.copilot-sessions/snapshots/`
- Session summaries in `.copilot-sessions/summaries/`
- Git history for pattern analysis

---

**Status**: ✅ Active  
**Last Update**: 2025-12-24  
**Pattern Count**: 13 (8 CJF + 5 Project-Specific)  
**Next Review**: After next major failure or monthly
