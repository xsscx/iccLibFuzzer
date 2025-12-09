###############################################################
#
## Copyright (©) 2025 International Color Consortium.
##                 All rights reserved.
##                 https://color.org
#
# Last Modified: 09-DEC-2025 0200Z by David Hoyt
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
# iex (iwr -Uri "https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/pr304.ps1").Content
#
#
#
###############################################################

Write-Host "============================= Starting Windows PR304 Build =============================" -ForegroundColor Green
Write-Host "Last Updated: 07-DEC-2025 1400Z by David H Hoyt LLC" -ForegroundColor Green

git clone https://github.com/InternationalColorConsortium/iccDEV.git
cd iccDEV
          git checkout ubuntu-warning-cleanup
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


