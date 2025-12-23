# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 2.3.x   | :white_check_mark: |
| < 2.3   | :x:                |

## Reporting a Vulnerability

The International Color Consortium takes the security of our software seriously. If you believe you have found a security vulnerability in RefIccMAX, please report it to us as described below.

### Reporting Process

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via [GitHub Security Advisories](https://github.com/xsscx/ipatch/security/advisories/new).

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

### What to Include

Please include the following information in your report:

- Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

This information will help us triage your report more quickly.

### Disclosure Policy

When we receive a security bug report, we will:

1. Confirm the problem and determine the affected versions
2. Audit code to find any similar problems
3. Prepare fixes for all supported releases
4. Release patches as soon as possible

### Security Update Communications

Security updates will be announced via:

- GitHub Security Advisories
- Release notes in GitHub Releases
- Repository README

### Preferred Languages

We prefer all communications to be in English.

### Safe Harbor

We support safe harbor for security researchers who:

- Make a good faith effort to avoid privacy violations, destruction of data, and interruption or degradation of our services
- Only interact with accounts you own or with explicit permission of the account holder
- Do not exploit a security issue you discover for any reason (this includes demonstrating additional risk)
- Provide us a reasonable amount of time to resolve the issue before public disclosure

We will not pursue legal action against researchers who follow these guidelines.

## Security Best Practices for Contributors

When contributing to this project:

1. **Never commit secrets**: API keys, passwords, tokens, or other credentials
2. **Validate all inputs**: Especially when processing ICC profile data
3. **Use safe functions**: Prefer bounds-checked functions over unsafe variants
4. **Check for overflows**: Integer overflows in profile parsing can lead to vulnerabilities
5. **Handle NaN/Infinity**: Validate floating-point values in color calculations
6. **Follow secure coding guidelines**: Review CONTRIBUTING.md for detailed standards

## Known Security Considerations

### ICC Profile Parsing

ICC profiles are untrusted input and must be validated:

- **Buffer overflows**: Profile size fields must be validated before allocation
- **Integer overflows**: Tag offsets and sizes must be checked
- **Type confusion**: Tag types must be validated before casting
- **Infinite loops**: Recursive profile references must be detected
- **Resource exhaustion**: Large profiles must have size limits

### Fuzzing

This project includes fuzzing infrastructure. See `ENABLE_FUZZING` in `Build/Cmake/CMakeLists.txt`.

To run fuzzing:

```bash
cmake -DENABLE_FUZZING=ON Build/Cmake
make
# Run fuzzer targets
```

## Security-Related Build Options

The following CMake options enable security hardening:

- `ENABLE_SANITIZERS=ON`: Enable AddressSanitizer and UndefinedBehaviorSanitizer
- `ENABLE_FUZZING=ON`: Enable libFuzzer instrumentation
- `ICC_ENABLE_ASSERTS=ON`: Enable runtime assertions
- `ICC_LOG_SAFE=ON`: Enable bounds-checked logging

## Automated Security Scanning

This repository uses:

- **OSSF Scorecard**: Weekly security posture analysis
- **Dependabot**: Automated dependency updates
- **GitHub Secret Scanning**: Credential leak detection
- **CodeQL** (if enabled): Static application security testing

View current security status: [Security Advisories](https://github.com/xsscx/ipatch/security)

## Attribution

We appreciate researchers and contributors who help improve the security of this project. With your permission, we'll acknowledge your contribution in our security advisories and release notes.

---

**Last Updated**: 2025-12-18  
**Contact**: Via [GitHub Security Advisories](https://github.com/xsscx/ipatch/security/advisories/new)
