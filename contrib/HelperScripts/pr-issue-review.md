# PR & Issue Helper Scripts

**Last Updated:** Thu Nov 27 22:50:49 EST 2025

## Summary

Tooling to help generate an Issue, Build from Head or Review a PR on Unix & Windows.
 - Tests for pass or fail but needs visual review while refinements are made

## PR Build & Check

### Unix PR Review Tool

- Run the following command in your Terminal:

```
cd /tmp
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/unix-pr-review.sh)"
```

### Windows PR Review Tool

- Run the following command in your Developer Powershell:

```
cd \tmp
iex (iwr -Uri "https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/windows-pr-review.ps1").Content
```

- Asks for the PR to Checkout & Test
- Runs the baseline checks

## New Issue Templates

### Unix

The templates can be modified by Users or Maintainers for Stable Reproductions.

## New Unix Issue

 - Paste the Issue into the Reproduction Tool
 - Run the following command in your Terminal:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/new-issue-reproduction.sh)"
```


### Unix New Issue Example

```
======================================================
=  ENTER Issue or Problem (end with EOF / Ctrl-D) —  =
======================================================

test
thank you

A new Issue can be opened using:

gh issue create --repo InternationalColorConsortium/iccDEV --title "New Issue" --body-file iccDEV/Testing/poc_input.txt --web
```

### Windows New Issue

 - Paste the Issue into the Reproduction Tool
 - Run the following command in your Terminal:

```
iex (iwr -Uri "https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/windows-new-issue.ps1").Content
```

### Windows New Issue Example

```
======================================================
=  ENTER Issue or Problem (end with Ctrl-Z)          =
======================================================

Test
Ignore
^Z

A new Issue can be opened using:

gh issue create --repo InternationalColorConsortium/iccDEV --title "New Issue" --body-file poc_input.txt --web
```

### Reproduction Note

- Unix is primary test platform
  - Linux is preferred
    - Asan
    - Ubsan
    - Tsan
    - Introspection

- Windows only provides for Asan

