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
#
# Run: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/issue244.sh)"
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
echo "===================== iccDEV | Unix Issue Template ====================="
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
echo "======== Commit & Branch Info ========="
git show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD | grep Commit || true
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
            sudo apt-get install -y \
                libpng-dev \
                libjpeg-dev \
                libwxgtk3.2-dev \
                libwxgtk-media3.2-dev \
                libwxgtk-webview3.2-dev \
                wx-common \
                wx3.2-headers \
                libtiff6 \
                curl \
                git \
                make \
                cmake \
                clang \
                clang-tools \
                libxml2 \
                libxml2-dev \
                nlohmann-json3-dev \
                build-essential
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
git show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD | grep Commit || true
git branch
echo ""
echo "===== Running Build with Log  ========="
make -j"$(nproc)" >build.log 2>&1
tail -n 50 build.log
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
git -C .. show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD | grep Commit || true
git -C .. branch
git -C .. diff --stat || true
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
            wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_20483.xml
            iccFromXml sRGB_D65_colorimetric_21981.xml out.icc
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
