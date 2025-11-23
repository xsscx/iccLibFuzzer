#!/usr/bin/env bash
###############################################################
#
## Copyright (©) 2025 International Color Consortium. All rights reserved.
##                 https://color.org
##
## Last Updated: 19-NOV-2025 1200Z by David Hoyt
#
## Intent: Run Linters & Code Checks
#
## TODO: 
#
#
#
#
#
# RUN from $PROJECT_ROOT -> cd iccdev
#                         ./iccdev-lint.sh
#
###############################################################

set -euo pipefail

BUILD_DIR="Build"
CHECKS="modernize-*,readability-*,cppcoreguidelines-*"
OUTDIR="tidy-out"

mkdir -p "${OUTDIR}"

# Get the Code

git clone https://github.com/InternationalColorConsortium/iccDEV.git
cd iccDEV/Build

# Build the Code
cmake Cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
make -j$(nproc)
cd ..

# Extract translation units
jq -r '.[].file' "${BUILD_DIR}/compile_commands.json" \
  | xargs -I{} -P"$(nproc)" sh -c '
        f="{}"
        base=$(basename "$f")
        log="'"${OUTDIR}"'/${base}.log"
        echo "[+] $(date +"%H:%M:%S") START $f"
        run-clang-tidy -p "'"${BUILD_DIR}"'" -checks="'"${CHECKS}"'" "$f" > "$log" 2>&1
        echo "[+] $(date +"%H:%M:%S") DONE  $f"
    '
