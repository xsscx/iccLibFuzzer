#!/usr/bin/env bash
#------------------------------------------------------------------------------
# @file
# File:       backup.sh
#
# Contains:   Implementation of Repository & Branch Backup.
#
# Version:    V1
#
# Copyright:  (c) see Software License
#------------------------------------------------------------------------------
#
# Copyright (c) International Color Consortium.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. In the absence of prior written permission, the names "ICC" and "The
#    International Color Consortium" must not be used to imply that the
#    ICC organization endorses or promotes products derived from this
#    software.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE INTERNATIONAL COLOR CONSORTIUM OR
# ITS CONTRIBUTING MEMBERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
# ====================================================================
#
# This software consists of voluntary contributions made by many
# individuals on behalf of the International Color Consortium.
#
# Membership in the ICC is encouraged when this software is used for
# commercial purposes.
#
# For more information on The International Color Consortium, please
# see http://www.color.org/.
#------------------------------------------------------------------------------

###############################################################
# Copyright (©) 2024-2025 David H Hoyt. All rights reserved.
###############################################################
#                 https://srd.cx
#
# Last Updated: 17-DEC-2025 1700Z by David Hoyt
#
# Intent: Backup Repo & Branches via cron
#
# File: .github/scripts/backup.sh
# 
#
# Comment: Script to Backup Repo
#          Mea Culpa
#
#
# backup.sh https://github.com/InternationalColorConsortium/iccDEV.git 
#    
#
#
###############################################################

set -euo pipefail

# ===== ENTRY BANNER =====
SCRIPT_START=$(date -u +%s)
SCRIPT_START_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "============================================================"
echo "Script: $(basename "$0")"
echo "Start:  ${SCRIPT_START_TS}"
echo "PID:    $$"
echo "Args:   $# argument(s)"
echo "============================================================"

# ===== CONFIG =====
REPO_URL="${1:?Usage: $0 <repo-url>}"

# ---- URL validation (scheme whitelist; disallow insecure git://) ----
if [[ ! "$REPO_URL" =~ ^(https://|ssh://|git@) ]]; then
  echo "Error: unsupported or unsafe repo URL scheme"
  exit 1
fi

BACKUP_TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S")
BASE_DIR="$(pwd)/backup/${BACKUP_TIMESTAMP}"
REPO_NAME="$(basename -s .git "$REPO_URL")"
WORK_DIR="${BASE_DIR}/${REPO_NAME}_bare"

mkdir -p "$BASE_DIR"

# ===== ANONYMOUS IDENTITY =====
ANON_NAME="anon"
ANON_EMAIL="anon@localhost"

# ===== GIT HARDENING (ENV) =====
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

# ===== CLEANUP HANDLER =====
cleanup() {
  git -C "$WORK_DIR" worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# ===== CLONE (NO CHECKOUT) =====
git \
  -c user.name="$ANON_NAME" \
  -c user.email="$ANON_EMAIL" \
  -c commit.gpgsign=false \
  -c credential.helper= \
  clone --no-checkout "$REPO_URL" "$WORK_DIR"

cd "$WORK_DIR"

# ===== REPO-LOCAL LOCKDOWN =====
git config user.name "$ANON_NAME"
git config user.email "$ANON_EMAIL"
git config commit.gpgsign false
git config credential.helper ""
git config core.hooksPath /dev/null
git config fetch.recurseSubmodules false
git config fetch.prune true
git config transfer.fsckobjects true

# ===== ENUMERATE REMOTE BRANCHES =====
mapfile -t BRANCHES < <(
  git for-each-ref \
    --format='%(refname:short)' refs/remotes/origin |
    grep -v '^origin/HEAD$'
)

# ===== BACKUP EACH BRANCH =====
BRANCH_COUNT=0
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Starting branch backup (${#BRANCHES[@]} branches)"

for remote_branch in "${BRANCHES[@]}"; do
  branch="${remote_branch#origin/}"

  # ---- sanitize branch name for filesystem ----
  safe_branch=$(printf '%s' "$branch" | tr '/[:space:]' '__')
  if [[ "$safe_branch" == *".."* || -z "$safe_branch" ]]; then
    echo "Skipping unsafe branch name: $branch"
    continue
  fi

  BACKUP_PATH="${BASE_DIR}/${REPO_NAME}_${safe_branch}"

  # ---- rm -rf guard ----
  [[ "$BACKUP_PATH" == "$BASE_DIR/"* ]] || {
    echo "Refusing to delete outside base dir"
    exit 1
  }
  rm -rf -- "$BACKUP_PATH"

  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Backing up branch: $branch"
  git worktree add --detach "$BACKUP_PATH" "$remote_branch"

  git -C "$BACKUP_PATH" config user.name "$ANON_NAME"
  git -C "$BACKUP_PATH" config user.email "$ANON_EMAIL"
  git -C "$BACKUP_PATH" config commit.gpgsign false
  git -C "$BACKUP_PATH" config credential.helper ""
  git -C "$BACKUP_PATH" config core.hooksPath /dev/null

  BRANCH_COUNT=$((BRANCH_COUNT + 1))
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] ✓ Branch $branch → $BACKUP_PATH"
done

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Anonymous backup complete: $BRANCH_COUNT branches"

# ===== EXIT BANNER =====
SCRIPT_END=$(date -u +%s)
SCRIPT_END_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SCRIPT_DURATION=$((SCRIPT_END - SCRIPT_START))
echo "============================================================"
echo "Script: $(basename "$0")"
echo "End:    ${SCRIPT_END_TS}"
echo "Duration: ${SCRIPT_DURATION}s"
echo "Repo:   ${REPO_NAME}"
echo "Branches: ${BRANCH_COUNT}"
echo "Backup Timestamp: ${BACKUP_TIMESTAMP}"
echo "Working Directory: ${WORK_DIR}"
echo "Status: SUCCESS"
echo "============================================================"
