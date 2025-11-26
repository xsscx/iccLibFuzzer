###############################################################
#
## Copyright (©) 2025 International Color Consortium.
##                 All rights reserved.
##                 https://color.org
#
# Last Modified: 28-NOV-2025 2300Z by David Hoyt
# Intent: Windows Issue Template
#
# Instructions: Please run this powershell script when you have a new Issue:
#                 - Config Issue
#                      - Include the Cmake Output
#                  - Build Issue
#                      - Include the Build Output
#                  - Tools Issue
#                  *** - Provide your Repoduction ***
#                      - Include the Output
# *** All Reports should include a known good & working reproduction ***
#
#
#
#
#  URL https://github.com/InternationalColorConsortium/iccDEV
#
#
# iex (iwr -Uri "https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/windows-new-issue.ps1").Content
#
#
#
###############################################################

Write-Host ""
Write-Host "===================== iccDEV | Windows New Issue Template ====================="
Write-Host "Fetching the Code..."
Write-Host ""
git clone https://github.com/InternationalColorConsortium/iccDEV.git
cd iccDEV
# git fetch origin pull/247/head:pr-247
# git checkout pr-247
Write-Host "Branch Status"
          pwd
          git branch
          git status
          date
          Write-Host "========= Fetching Deps... ================`n"
          Start-BitsTransfer -Source "https://github.com/InternationalColorConsortium/iccDEV/releases/download/v2.3.1/vcpkg-exported-deps.zip" -Destination "deps.zip"
          Write-Host "========= Extracting Deps... ================`n"
          tar -xf deps.zip
          cd Build/Cmake
          Write-Host "========= Building... ================`n"  
          cmake  -B build -S . -DCMAKE_TOOLCHAIN_FILE="..\..\scripts\buildsystems\vcpkg.cmake" -DVCPKG_MANIFEST_MODE=OFF -DCMAKE_BUILD_TYPE=Debug  -Wno-dev
Write-Host ""
          cmake --build build -- /m /maxcpucount
          cmake --build build -- /m /maxcpucount   
Write-Host ""
            $exeDirs = Get-ChildItem -Recurse -File -Include *.exe -Path .\build\ |
                Where-Object { $_.FullName -match 'iccdev' -and $_.FullName -notmatch '\\CMakeFiles\\' -and $_.Name -notmatch '^CMake(C|CXX)CompilerId\.exe$' } |
                ForEach-Object { Split-Path $_.FullName -Parent } |
                Sort-Object -Unique
            $env:PATH = ($exeDirs -join ';') + ';' + $env:PATH
            $env:PATH -split ';' | Select-String "icc"
            $toolDirs = Get-ChildItem -Recurse -File -Include *.exe -Path .\Tools\ | ForEach-Object { Split-Path -Parent $_.FullName } | Sort-Object -Unique
            $env:PATH = ($toolDirs -join ';') + ';' + $env:PATH
            cd ..\..\Testing

Write-Output ""
Write-Output "======================================================"
Write-Output "=  ENTER Issue or Problem (end with Ctrl-Z)          ="
Write-Output "======================================================"
Write-Output ""

# Unsafe target file (UCI)
$POC_FILE = "poc_input.txt"

# Truncate file
Set-Content -Path $POC_FILE -Value ""

###############################################################################
# Markdown Header
###############################################################################
Add-Content -Path $POC_FILE -Value "# New Issue"
Add-Content -Path $POC_FILE -Value ""

###############################################################################
# Issue Body Input
###############################################################################
Add-Content -Path $POC_FILE -Value "## Issue or Problem Report"
Add-Content -Path $POC_FILE -Value "> Enter description below:"
Add-Content -Path $POC_FILE -Value '```'

# Read raw input until Ctrl-Z
$stdin = [Console]::In.ReadToEnd()
Add-Content -Path $POC_FILE -Value $stdin

Add-Content -Path $POC_FILE -Value '```'
Add-Content -Path $POC_FILE -Value ""

###############################################################################
# Summary
###############################################################################
Write-Output ""
Write-Output "A new Issue can be opened using:"
Write-Output ""
Write-Output 'gh issue create --repo InternationalColorConsortium/iccDEV --title "New Issue" --body-file poc_input.txt --web'
Write-Output ""
