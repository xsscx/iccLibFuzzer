# Session Template
## GitHub Copilot CLI Standard Workflow

**Version**: 1.0  
**Effective**: 2025-12-24  
**Purpose**: Standardized workflow for consistent, high-quality sessions

---

## Pre-Session Checklist

### 1. Environment Preparation

```bash
# Navigate to project
cd /home/xss/copilot/iccLibFuzzer

# Verify git status
git status
git log --oneline -5

# Check for updates
git pull origin master

# Verify no uncommitted work (or understand state)
git diff
```

### 2. Context Review

**Read These Files** (in order):
1. `.copilot-sessions/next-session/NEXT_SESSION_START.md` - Latest status
2. `.copilot-sessions/summaries/[latest].md` - Previous session
3. `.copilot-sessions/snapshots/[latest].md` - Last state

**Key Questions**:
- What was the last session working on?
- Are there pending tasks?
- Are there known issues?
- What is the current CI/CD status?

### 3. CI/CD Status Check

```bash
# Check recent GitHub Actions runs
gh run list --workflow=clusterfuzzlite.yml --limit 5

# View latest run status
gh run view [run_id]

# Check for failures
gh run list --status=failure --limit 3
```

### 4. Issue/Task Clarification

**User Input Checklist**:
- [ ] Understand the exact problem or goal
- [ ] Clarify any ambiguity before proceeding
- [ ] Verify scope of work
- [ ] Confirm any constraints or preferences
- [ ] Ask questions if anything unclear

---

## Session Initialization

### 1. Report Intent

```bash
# Use report_intent tool immediately
report_intent: "[Brief description of session goal]"
```

**Examples**:
- "Fixing CFL build failure"
- "Implementing corpus caching"
- "Investigating heap overflow"
- "Updating documentation"

### 2. Create Session Snapshot

**Filename**: `YYYY-MM-DD_HHMMSS_state.md`

**Content**:
```markdown
# Session State Snapshot
**Timestamp**: [Current datetime]
**Session Type**: [Bug Fix / Feature / Investigation]
**Repository**: https://github.com/xsscx/iccLibFuzzer

## Current State
[Git status, commits, working tree state]

## Planned Work
[What will be done this session]

## Context
[Relevant background, issues, references]
```

### 3. Establish Success Criteria

**Define**:
- What does "done" look like?
- How will we verify success?
- What tests must pass?
- What documentation is needed?

---

## Work Execution Phase

### 1. Analysis Before Action

**For Bug Fixes**:
```bash
# 1. Reproduce the bug
[commands to reproduce]

# 2. Identify root cause
[analysis steps]

# 3. Locate exact code/config issue
[grep, view, etc.]

# 4. Understand why it's wrong
[rationale]
```

**For Features**:
```bash
# 1. Understand requirements
[what needs to be built]

# 2. Design approach
[how it will work]

# 3. Identify affected components
[what needs to change]

# 4. Plan testing strategy
[how to verify]
```

### 2. Minimal Change Implementation

**Pattern**:
```bash
# 1. Make smallest possible change
edit [file]: [precise old_str] → [new_str]

# 2. Verify immediately
[compile / test / run]

# 3. If works, commit
# 4. If not, revert and try again
```

**Avoid**:
- ❌ Changing multiple things at once
- ❌ Rewriting working code
- ❌ Adding unnecessary features
- ❌ Over-engineering

### 3. Verification Steps

**Always Verify**:
```bash
# Code compiles
cd Build && cmake Cmake && make -j32

# Tests pass
cd Testing && ./RunTests.sh

# No new warnings
make 2>&1 | grep -i warning

# Changes are minimal
git diff --stat
```

**For Fuzzing Changes**:
```bash
# Fuzzer builds
[build command]

# Fuzzer runs
./fuzzer corpus/ -max_total_time=10

# Sanitizer works
[verify sanitizer output]
```

### 4. Documentation As You Go

**Update Snapshot**:
- Document decisions made
- Record alternatives considered
- Note any issues encountered
- Track time spent

**Commit Early, Commit Often**:
- One logical change per commit
- Clear commit message each time
- Push after verification

---

## Verification and Testing

### 1. Pre-Commit Checks

**Mandatory**:
```bash
# 1. Review changes
git diff

# 2. Check for secrets
git diff | grep -iE '(password|api_key|secret|token)'

# 3. Verify no debug code
git diff | grep -iE '(console\.log|print\(|TODO|FIXME)'

# 4. Build passes
make clean && make -j32

# 5. Tests pass
./RunTests.sh
```

### 2. Commit with Quality Message

**Template**:
```bash
git commit -m "
<Type>: <Summary (50 chars)>

What:
- [Specific changes]

Why:
- [Rationale]

How:
- [Implementation approach]

Impact:
- [Effects and implications]

Testing:
- [How verified]

Related: [Issue/Run IDs]
"
```

### 3. Push and Monitor

```bash
# Push to remote
git push origin master

# Verify push succeeded
git log origin/master..HEAD  # Should be empty

# Monitor CI/CD
gh run watch  # If triggered
```

---

## Session Closure

### 1. Generate Session Summary

**Create**: `.copilot-sessions/summaries/YYYY-MM-DD_session.md`

**Include**:
- Session overview
- Accomplishments
- Problem and resolution
- Metrics (time, files, lines)
- Impact assessment
- Next steps

### 2. Update Next-Session Guide

**Update**: `.copilot-sessions/next-session/NEXT_SESSION_START.md`

**Sections to Update**:
- Date Updated
- Status
- Recent Commits
- Pending Tasks
- Known Issues
- Quick-start commands

### 3. Final Verification

```bash
# All changes committed
git status  # Should be clean

# Session docs created
ls .copilot-sessions/summaries/$(date +%Y-%m-%d)*.md
ls .copilot-sessions/snapshots/$(date +%Y-%m-%d)*.md

# Next session guide updated
cat .copilot-sessions/next-session/NEXT_SESSION_START.md | head -20
```

### 4. Cleanup (if needed)

```bash
# Remove temporary files
rm -f *.tmp *.bak

# Clean build artifacts (optional)
rm -rf Build/build_*

# Archive old snapshots (if >30 days old)
find .copilot-sessions/snapshots/ -mtime +30 -delete
```

---

## Session Quality Checklist

### Before Closing Session

**Code Quality**:
- [ ] All changes minimal and justified
- [ ] No regressions introduced
- [ ] Code compiles without warnings
- [ ] Tests pass
- [ ] Documentation updated

**Security**:
- [ ] No secrets committed
- [ ] No sensitive data exposed
- [ ] Input validation present
- [ ] Error handling secure

**Documentation**:
- [ ] Session summary complete
- [ ] Snapshot archived
- [ ] Next-session guide updated
- [ ] Commit messages clear

**Process**:
- [ ] All changes committed and pushed
- [ ] CI/CD status checked
- [ ] Metrics tracked
- [ ] No pending work (or documented)

---

## Common Session Types

### Type 1: Bug Fix

**Duration**: 10-30 minutes  
**Focus**: Minimal, surgical fix

**Workflow**:
1. Reproduce bug
2. Identify root cause
3. Implement minimal fix
4. Verify fix works
5. Document and commit

### Type 2: Feature Implementation

**Duration**: 30-120 minutes  
**Focus**: Planned enhancement

**Workflow**:
1. Clarify requirements
2. Design approach
3. Implement incrementally
4. Test thoroughly
5. Document comprehensively

### Type 3: Investigation

**Duration**: 15-60 minutes  
**Focus**: Analysis and understanding

**Workflow**:
1. Gather information
2. Analyze patterns
3. Form hypotheses
4. Test hypotheses
5. Document findings

### Type 4: Cleanup/Refactor

**Duration**: 20-60 minutes  
**Focus**: Code quality improvement

**Workflow**:
1. Identify areas for improvement
2. Plan refactoring
3. Refactor systematically
4. Verify no behavior change
5. Document improvements

---

## Emergency Session Protocol

### Triggered By
- CI/CD complete failure
- Security vulnerability discovered
- Production incident
- Data loss/corruption

### Modified Workflow

**Priority Order**:
1. 🛑 **STOP and assess** - Don't make it worse
2. 🛑 **Contain** - Prevent further damage
3. 🛑 **Fix** - Minimal change to restore function
4. 🛑 **Verify** - Confirm fix works
5. 🛑 **Document** - What, why, how
6. 🛑 **Follow-up** - Proper fix if needed

**Skip**:
- Extended analysis (do quick assessment)
- Complex refactoring (minimal fix only)
- Perfect documentation (basic is OK)

**Do Later**:
- Root cause analysis
- Comprehensive fix
- Full documentation
- Process improvements

---

## Session Metrics Template

```yaml
session:
  id: YYYYMMDD-HHMMSS
  date: YYYY-MM-DD
  duration_minutes: [X]
  type: [bug_fix / feature / investigation / cleanup]
  outcome: [success / partial / failed]
  
trigger:
  type: [user_request / ci_failure / scheduled / emergency]
  description: "[What initiated session]"

work:
  files_modified: [X]
  lines_added: [X]
  lines_removed: [X]
  commits: [X]
  tools_used: [list]
  
quality:
  tests_passed: [true/false]
  build_clean: [true/false]
  regression_risk: [low/medium/high]
  security_violations: [0]
  
impact:
  severity: [critical/high/medium/low]
  scope: [system-wide / component / isolated]
  user_visible: [true/false]
  
next_steps:
  - [Action item 1]
  - [Action item 2]
```

---

## Tips for Effective Sessions

### Do
- ✅ Read context before starting
- ✅ Make minimal changes
- ✅ Document as you go
- ✅ Verify frequently
- ✅ Commit often with clear messages
- ✅ Ask questions when uncertain

### Don't
- ❌ Skip context review
- ❌ Make unnecessary changes
- ❌ Delay documentation
- ❌ Assume without verification
- ❌ Batch commits for unrelated changes
- ❌ Hallucinate or guess

---

## References

### Governance Documents
- `README.md` - Overview
- `SECURITY_CONTROLS.md` - Security requirements
- `BEST_PRACTICES.md` - Engineering standards
- `TRANSPARENCY_GUIDE.md` - Documentation standards
- `ANTI_PATTERNS.md` - Failure modes to avoid

### Session Infrastructure
- `.copilot-sessions/snapshots/` - State captures
- `.copilot-sessions/summaries/` - Session reports
- `.copilot-sessions/next-session/` - Start guide

---

**Status**: ✅ Active  
**Last Review**: 2025-12-24  
**Usage**: Required for all Copilot CLI sessions  
**Compliance**: Mandatory
