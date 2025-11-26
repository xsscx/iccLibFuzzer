###############################################################
#
## Copyright (©) 2025 International Color Consortium.
##                 All rights reserved.
##                 https://color.org
#
# Last Modified: 27-NOV-2025 2300Z by David Hoyt
# Intent: Windows PR Template
#
# Instructions: Please run this powershell script when you have a:
#                 - Config Issue
#                      - Include the Cmake Output
#                  - Build Issue
#                      - Include the Build Output
#                  - Tools Issue
#                      - Provide your Repoduction
#                      - Include the Output
#  URL https://github.com/InternationalColorConsortium/iccDEV
#
#
# iex (iwr -Uri "https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/windows-pr-review.ps1").Content
#
#
#
###############################################################

# Strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================================================"
Write-Host "==================== International Color Consortium ===================="
Write-Host "=============== Copyright (c) 2025 All Rights Reserved ================="
Write-Host ""
Write-Host "Repository URL https://github.com/InternationalColorConsortium/iccDEV"
Write-Host ""
Write-Host "Please Open an Issue with Questions, Comments or Bug Reports. Thank You."
Write-Host ""
Write-Host "===================== iccDEV | Windows PR Review Template ====================="
Write-Host ""

# =======================
# Prompt for PR Number
# =======================
$pr_number = Read-Host "Enter PR number to checkout"

# Sanity checks
if ([string]::IsNullOrWhiteSpace($pr_number)) {
    Write-Error "Error: PR number is empty"
    exit 1
}

if ($pr_number -notmatch '^[0-9]+$') {
    Write-Error "Error: PR number must be numeric"
    exit 1
}

Write-Host ""
Write-Host "========================================================================"
Write-Host "Now checking out PR $pr_number from URL:"
Write-Host "    https://github.com/InternationalColorConsortium/iccDEV/pull/$pr_number"
Write-Host "========================================================================"
Write-Host ""
Write-Host "Fetching repository... then Build & Run Checks..."
Write-Host ""

# Clone if needed
if (-not (Test-Path "iccDEV")) {
    git clone https://github.com/InternationalColorConsortium/iccDEV.git
}

Set-Location iccDEV

Write-Host ""
Write-Host "========================================================================"
Write-Host "*** If there is a CMake Failure, Please paste the error into your Review"
Write-Host "========================================================================"
Write-Host "iccDEV Configure Issue Report ** Please include the data below this line"
Write-Host "========================================================================"
Write-Host ""

# Origin check
$origin_url = git remote get-url origin 2>$null
Write-Host "Remote origin: $origin_url"

$expected_repo = "InternationalColorConsortium/iccDEV"
$expected_https = "https://github.com/$expected_repo.git"
$expected_https_nogit = "https://github.com/$expected_repo"
$expected_ssh = "git@github.com:$expected_repo.git"

if (($origin_url -ne $expected_https) -and
    ($origin_url -ne $expected_https_nogit) -and
    ($origin_url -ne $expected_ssh)) {

    Write-Host "Origin URL mismatch:" -ForegroundColor Red
    Write-Host "  expected: $expected_https"
    Write-Host "       or: $expected_https_nogit"
    Write-Host "       or: $expected_ssh"
    Write-Host "     got: $origin_url"
}

Write-Host ""
Write-Host "============== Host Info =============="
cmd.exe /c ver
Write-Host ""

Write-Host "======== Commit & Branch Info ========="
git show --stat --pretty=format:"Commit: %H`nAuthor: %an`nDate: %ad`n" HEAD | Select-String "Commit"
git branch
Write-Host ""

Write-Host "Fetching PR $pr_number..."
git fetch origin "pull/$pr_number/head:pr-$pr_number"
Write-Host ""

Write-Host "Checking out pr-$pr_number..."
git checkout "pr-$pr_number"
Write-Host ""

Write-Host "PR $pr_number checkout complete."
Write-Host ""

Write-Host "======== Commit & Branch Info ========="
git show --stat --pretty=format:"Commit: %H`nAuthor: %an`nDate: %ad`n" HEAD | Select-String "Commit"
git branch
Write-Host ""
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
Write-Host "========================================================================"
Write-Host "iccDEV Configure Issue Report ** Please include the data above this line"
Write-Host "========================================================================"
Write-Host ""
Write-Host ""
Write-Host "========================================================================"
Write-Host "iccDEV Build Issue Report ****** Please include the data below this line"
Write-Host "========================================================================"
Write-Host ""
          cmake --build build -- /m /maxcpucount
          cmake --build build -- /m /maxcpucount   
Write-Host ""
Write-Host "========================================================================"
Write-Host "iccDEV Build Issue Report ****** Please include the data above this line"
Write-Host "========================================================================"
Write-Host ""
Write-Host "========================================================================"
Write-Host "iccDEV Issue Report ************ Please include the data below this line"
Write-Host "========================================================================"
Write-Host ""
            $exeDirs = Get-ChildItem -Recurse -File -Include *.exe -Path .\build\ |
                Where-Object { $_.FullName -match 'iccdev' -and $_.FullName -notmatch '\\CMakeFiles\\' -and $_.Name -notmatch '^CMake(C|CXX)CompilerId\.exe$' } |
                ForEach-Object { Split-Path $_.FullName -Parent } |
                Sort-Object -Unique
            $env:PATH = ($exeDirs -join ';') + ';' + $env:PATH
            $env:PATH -split ';' | Select-String "icc"
            $toolDirs = Get-ChildItem -Recurse -File -Include *.exe -Path .\Tools\ | ForEach-Object { Split-Path -Parent $_.FullName } | Sort-Object -Unique
            $env:PATH = ($toolDirs -join ';') + ';' + $env:PATH
            pwd
            cd ..\..\Testing
            .\CreateAllProfiles.bat
            .\RunTests.bat
            cd CalcTest\
            .\checkInvalidProfiles.bat
            .\runtests.bat
            cd ..\Display
            .\RunProtoTests.bat
            cd ..\HDR
            .\mkprofiles.bat
            cd ..\mcs\
            .\updateprev.bat
            .\updateprevWithBkgd.bat
            cd ..\Overprint
            .\RunTests.bat
            cd ..
            cd hybrid
            .\BuildAndTest.bat
            cd ..
            cd ..
            pwd
            # Collect .icc profile information
            $profiles = Get-ChildItem -Path . -Filter "*.icc" -Recurse -File
            $totalCount = $profiles.Count
            
            # Group profiles by directory
            $groupedProfiles = $profiles | Group-Object { $_.Directory.FullName }
            
            # Generate Summary Report
            Write-Host "`n========================="
            Write-Host " ICC Profile Report"
            Write-Host "========================="
            
            # Print count per subdirectory
            foreach ($group in $groupedProfiles) {
                Write-Host ("{0}: {1} .icc profiles" -f $group.Name, $group.Count)
            }
            
            Write-Host "`nTotal .icc profiles found: $totalCount"
            Write-Host "=========================`n"
            
            Write-Host "All Done!"
Write-Host ""
Write-Host "========================================================================"
Write-Host "iccDEV Issue Report ************ Please include the data above this line"
Write-Host "========================================================================"
Write-Host ""