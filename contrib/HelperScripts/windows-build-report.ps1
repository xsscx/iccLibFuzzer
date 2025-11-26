# ========================== Windows Build Report Script ==========================
# Windows Build Report
# Copyright (c) 2025 International Color Consortium. All rights reserved.
# Author: David Hoyt
# Date: 25-FEB-2025 1030 EST
#
#
# Use a Developer Powershell Terminal
# To be run from iccDEV/
# Run via pwsh: iex (iwr -Uri "https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/windows-build-report.ps1").Content
#
# ============================================================

# Start of Script
Write-Host "============================= Starting Windows iccDEV Build Report =============================" -ForegroundColor Green
Write-Host "Copyright (c) 2025 International Color Consortium. All rights reserved." -ForegroundColor Green
Write-Host "Last Updated: 27-NOV-2025 1121 EST by David H Hoyt LLC" -ForegroundColor Green
# === Windows Build Report ===
$LOG_FILE = ".\build-data.log"
$HTML_FILE = ".\iccdev_build_report.html"

Write-Output "=== iccDEV Windows Build Host Report ===" | Out-File -FilePath $LOG_FILE -Encoding utf8
Write-Output " Last Updated: $(Get-Date) " | Out-File -FilePath $LOG_FILE -Append

# Function to log commands and their outputs
function Log-Command {
    param ($Command)
    Write-Output "=== Command: $Command ===" | Tee-Object -FilePath $LOG_FILE -Append
    try {
        Invoke-Expression $Command 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
    } catch {
        Write-Output "ERROR: $_" | Tee-Object -FilePath $LOG_FILE -Append
    }
    Write-Output "" | Tee-Object -FilePath $LOG_FILE -Append
}

# === SYSTEM INFO COLLECTION ===
Log-Command "systeminfo"
Log-Command "wmic os get Caption, Version, BuildNumber"
Log-Command "wmic cpu get Name"

# === BINARY ANALYSIS ===
$executables = Get-ChildItem -Path . -Filter "*.exe" -Recurse
$dynamicLibs = Get-ChildItem -Path . -Filter "*.dll" -Recurse
$staticLibs = Get-ChildItem -Path . -Filter "*.lib" -Recurse

$totalFiles = ($executables.Count + $dynamicLibs.Count + $staticLibs.Count)
$codesignedFiles = 0
$unsignedFiles = 0
$unsignedFilesList = @()
$codesignedFilesList = @()

foreach ($file in $executables + $dynamicLibs) {
    $signingStatus = Get-AuthenticodeSignature -FilePath $file.FullName
    if ($signingStatus.Status -eq 'Valid') {
        $codesignedFilesList += $file.FullName
        $codesignedFiles++
    } else {
        $unsignedFilesList += $file.FullName
        $unsignedFiles++
    }
}

# === GENERATE HTML REPORT ===
$logContent = Get-Content -Raw $LOG_FILE
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IccDEV Developer Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f4f4f4; }
    </style>
</head>
<body>
<div id="PageBodyContainer">
    <header id="HeaderContainer">
        <div id="HeaderTitleContainer">
            <a href="https://color.org/index.xalter">
                <img src="https://color.org/system/images/ICC_logo_text.gif" width="368" height="27" alt="International Color Consortium">
            </a>
        </div>
        <div id="HeaderLogoContainer">
            <img src="https://color.org/system/images/ICC_logo_top.gif" width="143" height="65" alt="ICC Logo">
            <img src="https://color.org/system/images/hd_images.jpg" width="657" height="46" alt="Making color seamless between devices and documents">
        </div>
    </header>
    <main id="MainContainer">
        <h1>IccDEV Developer Report</h1>
        <p>This report summarizes ICC profile builds and measurements across different hosts, platforms, and toolchains.</p>
        <h2>Build Summary</h2>
        <table>
            <tr><th>Total Files</th><td>$totalFiles</td></tr>
            <tr><th>Executables</th><td>$($executables.Count)</td></tr>
            <tr><th>Dynamic Libraries</th><td>$($dynamicLibs.Count)</td></tr>
            <tr><th>Static Libraries</th><td>$($staticLibs.Count)</td></tr>
            <tr><th>Codesigned Files</th><td>$codesignedFiles</td></tr>
            <tr><th>Unsigned Files</th><td>$unsignedFiles</td></tr>
        </table>
    </main>
"@
# The here-string is **CLOSED PROPERLY** above before adding additional HTML.

# Concatenate the lists properly
$htmlContent += "<h2>Executables</h2><ul>`r`n"
foreach ($exe in $executables) { $htmlContent += "    <li>$($exe.FullName)</li>`r`n" }
$htmlContent += "</ul>`r`n"

$htmlContent += "<h2>Dynamic Libraries</h2><ul>`r`n"
foreach ($dll in $dynamicLibs) { $htmlContent += "    <li>$($dll.FullName)</li>`r`n" }
$htmlContent += "</ul>`r`n"

$htmlContent += "<h2>Static Libraries</h2><ul>`r`n"
foreach ($lib in $staticLibs) { $htmlContent += "    <li>$($lib.FullName)</li>`r`n" }
$htmlContent += "</ul>`r`n"

$htmlContent += "<h2>Codesigned Files</h2><ul>`r`n"
foreach ($file in $codesignedFilesList) { $htmlContent += "    <li>$file</li>`r`n" }
$htmlContent += "</ul>`r`n"

$htmlContent += "<h2>Unsigned Files</h2><ul>`r`n"
foreach ($file in $unsignedFilesList) { $htmlContent += "    <li>$file</li>`r`n" }
$htmlContent += "</ul>`r`n"

# Footer added properly
$htmlContent += @"
        <h2>Build Host Details</h2>
        <pre>$logContent</pre>
<footer id="FooterContainer">
    <div>
        <img src="https://color.org/system/images/ICC_logo_btm.gif" width="133" height="22" alt="ICC Logo">
        <p>&copy; 2025 International Color Consortium | All Rights Reserved.</p>
    </div>
</footer>
</body>
</html>
"@

# Output to file
$htmlContent | Out-File -FilePath $HTML_FILE -Encoding utf8
Write-Host "HTML report generated at: $HTML_FILE"
