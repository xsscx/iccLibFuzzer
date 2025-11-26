###############################################################
#
## Copyright (©) 2025 International Color Consortium. 
##                 All rights reserved. 
##                 https://color.org
#
# Last Modified: 27-NOV-2025 1900Z by David Hoyt
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
# Run: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/unix-pr-review.sh)"
#
#
###############################################################

set -euo pipefail

status() {
    local section="$1"
    local rc="$2"
    if [ "$rc" -eq 0 ]; then
        echo ">>> [PASS] $section"
    else
        echo ">>> [FAIL] $section (exit $rc)"
    fi
    echo ""
}

echo ""
echo "========================================================================"
echo "==================== International Color Consortium ===================="
echo "=============== Copyright (c) 2025 All Rights Reserved ================="
echo ""
echo "Repository URL https://github.com/InternationalColorConsortium/iccDEV"
echo ""
echo "Please Open an Issue with Questions, Comments or Bug Reports. Thank You."
echo ""
echo "===================== iccDEV | Unix PR Review Template ====================="
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
echo "PR ${pr_number} Cmake Report *** Please include the data below this line ***"
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
echo ""
echo "========= Dependencies Installed ========="
echo ""
echo "PR ${pr_number} Cmake Configuration"
echo ""
echo "===== Running Cmake with cmake.log  ========"
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS="-g -fsanitize=address,undefined -fno-omit-frame-pointer" \
      Cmake >cmake.log 2>&1
echo ""
tail -n 68 cmake.log
echo ""
echo "========================================================================"
echo "PR ${pr_number} Cmake Report *** Please include the data above this line"
echo "========================================================================"
echo ""
echo "========================================================================"
echo "*** If there is a Build Failure, Please paste the error in the Review **"
echo "========================================================================"
echo "PR ${pr_number} Build Report  ** Please include the data below this line"
echo "========================================================================"
echo ""
echo "======== Commit & Branch Info ========="
git show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD
git branch
echo ""
echo "PR ${pr_number} Cmake Build"
echo ""
echo "===== Running Build with Log  ========="
make -j"$(nproc)" >build.log 2>&1
tail -n 25 build.log
echo ""
echo "===== Finding the Built Files ========="
find . -type f \( -perm -111 -o -name "*.a" -o -name "*.so" -o -name "*.dylib" \) \
    -mmin -1440 ! -path "*/.git/*" ! -path "*/CMakeFiles/*" ! -name "*.sh"
echo ""
echo "========================================================================"
echo "PR ${pr_number} Build Report  ** Please include the data above this line"
echo "========================================================================"
echo ""
echo "========================================================================"
echo "*** If a Repro issue appears, Please paste the error in the Review   ***"
echo "========================================================================"
echo "PR ${pr_number} Repro Report  ** Please include the data below this line"
echo "========================================================================"
echo ""
echo "PR ${pr_number} Reproduction"
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

# Extend PATH once
for d in ../Build/Tools/*; do
    [ -d "$d" ] && export PATH="$(realpath "$d"):$PATH"
done

############################################################
# "========= INSERT YOUR REPRODUCTION BELOW HERE ========="#
############################################################

echo "======================================================"
echo "============= PR ${pr_number} START  ================="
echo "======================================================"
echo ""

# Disable fail-on-error so every test executes
set +e

echo "=== Updating PATH ==="
for d in ../Build/Tools/*; do
    [ -d "$d" ] && export PATH="$(realpath "$d"):$PATH"
done

############################################################
# Profile / Unit Test Execution with PASS / FAIL Reporting
############################################################

echo "========= PR ${pr_number} TEST START ========="

# -----------------------
# CreateAllProfiles.sh
# -----------------------
sh CreateAllProfiles.sh
rc_cap=$?
status "CreateAllProfiles.sh" "$rc_cap"

# -----------------------
# RunTests.sh
# -----------------------
sh RunTests.sh
rc_rt=$?
status "RunTests.sh" "$rc_rt"

# -----------------------
# HDR/mkprofiles.sh
# -----------------------
cd HDR
sh mkprofiles.sh
rc_hdr=$?
cd ..
status "HDR/mkprofiles.sh" "$rc_hdr"

# -----------------------
# hybrid/BuildAndTest.sh
# -----------------------
cd hybrid
sh BuildAndTest.sh
rc_hybrid=$?
cd ..
status "hybrid/BuildAndTest.sh" "$rc_hybrid"

# -----------------------
# CalcTest/checkInvalidProfiles.sh
# -----------------------
cd CalcTest
sh checkInvalidProfiles.sh
rc_calc=$?
cd ..
status "CalcTest/checkInvalidProfiles.sh" "$rc_calc"

# -----------------------
# mcs/updateprev.sh
# -----------------------
cd mcs
sh updateprev.sh
rc_mcs_up=$?
status "mcs/updateprev.sh" "$rc_mcs_up"

# -----------------------
# mcs/updateprevWithBkgd.sh
# -----------------------
sh updateprevWithBkgd.sh
rc_mcs_bg=$?
cd ..
status "mcs/updateprevWithBkgd.sh" "$rc_mcs_bg"


############################################################
# FINAL SUCCESS / FAIL SUMMARY FOR THE PR UNIT TEST
############################################################

echo "========= PR ${pr_number} TEST SUMMARY ==============="

# Collect RCs
all_rcs=$(( rc_cap + rc_rt + rc_hdr + rc_hybrid + rc_calc + rc_mcs_up + rc_mcs_bg ))

if [ "$all_rcs" -eq 0 ]; then
    echo ">>> [PASS] Full PR Unit Test"
else
    echo ">>> [FAIL] Full PR Unit Test (one or more failures)"
fi

echo ""
echo "** PR Authors must indicate the Expected Output for Success and Failure to guide Maintainers **"
echo ""

# Return to strict mode
set -e

echo ""
echo "======================================================"
echo "==================  PR ${pr_number} TEST STOP   =============="
echo "======================================================"
echo ""
echo "========================================================================"
echo "PR ${pr_number} Repro Report  ** Please include the data above this line ***"
echo "========================================================================"

cd ../../..

############################################################
# "========= INSERT YOUR REPRODUCTION ABOVE HERE ========="#
############################################################

##### Please do not remove Issue Start or Stop Markers #####
