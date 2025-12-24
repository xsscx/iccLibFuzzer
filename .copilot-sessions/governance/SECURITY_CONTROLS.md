# Security Controls
## GitHub Copilot CLI Governance

**Version**: 1.0  
**Effective**: 2025-12-24  
**Compliance**: Mandatory

---

## Security Principles

1. **No Secrets in Code**: Never commit credentials, tokens, keys, passwords
2. **Least Privilege**: Only access what's necessary for the task
3. **Defense in Depth**: Multiple layers of protection
4. **Fail Secure**: On security violation, stop and alert
5. **Auditability**: All security-relevant actions logged

---

## Prohibited Actions

### NEVER Do These (Automatic Fail)

#### 1. Credential Exposure
```yaml
❌ FORBIDDEN:
- Committing API keys, tokens, passwords
- Logging authentication credentials
- Hardcoding secrets in source code
- Echoing environment variables with secrets
- Including credentials in error messages
- Storing secrets in plaintext files
```

**Detection**:
```bash
# Pre-commit check (planned automation)
git diff --cached | grep -iE '(password|api_key|secret|token|private_key)'
```

**Mitigation**:
- Use environment variables
- Use secret management tools (GitHub Secrets, Vault)
- Reference secrets by name, never by value
- Review all commits before push

#### 2. Sensitive Data Exposure
```yaml
❌ FORBIDDEN:
- Committing PII (personally identifiable information)
- Logging user data or system internals
- Including network configurations in docs
- Exposing internal system architecture
- Sharing proprietary algorithms or data
```

**Detection**:
- Manual review of all commits
- Automated scanning (planned: git-secrets, trufflehog)

**Mitigation**:
- Sanitize all outputs
- Use placeholder data in examples
- Redact sensitive information
- Review before commit

#### 3. Code Injection Vulnerabilities
```yaml
❌ FORBIDDEN:
- Unsanitized user input in shell commands
- Dynamic code execution without validation
- SQL injection patterns
- Path traversal vulnerabilities
- Command injection in build scripts
```

**Example - Bad**:
```cpp
// NEVER DO THIS
system(user_input.c_str());
```

**Example - Good**:
```cpp
// Validate and sanitize
if (!isValidInput(user_input)) return false;
safeExecute(sanitized_input);
```

#### 4. Dependency Security Violations
```yaml
❌ FORBIDDEN:
- Adding dependencies without review
- Using outdated/vulnerable versions
- Ignoring security warnings
- Bypassing dependency scans
```

**Requirements**:
- Review all new dependencies
- Check for known CVEs
- Verify integrity (checksums, signatures)
- Document dependency justification

---

## Security Boundaries

### File System Access

**Allowed**:
- Current working directory: `/home/xss/copilot/iccLibFuzzer`
- All subdirectories under CWD
- Temporary directories for builds (`/tmp/`)
- Read-only access to system tools

**Forbidden**:
- User home directory (except CWD)
- System directories (`/etc`, `/usr`, `/var`)
- Other users' directories
- Network mounts without approval

**Enforcement**:
```bash
# All operations must be within CWD
pwd  # Verify: /home/xss/copilot/iccLibFuzzer
```

### Network Access

**Allowed**:
- GitHub API (read operations)
- Package managers (apt, pip, npm)
- ClusterFuzzLite containers (localhost)
- Documentation sites (read-only)

**Forbidden**:
- Exfiltration of code or data
- Unauthorized API calls
- Downloading unsigned binaries
- Establishing persistent connections

**Verification**:
- Review all network operations
- Log all external connections
- Verify HTTPS for all connections

### Code Modification

**Allowed**:
- Minimal, surgical changes only
- Bug fixes with clear justification
- Performance improvements with benchmarks
- Security fixes (highest priority)

**Forbidden**:
- Rewriting working code without reason
- Changing code style without permission
- Modifying security-critical sections without review
- Deleting functional code

**Pattern**:
```bash
# Good: Surgical fix
git diff --stat
# .clusterfuzzlite/build.sh | 28 +++++++-------

# Bad: Massive rewrite
git diff --stat
# 157 files changed, 8234 insertions(+), 6891 deletions(-)
```

---

## CI/CD Security

### GitHub Actions

**Requirements**:
1. ✅ All workflows reviewed before merge
2. ✅ No secrets in workflow files
3. ✅ Pin action versions (not @master)
4. ✅ Limit workflow permissions
5. ✅ Review all third-party actions

**Example - Secure Workflow**:
```yaml
name: Secure Build
on: [push]

permissions:
  contents: read  # Minimal permissions

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4  # Pinned version
      - name: Build
        run: make build
        # No secrets exposed
```

**Forbidden**:
```yaml
❌ BAD:
permissions: write-all  # Too broad

❌ BAD:
- name: Deploy
  run: echo ${{ secrets.AWS_KEY }}  # Exposes secret

❌ BAD:
- uses: random-user/action@master  # Unvetted, unpinned
```

### ClusterFuzzLite

**Security Controls**:
1. ✅ Build in isolated Docker containers
2. ✅ No network access during fuzzing
3. ✅ Resource limits enforced
4. ✅ Crash artifacts sanitized before upload
5. ✅ Corpus data version controlled

**Configuration Review**:
```yaml
# .clusterfuzzlite/project.yaml
language: c++
sanitizers:
  - address  # Memory safety
  - undefined  # UB detection
  - memory  # Use-after-free, etc.

# Security: Fuzzers run with minimal privileges
# No network access, isolated filesystem
```

---

## Fuzzing Security

### Input Validation

**Requirements**:
- All fuzzer inputs treated as hostile
- No assumptions about input validity
- Bounds checking on all operations
- Sanitizers enabled (ASan, UBSan, MSan)

**Pattern**:
```cpp
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  // Validate size
  if (size < 4 || size > 15 * 1024 * 1024) return 0;
  
  // Validate format
  if (!isValidICCHeader(data, size)) return 0;
  
  // Safe processing
  IccProfile profile;
  profile.Read(data, size);  // Sanitizer-instrumented
  
  return 0;
}
```

### Crash Artifact Handling

**Requirements**:
1. ✅ Sanitize before storage
2. ✅ No PII in crash files
3. ✅ Verify file sizes (no OOMs stored)
4. ✅ Checksum verification
5. ✅ Retention limits (90 days)

**Process**:
```bash
# Save crash artifacts
mkdir -p poc-archive/
cp crash-* poc-archive/

# Sanitize metadata
sha256sum crash-* > checksums.txt

# Document
cat > README.md << EOF
Crash: $filename
SHA256: $checksum
Fuzzer: $fuzzer
Sanitizer: $sanitizer
Date: $(date -u +%Y-%m-%d)
EOF
```

---

## Incident Response

### Security Violation Detected

**Immediate Actions**:
1. 🛑 **STOP** all operations
2. 🛑 **DO NOT** commit or push
3. 🛑 **ALERT** user immediately
4. 🛑 **DOCUMENT** the violation

**Template**:
```
🔴 SECURITY VIOLATION DETECTED

Type: [Credential Exposure / Data Leak / Code Injection / Other]
Severity: [Critical / High / Medium / Low]
Description: [What was detected]
Location: [File, line, or operation]

STOPPED: No changes committed or pushed.
ACTION REQUIRED: Review and remediate before proceeding.
```

### Credential Leak Response

**If secrets committed**:
```bash
# 1. DO NOT PUSH
git reset --soft HEAD~1  # Undo commit

# 2. Purge from history if already pushed
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/secret/file" \
  --prune-empty --tag-name-filter cat -- --all

# 3. Rotate compromised credentials IMMEDIATELY
# 4. Document in security incident log
# 5. Update .gitignore to prevent recurrence
```

---

## Secure Development Practices

### Code Review Checklist

Before every commit:
- [ ] No hardcoded secrets or credentials
- [ ] No PII or sensitive data
- [ ] Input validation present
- [ ] Error handling secure (no info leaks)
- [ ] Dependencies reviewed
- [ ] No injection vulnerabilities
- [ ] Sanitizers enabled for fuzzing code
- [ ] Changes minimal and justified

### Git Hygiene

**Requirements**:
```bash
# 1. Never commit secrets
echo "*.key" >> .gitignore
echo "*.pem" >> .gitignore
echo ".env" >> .gitignore
echo "secrets/" >> .gitignore

# 2. Review before commit
git diff --cached

# 3. Clear commit messages
git commit -m "Fix: Description of what and why"

# 4. Sign commits (optional but recommended)
git commit -S -m "Signed commit"
```

---

## Compliance Verification

### Automated Checks (Planned)

```bash
# Pre-commit hook: .git/hooks/pre-commit
#!/bin/bash
set -e

# Check for secrets
if git diff --cached | grep -iE '(password|api_key|secret|token)'; then
  echo "🔴 SECURITY: Potential secret detected"
  exit 1
fi

# Check for large files
if git diff --cached --stat | grep -E '[0-9]{4,}\s+insertions'; then
  echo "⚠️  WARNING: Large changes detected - review carefully"
fi

# Check for file size
MAX_SIZE=1048576  # 1MB
for file in $(git diff --cached --name-only); do
  size=$(stat -c%s "$file" 2>/dev/null || echo 0)
  if [ $size -gt $MAX_SIZE ]; then
    echo "🔴 SECURITY: File too large: $file ($size bytes)"
    exit 1
  fi
done
```

### Manual Audit

**Weekly**:
- [ ] Review all commits for security issues
- [ ] Check GitHub Actions logs for anomalies
- [ ] Verify no secrets in repository
- [ ] Review session snapshots for violations

**Monthly**:
- [ ] Comprehensive security audit
- [ ] Update dependency versions
- [ ] Review access logs
- [ ] Update security controls as needed

---

## References

### Security Standards
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [NIST Secure Software Development](https://csrc.nist.gov/publications/detail/sp/800-218/final)

### Tools
- [git-secrets](https://github.com/awslabs/git-secrets) - Prevent committing secrets
- [trufflehog](https://github.com/trufflesecurity/trufflehog) - Find secrets in git history
- [gitleaks](https://github.com/gitleaks/gitleaks) - SAST tool for secrets

### Project-Specific
- `.llmcjf-config.yaml` - Security boundaries defined
- `llmcjf/profiles/` - Behavioral controls
- `.github/workflows/` - CI/CD security configs

---

**Status**: ✅ Active  
**Last Review**: 2025-12-24  
**Next Review**: 2025-12-31  
**Compliance**: Mandatory for all Copilot CLI sessions
