###############################################################
#
## Copyright (©) 2025 International Color Consortium.
##                 All rights reserved.
##                 https://color.org
#
# Last Modified: 27-NOV-2025 2300Z by David Hoyt
# Intent: Windows Issue Template
#
# Instructions: Please run this powershell script when you have a:
#                 - Config Issue
#                      - Include the Cmake Output
#                  - Build Issue
#                      - Include the Build Output
#                  - Tools Issue
#                  *** - Provide your Repoduction ***
#                      - Include the Output
# *** All Reports must include a known good & working reproduction ***
#
#
#
#
#  URL https://github.com/InternationalColorConsortium/iccDEV
#
#
# iex (iwr -Uri "https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/windows-issue-template.ps1").Content
#
#
#
###############################################################

Write-Host ""
Write-Host "========================================================================"
Write-Host "===================== iccDEV | Windows Issue Template ====================="
Write-Host "Fetching the Code..."
Write-Host ""
Write-Host "========================================================================"
Write-Host "iccDEV Configure Issue Report ** Please include the data below this line"
Write-Host "========================================================================"
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