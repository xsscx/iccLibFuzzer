###############################################################
#
## Copyright (©) 2025 International Color Consortium.
##                 All rights reserved.
##                 https://color.org
#
# Last Modified: 26-NOV-2025 2100Z by David Hoyt
# Intent: Unix Issue Template
#
# Instructions: Please run this bash script when you have a:
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
# iex (iwr -Uri "https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/pr247.ps1").Content
#
#
#
###############################################################

Write-Host "============================= Starting Windows PR247 Build =============================" -ForegroundColor Green
Write-Host "Last Updated: 26-NOV-2025 2200 EST by David H Hoyt LLC" -ForegroundColor Green


git clone https://github.com/InternationalColorConsortium/iccDEV.git
cd iccDEV
git fetch origin pull/247/head:pr-247
git checkout pr-247
          git branch
          git status
          Write-Host "========= Fetching Deps... ================`n"
          Start-BitsTransfer -Source "https://github.com/InternationalColorConsortium/iccDEV/releases/download/v2.3.1/vcpkg-exported-deps.zip" -Destination "deps.zip"
          Write-Host "========= Extracting Deps... ================`n"
          tar -xf deps.zip
          cd Build/Cmake
          Write-Host "========= Building... ================`n"  
          cmake  -B build -S . -DCMAKE_TOOLCHAIN_FILE="..\..\scripts\buildsystems\vcpkg.cmake" -DVCPKG_MANIFEST_MODE=OFF -DCMAKE_BUILD_TYPE=Debug  -Wno-dev
          cmake --build build -- /m /maxcpucount
          cmake --build build -- /m /maxcpucount   


