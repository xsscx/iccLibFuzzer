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
# *** All Reports must include a known good & working reproduction ***
#
#
#
#
#  URL https://github.com/InternationalColorConsortium/iccDEV
#
#
#
# Run: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/legacy-unix-issue-template.sh)"
#
#
###############################################################

set -euo pipefail

echo ""
echo "========================================================================"
echo "==================== International Color Consortium ===================="
echo "=============== Copyright (c) 2025 All Rights Reserved ================="
echo ""
echo "Repository URL https://github.com/InternationalColorConsortium/iccDEV"
echo ""
echo "Please Open an Issue with Questions, Comments or Bug Reports. Thank You."
echo ""
echo "===================== iccDEV | Legacy Unix Issue Template ====================="
echo "Fetching the Code..."
echo ""

if [ ! -d iccDEV ]; then
    git clone https://github.com/InternationalColorConsortium/iccDEV.git
fi

cd iccDEV || { echo "cd iccDEV failed" >&2; exit 1; }
echo ""
echo "========================================================================"
echo "iccDEV Configure Issue Report ** Please include the data below this line"
echo "========================================================================"
echo ""
echo "Checking the Origin..."

origin_url="$(git remote get-url origin || true)"
echo "Remote origin: $origin_url"

expected_repo="${1:-InternationalColorConsortium/iccDEV}"
expected_https="https://github.com/${expected_repo}.git"
expected_https_nogit="${expected_https%.git}"
expected_ssh="git@github.com:${expected_repo}.git"

if [[ "$origin_url" != "$expected_https" \
   && "$origin_url" != "$expected_https_nogit" \
   && "$origin_url" != "$expected_ssh" ]]; then
    echo "Origin URL mismatch:" >&2
    echo "  expected: $expected_https" >&2
    echo "       or: $expected_https_nogit" >&2
    echo "       or: $expected_ssh" >&2
    echo "     got: $origin_url" >&2
fi
echo ""
echo "============== Host Info =============="
uname -a
echo ""
echo "======== Commit & Branch Info ========="
git show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD
git branch
echo ""
cd Build || { echo "cd Build failed" >&2; exit 1; }
echo "========= Checking Dependencies ========="

os="$(uname -s)"

case "$os" in
    Darwin)
        # macOS
        if command -v brew >/dev/null 2>&1; then
            echo "brew detected — installing deps"
            brew update || true
            brew install \
                libpng \
                jpeg \
                wxwidgets \
                libtiff \
                curl \
                git \
                make \
                cmake \
                llvm \
                libxml2 \
                nlohmann-json
        else
            echo "Homebrew not found." >&2
            echo "Install Homebrew: https://brew.sh/" >&2
            exit 1
        fi
        ;;
    Linux)
        # Linux
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -y
            sudo apt-get install -y cmake build-essential pkg-config libxml2-dev libcurl4-openssl-dev nlohmann-json3-dev libtiff-dev libpng-dev libjpeg-dev libwxgtk3.0-gtk3-dev wx3.0-headers libwxbase3.0-dev libwxgtk-media3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev
        else
            echo "Unsupported Linux distribution (no apt-get)" >&2
            exit 1
        fi
        ;;
    *)
        echo "Unsupported OS: $os" >&2
        exit 1
        ;;
esac

echo "========= Dependencies Installed ========="
echo ""
echo "===== Running Cmake with cmake.log  ========"
echo ""
echo "Modifying Cmake configuration for legacy Unix"
sed -i 's|^[[:space:]]*cmake_policy(SET CMP0135 NEW)|#cmake_policy(SET CMP0135 NEW)|' Cmake/CMakeLists.txt
sed -i 's|cmake_minimum_required(VERSION [0-9.]\+ FATAL_ERROR)|cmake_minimum_required(VERSION 3.18 FATAL_ERROR)|' Cmake/CMakeLists.txt
sed -i 's|^[[:space:]]*ADD_SUBDIRECTORY(Tools/wxProfileDump)|#ADD_SUBDIRECTORY(Tools/wxProfileDump)|' Cmake/CMakeLists.txt
sed -i 's|message(STATUS "wxWidgets found and configured")|message(STATUS "wxWidgets found and NOT configured on Legacy Unix")|' Cmake/CMakeLists.txt
echo ""
echo " Running Cmake Config"
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="-g -fsanitize=address,undefined -fno-omit-frame-pointer" Cmake >cmake.log 2>&1
echo ""
tail -n 68 cmake.log
echo ""
echo "========================================================================"
echo "iccDEV Configure Issue Report ** Please include the data above this line"
echo "========================================================================"
echo ""
echo "========================================================================"
echo "iccDEV Build Issue Report  ***** Please include the data below this line"
echo "========================================================================"
echo ""
echo "======== Commit & Branch Info ========="
git show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD
git branch
echo ""
echo "===== Running Build with Log  ========="
make -j"$(nproc)" >build.log 2>&1
tail -n 50 build.log
echo ""
echo "===== Finding the Built Files ========="
find . -type f \( -perm -111 -o -name "*.a" -o -name "*.so" -o -name "*.dylib" \) \
    -mmin -1440 ! -path "*/.git/*" ! -path "*/CMakeFiles/*" ! -name "*.sh"
echo ""
echo "========================================================================"
echo "iccDEV Build Issue Report  ***** Please include the data above this line"
echo "========================================================================"
echo ""
echo "========================================================================"
echo "iccDEV Issue Reproduction ****** Please include the data below this line"
echo "========================================================================"
echo ""
echo "========= Date & Time          ========="
date
pwd
echo ""
echo "========= Commit & Branch Info ========="
git show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD
git branch
git diff --stat
echo ""
echo "========= Host Info            ========="
uname -a
echo ""

cd ../Testing || { echo "cd ../Testing failed" >&2; exit 1; }

for d in ../Build/Tools/*; do
  if [ -d "$d" ]; then
    abs="$(realpath "$d" 2>/dev/null || true)"
    [ -n "$abs" ] && export PATH="$abs:$PATH"
  fi
done

############################################################
# "========= INSERT YOUR REPRODUCTION BELOW HERE ========="#
############################################################

echo "======================================================"
echo "===================  ISSUE START  ===================="
echo "======================================================"
echo ""
            set +e
            echo "========= Start Leaking... =========" 
            cd CMYK-3DLUTs
            iccFromXml CMYK-3DLUTs.xml CMYK-3DLUTs.icc
            cd ..
            set -e
            echo "========= Stop Leaking... =========="
echo ""
echo "======================================================"
echo "===================  ISSUE STOP   ===================="
echo "======================================================"
echo ""
echo "========================================================================"
echo "iccDEV Issue Reproduction ****** Please include the data above this line"
echo "========================================================================"

cd ../../..

############################################################
# "========= INSERT YOUR REPRODUCTION ABOVE HERE ========="#
############################################################

##### Please do not remove Issue Start or Stop Markers #####
