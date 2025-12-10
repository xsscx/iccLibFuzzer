#!/bin/bash
###############################################################################
# Copyright (c) David H Hoyt LLC
#
# Last Updated:  16-DEC-2025-2025 1400Z by David Hoyt
#
# Intent: test_sanitization.sh
#
#
#
###############################################################################

set -euo pipefail

# Source the canonical sanitizer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -r "$SCRIPT_DIR/sanitize.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/sanitize.sh"
else
  echo "ERROR: Cannot find sanitize.sh in $SCRIPT_DIR" >&2
  exit 1
fi

echo "=========================================="
echo "Testing Sanitization Functions"
echo "=========================================="
echo ""

pass=0
fail=0

run_test() {
  local test_name="$1"
  local input="$2"
  local expected="$3"
  local func="${4:-sanitize_line}"
  
  echo "Test $((pass + fail + 1)): $test_name"
  echo "  Input:    $input"
  echo "  Expected: $expected"
  
  local result
  result=$("$func" "$input")
  echo "  Result:   $result"
  
  if [ "$result" = "$expected" ]; then
    echo "  ✅ PASS"
    pass=$((pass + 1))
  else
    echo "  ❌ FAIL"
    fail=$((fail + 1))
  fi
  echo ""
}

# =============================================================================
# HTML Entity Escaping Tests
# =============================================================================

run_test "Basic XSS payload" \
  "<script>alert('xss')</script>" \
  "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"

run_test "All HTML special chars" \
  "A&B <tag> \"quoted\" 'single'" \
  "A&amp;B &lt;tag&gt; &quot;quoted&quot; &#39;single&#39;"

run_test "Realistic cppcheck output" \
  "[IccTagBasic.cpp:42]: (warning) Member variable 'IccTag::m_nReserved' is not initialized." \
  "[IccTagBasic.cpp:42]: (warning) Member variable &#39;IccTag::m_nReserved&#39; is not initialized."

run_test "Empty string" \
  "" \
  ""

run_test "Normal text (no special chars)" \
  "Normal text with numbers 123 and letters abc" \
  "Normal text with numbers 123 and letters abc"

# =============================================================================
# Unicode and Charset Tests
# =============================================================================

run_test "Unicode characters (UTF-8)" \
  "Hello 世界 مرحبا 🌍" \
  "Hello 世界 مرحبا 🌍"

run_test "Unicode with HTML entities" \
  "<div>Hello 世界 & 'test'</div>" \
  "&lt;div&gt;Hello 世界 &amp; &#39;test&#39;&lt;/div&gt;"

run_test "Emoji and special symbols" \
  "✅ PASS ❌ FAIL 🔒 Security" \
  "✅ PASS ❌ FAIL 🔒 Security"

run_test "Mixed RTL/LTR text with entities" \
  "English & العربية <tag>" \
  "English &amp; العربية &lt;tag&gt;"

run_test "Zero-width characters (preserved - not security risk)" \
  "test​zero‌width​chars" \
  "test​zero‌width​chars"

# =============================================================================
# Control Character and Injection Tests
# =============================================================================

run_test "Null bytes removed" \
  "$(printf 'test\x00null\x00byte')" \
  "testnullbyte"

run_test "Carriage return removed" \
  "$(printf 'line1\r\nline2')" \
  "line1 line2"

run_test "Tab normalized to space" \
  "$(printf 'line1\tTab\nLine2')" \
  "line1Tab Line2"

run_test "ANSI escape sequences (CSI)" \
  "$(printf '\033[31mRed\033[0m Text')" \
  "[31mRed[0m Text"

run_test "Bell and other control chars" \
  "$(printf 'test\007bell\010backspace')" \
  "testbellbackspace"

# =============================================================================
# Homograph and Lookalike Attack Tests
# =============================================================================

run_test "Cyrillic lookalikes" \
  "Аdmin (Cyrillic A)" \
  "Аdmin (Cyrillic A)"

run_test "Mathematical bold/italic (preserved)" \
  "𝐇𝐞𝐥𝐥𝐨 𝑾𝒐𝒓𝒍𝒅" \
  "𝐇𝐞𝐥𝐥𝐨 𝑾𝒐𝒓𝒍𝒅"

# =============================================================================
# Truncation and Length Tests
# =============================================================================

# Test truncation with very long input
long_input=$(printf 'A%.0s' {1..2000})
echo "Test $((pass + fail + 1)): Long input truncation (2000 chars)"
result=$(sanitize_line "$long_input")
result_len=${#result}
echo "  Input length: 2000"
echo "  Result length: $result_len"
echo "  Max allowed: $SANITIZE_LINE_MAXLEN"
if [ "$result_len" -le "$SANITIZE_LINE_MAXLEN" ]; then
  echo "  ✅ PASS (truncated correctly)"
  pass=$((pass + 1))
else
  echo "  ❌ FAIL (not truncated)"
  fail=$((fail + 1))
fi
echo ""

# =============================================================================
# XSS and Injection Vector Tests
# =============================================================================

run_test "HTML event handler injection" \
  "<img src=x onerror='alert(1)'>" \
  "&lt;img src=x onerror=&#39;alert(1)&#39;&gt;"

run_test "JavaScript protocol" \
  "javascript:alert('xss')" \
  "javascript:alert(&#39;xss&#39;)"

run_test "Data URI with base64" \
  "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==" \
  "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="

run_test "SVG with script" \
  "<svg onload=alert(1)>" \
  "&lt;svg onload=alert(1)&gt;"

run_test "Markdown injection attempt" \
  "[Click me](javascript:alert('xss'))" \
  "[Click me](javascript:alert(&#39;xss&#39;))"

run_test "HTML comment injection" \
  "<!-- <script>alert(1)</script> -->" \
  "&lt;!-- &lt;script&gt;alert(1)&lt;/script&gt; --&gt;"

run_test "CSS expression injection" \
  "style='expression(alert(1))'" \
  "style=&#39;expression(alert(1))&#39;"

run_test "XML entity expansion attempt" \
  "<!ENTITY xxe SYSTEM \"file:///etc/passwd\">" \
  "&lt;!ENTITY xxe SYSTEM &quot;file:///etc/passwd&quot;&gt;"

run_test "CDATA section" \
  "<![CDATA[<script>alert(1)</script>]]>" \
  "&lt;![CDATA[&lt;script&gt;alert(1)&lt;/script&gt;]]&gt;"

run_test "Server-side template injection" \
  '{{7*7}} ${7*7} <%= 7*7 %>' \
  '{{7*7}} ${7*7} &lt;%= 7*7 %&gt;'

run_test "Path traversal in filename" \
  "../../../etc/shadow" \
  ".._.._.._etc_shadow" \
  "sanitize_filename"

run_test "Windows path traversal" \
  "..\\..\\windows\\system32" \
  "..-..-windows-system32" \
  "sanitize_filename"

run_test "Command injection attempt" \
  "test; rm -rf / #" \
  "test; rm -rf / #"

run_test "SQL injection pattern" \
  "' OR '1'='1" \
  "&#39; OR &#39;1&#39;=&#39;1"

run_test "LDAP injection pattern" \
  "*()|&" \
  "*()|&amp;"

# =============================================================================
# Edge Cases
# =============================================================================

run_test "Multiple consecutive entities" \
  "&&&&<<<<>>>>" \
  "&amp;&amp;&amp;&amp;&lt;&lt;&lt;&lt;&gt;&gt;&gt;&gt;"

run_test "Already encoded entities (double encoding)" \
  "&lt;script&gt;" \
  "&amp;lt;script&amp;gt;"

run_test "Mixed quotes" \
  "test \"'\" nested" \
  "test &quot;&#39;&quot; nested"

run_test "Backslash and special chars" \
  "C:\\Windows\\System32 & 'cmd'" \
  "C:\\Windows\\System32 &amp; &#39;cmd&#39;"

# =============================================================================
# sanitize_print Multi-line Tests
# =============================================================================

echo "Test $((pass + fail + 1)): Multi-line with sanitize_print"
multiline_input="Line 1: <error> & 'quote'
Line 2: \"test\"
Line 3: Normal"
result=$(sanitize_print "$multiline_input")
if echo "$result" | grep -q "&lt;error&gt;" && \
   echo "$result" | grep -q "&amp;" && \
   echo "$result" | grep -q "&#39;"; then
  echo "  ✅ PASS (contains expected entities)"
  pass=$((pass + 1))
else
  echo "  ❌ FAIL"
  fail=$((fail + 1))
fi
echo ""

# =============================================================================
# sanitize_ref and sanitize_filename Tests
# =============================================================================

run_test "Ref sanitization: branch name" \
  "feature/test-123" \
  "feature/test-123" \
  "sanitize_ref"

run_test "Ref sanitization: dangerous chars replaced" \
  "feature\$test<>|branch" \
  "feature-test-branch" \
  "sanitize_ref"

run_test "Filename sanitization: slashes to underscores" \
  "../../etc/passwd" \
  ".._.._etc_passwd" \
  "sanitize_filename"

# =============================================================================
# Results Summary
# =============================================================================

echo "=========================================="
echo "Results: $pass passed, $fail failed"
echo "=========================================="

if [ $fail -eq 0 ]; then
  echo "✅ All tests PASSED"
  exit 0
else
  echo "❌ Some tests FAILED"
  exit 1
fi
echo "  Result:   $result"
if [ "$result" = "$expected" ]; then
  echo "  ✅ PASS"
  pass=$((pass + 1))
else
  echo "  ❌ FAIL"
  fail=$((fail + 1))
fi
echo ""

# Test 3: Realistic cppcheck output
echo "Test 3: Cppcheck-like output"
input="[IccTagBasic.cpp:42]: (warning) Member variable 'IccTag::m_nReserved' is not initialized."
expected="[IccTagBasic.cpp:42]: (warning) Member variable &#39;IccTag::m_nReserved&#39; is not initialized."
result=$(sanitize_html "$input")
echo "  Input:    $input"
echo "  Expected: $expected"
echo "  Result:   $result"
if [ "$result" = "$expected" ]; then
  echo "  ✅ PASS"
  pass=$((pass + 1))
else
  echo "  ❌ FAIL"
  fail=$((fail + 1))
fi
echo ""

# Test 4: Empty string
echo "Test 4: Empty string"
input=""
expected=""
result=$(sanitize_html "$input")
echo "  Input:    (empty)"
echo "  Expected: (empty)"
echo "  Result:   (empty)"
if [ "$result" = "$expected" ]; then
  echo "  ✅ PASS"
  pass=$((pass + 1))
else
  echo "  ❌ FAIL"
  fail=$((fail + 1))
fi
echo ""

# Test 5: No special chars
echo "Test 5: Normal text (no special chars)"
input="Normal text with numbers 123 and letters abc"
expected="Normal text with numbers 123 and letters abc"
result=$(sanitize_html "$input")
echo "  Input:    $input"
echo "  Expected: $expected"
echo "  Result:   $result"
if [ "$result" = "$expected" ]; then
  echo "  ✅ PASS"
  pass=$((pass + 1))
else
  echo "  ❌ FAIL"
  fail=$((fail + 1))
fi
echo ""

# Test 6: Multiple lines simulation
echo "Test 6: Multi-line output (simulated)"
input="Line 1: <error> & 'quote'
Line 2: \"test\""
result=$(sanitize_html "$input")
echo "  Input:    $input"
echo "  Result:   $result"
if echo "$result" | grep -q "&lt;error&gt;" && echo "$result" | grep -q "&amp;" && echo "$result" | grep -q "&#39;"; then
  echo "  ✅ PASS (contains expected entities)"
  pass=$((pass + 1))
else
  echo "  ❌ FAIL"
  fail=$((fail + 1))
fi
echo ""

echo "=========================================="
echo "Results: $pass passed, $fail failed"
echo "=========================================="

if [ $fail -eq 0 ]; then
  echo "✅ All tests PASSED"
  exit 0
else
  echo "❌ Some tests FAILED"
  exit 1
fi
