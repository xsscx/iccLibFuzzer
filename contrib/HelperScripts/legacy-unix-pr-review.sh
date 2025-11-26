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
# Run: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/legacy-unix-pr-review.sh)"
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
echo "===================== iccDEV | Legacy Unix PR Review Template ====================="
set -euo pipefail

# =======================
# Prompt for PR Number
# =======================
printf "Enter PR number to checkout: "
read -r pr_number

# Sanity checks
if [[ -z "${pr_number}" ]]; then
    echo "Error: PR number is empty" >&2
    exit 1
fi
if ! [[ "${pr_number}" =~ ^[0-9]+$ ]]; then
    echo "Error: PR number must be numeric" >&2
    exit 1
fi

echo ""
echo "========================================================================"
echo "Now checking out PR ${pr_number} from URL:"
echo "    https://github.com/InternationalColorConsortium/iccDEV/pull/${pr_number}"
echo "========================================================================"
echo ""
echo "Fetching repository... then Build & Run Checks..."
echo ""

if [ ! -d iccDEV ]; then
    git clone https://github.com/InternationalColorConsortium/iccDEV.git
fi

cd iccDEV || { echo "cd iccDEV failed" >&2; exit 1; }

echo ""
echo "========================================================================"
echo "*** If there is a Cmake Failure, Please paste the error into your Review"
echo "========================================================================"
echo "iccDEV Configure Issue Report ** Please include the data below this line"
echo "========================================================================"
echo ""

origin_url="$(git remote get-url origin || true)"
echo "Remote origin: $origin_url"

expected_repo="InternationalColorConsortium/iccDEV"
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
echo "Fetching PR ${pr_number}..."
git fetch origin "pull/${pr_number}/head:pr-${pr_number}"
echo ""
echo "Checking out pr-${pr_number}..."
git checkout "pr-${pr_number}"
echo ""
echo "PR ${pr_number} checkout complete."
echo ""
echo "======== Commit & Branch Info ========="
git show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD
git branch
echo ""
cd Build || { echo "cd Build failed" >&2; exit 1; }
echo "========= Checking Dependencies ========="
echo ""
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
echo ""
echo "========= Dependencies Installed ========="
echo ""
echo "===== Running Fixups with sed       ========"
sed -i 's/^cmake_policy(SET CMP0135 NEW)/#&/' Cmake/CMakeLists.txt
sed -i 's/cmake_minimum_required(VERSION [0-9.]\+ FATAL_ERROR)/cmake_minimum_required(VERSION 3.0 FATAL_ERROR)/' Cmake/CMakeLists.txt
sed -i 's/cmake_minimum_required(VERSION [0-9.]\+ FATAL_ERROR)/cmake_minimum_required(VERSION 3.18 FATAL_ERROR)/' Cmake/CMakeLists.txt
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
echo "*** If there is a Build Failure, Please paste the error in the Review **"
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
echo "*** If a profile issue appears, Please paste the error in the Review ***"
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
echo "==================  PROFILE START  ==================="
echo "======================================================"
echo ""
echo "========= BEGIN INSIDE STUB ========="
        cd ../Testing/
        echo "=== Updating PATH ==="
         for d in ../Build/Tools/*; do
          [ -d "$d" ] && export PATH="$(realpath "$d"):$PATH"
         done
          sh CreateAllProfiles.sh
          sh RunTests.sh
          cd HDR
          sh mkprofiles.sh
          cd ..
          cd hybrid
          sh BuildAndTest.sh
          cd ..
          cd CalcTest
          sh checkInvalidProfiles.sh
          cd ..
          cd mcs
          sh updateprev.sh
          sh updateprevWithBkgd.sh
          cd ..
          wget https://github.com/xsscx/PatchIccMAX/raw/refs/heads/re231/contrib/UnitTest/cve-2023-46602.icc
          iccDumpProfile cve-2023-46602.icc
          iccRoundTrip cve-2023-46602.icc
          wget https://github.com/xsscx/PatchIccMAX/raw/refs/heads/re231/contrib/UnitTest/icPlatformSignature-ubsan-poc.icc
          iccRoundTrip icPlatformSignature-ubsan-poc.icc
          iccDumpProfile icPlatformSignature-ubsan-poc.icc
          wget https://github.com/xsscx/PatchIccMAX/raw/refs/heads/re231/contrib/UnitTest/icSigMatrixElemType-Read-poc.icc
          iccRoundTrip icSigMatrixElemType-Read-poc.icc
          iccDumpProfile icSigMatrixElemType-Read-poc.icc
          iccToXml icSigMatrixElemType-Read-poc.icc icSigMatrixElemType-Read-poc.xml
          iccToXml icPlatformSignature-ubsan-poc.icc icPlatformSignature-ubsan-poc.xml
          iccToXml cve-2023-46602.icc cve-2023-46602.xml
          iccFromXml icSigMatrixElemType-Read-poc.xml icSigMatrixElemType-Read-rt.icc
          iccFromXml icPlatformSignature-ubsan-poc.xml icPlatformSignature-ubsan-rt.icc
          iccFromXml cve-2023-46602.xml cve-2023-46602-rt.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_94578.xml
          icctoXml sRGB_D65_colorimetric_94578.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_8590.xml
          iccFromXml sRGB_D65_colorimetric_8590.xml
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_80278.xml
          iccFromXml sRGB_D65_colorimetric_80278.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_72115.xml
          iccFromXml sRGB_D65_colorimetric_72115.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_61477.xml
          iccFromXml sRGB_D65_colorimetric_61477.xml
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_448.xml
          iccFromXml sRGB_D65_colorimetric_448.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_42752.xml
          iccFromXml sRGB_D65_colorimetric_42752.xml out.icc
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_21981.xml
          iccFromXml sRGB_D65_colorimetric_21981.xml
          wget https://raw.githubusercontent.com/xsscx/Commodity-Injection-Signatures/refs/heads/master/xml/icc/sRGB_D65_colorimetric_20483.xml
          iccFromXml sRGB_D65_colorimetric_20483.xml out.icc
          wget https://github.com/xsscx/Commodity-Injection-Signatures/raw/refs/heads/master/graphics/icc/Cat8Lab-D65_2degMeta.icc
          iccToXml Cat8Lab-D65_2degMeta.icc Cat8Lab-D65_2degMeta.xml
          find . -iname "*.icc" | wc -l
          iccRoundTrip PCC/Lab_float-D50_2deg.icc
          bash -c "$(curl -fsSL https://raw.githubusercontent.com/xsscx/PatchIccMAX/refs/heads/research/contrib/UnitTest/iccDumpProfile_checks.zsh)"
          cd ../Build
          bash -c "$(curl -fsSL https://raw.githubusercontent.com/xsscx/PatchIccMAX/refs/heads/research/contrib/CalcTest/test_icc_apply_named_cmm.sh)"
echo "========= INSIDE STUB EXIT ========="

echo ""
echo "======================================================"
echo "==================  PROFILE STOP   ==================="
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
