###############################################################
#
## Copyright (©) 2025 International Color Consortium.
##                 All rights reserved.
##                 https://color.org
#
# Last Modified: 29-NOV-2025 1700Z by David Hoyt
# Intent: Unix New Issue Template
#
# Instructions: Please run this bash script when you have a new Issue:
#                 - Config Issue
#                      - Include the Cmake Output
#                  - Build Issue
#                      - Include the Build Output
#                  - Tools Issue
#                  *** - Provide your Repoduction ***
#                      - Include the Output
#
# *** All new Issues should include a Reproduction using this Script ***
#
#
#
#  URL https://github.com/InternationalColorConsortium/iccDEV
#
#
#
# Run: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/InternationalColorConsortium/iccDEV/refs/heads/research/contrib/HelperScripts/new-issue-reproduction.sh)"
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
echo "iccDEV | Unix New Issue Script "
echo ""
echo "Fetching the Code..."
echo ""

if [ ! -d iccDEV ]; then
    git clone https://github.com/InternationalColorConsortium/iccDEV.git
fi

cd iccDEV || { echo "cd iccDEV failed" >&2; exit 1; }
echo ""
echo "Checking the Origin..."
echo ""
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
echo "Date & Host Info"
date
uname -a
echo ""
echo "Commit & Branch Info"
git show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD
git branch
echo ""
cd Build || { echo "cd Build failed" >&2; exit 1; }
echo "Checking Dependencies"

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
                nlohmann-json >brew.log 2>&1
                tail -n 4 brew.log
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
                build-essential >apt.log 2>&1
                tail -n 4 apt.log
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

echo "Dependencies Installed"
echo ""
echo "===== Running Cmake with -fsanitize=address,undefined with cmake.log  ======"
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS="-g -fsanitize=address,undefined -fno-omit-frame-pointer" \
      Cmake >cmake.log 2>&1
cm_rc=$?                            
echo ""
tail -n 10 cmake.log
echo ""
status "CMake Configure" "$cm_rc"   
echo ""
echo "Build with Log"
make -j"$(nproc)" >build.log 2>&1
mk_rc=$?                             
tail -n 10 build.log
echo ""
status "Build / Make" "$mk_rc"       
echo ""
echo "Finding the Built Files"
find . -type f \( -perm -111 -o -name "*.a" -o -name "*.so" -o -name "*.dylib" \) \
    -mmin -1440 ! -path "*/.git/*" ! -path "*/CMakeFiles/*" ! -name "*.sh"
fi_rc=$?                              
echo ""
status "Artifact Scan" "$fi_rc"      
echo ""

cd ../Testing || { echo "cd ../Testing failed" >&2; exit 1; }

for d in ../Build/Tools/*; do
  if [ -d "$d" ]; then
    abs="$(realpath "$d" 2>/dev/null || true)"
    [ -n "$abs" ] && export PATH="$abs:$PATH"
  fi
done

echo ""
echo "======================================================"
echo "=  ENTER Issue or Problem (end with EOF / Ctrl-D) —  ="
echo "======================================================"
echo ""

# UnSafe target file - This is User Controllable Input (UCI)
POC_FILE="poc_input.txt"

# Truncate for new run
: > "$POC_FILE"

###############################################################################
# Markdown Header
###############################################################################
{
echo "# New Issue"
echo

###############################################################################
# Host Info
###############################################################################
echo "## Host"
echo '```'
date
uname -a
echo '```'
echo

###############################################################################
# Commit / Branch Info
###############################################################################
echo "## Commit & Branch Info"
echo '```'
git show --stat --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%n" HEAD
git branch --show-current
echo '```'
echo

###############################################################################
# CMake Log
###############################################################################
echo "## CMake Log (last few lines)"
echo '```'
tail -n 15 ../Build/cmake.log
echo '```'
echo

###############################################################################
# Build Log
###############################################################################
echo "## Build Log (last few lines)"
echo '```'
tail -n 15 ../Build/build.log
echo '```'
echo

###############################################################################
# Issue Body Input
###############################################################################
echo "## Issue or Problem Report"
echo "> Enter description below:"
echo '```'
} >> "$POC_FILE"

# Read raw PoC body from stdin
cat >> "$POC_FILE"

# Close the fenced markdown block
echo '```' >> "$POC_FILE"
echo >> "$POC_FILE"

###############################################################################
# Summary for terminal
###############################################################################
echo ""
echo "A new Issue can be opened using:"
echo ""
echo 'gh issue create --repo InternationalColorConsortium/iccDEV --title "New Issue" --body-file iccDEV/Testing/poc_input.txt --web'
echo
